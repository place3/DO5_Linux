#!/bin/bash
# Конвертирует "DD.MM.YYYY HH:MM" в однозначный ISO-формат
to_iso() {
    local input="$1"
    local date_part="${input%% *}"
    local time_part="${input#* }"
    local dd mm yyyy
    IFS='.' read -r dd mm yyyy <<< "$date_part"
    echo "${yyyy}-${mm}-${dd} ${time_part}"
}

# Строит regex-фрагмент "a+z+" по строке букв "az" (сохраняет порядок)
build_letter_pattern() {
    local letters="$1"
    local pattern=""
    local i char
    for (( i=0; i<${#letters}; i++ )); do
        char="${letters:$i:1}"
        pattern+="${char}+"
    done
    echo "$pattern"
}

confirm() {
    local answer
    read -r -p "Удалить найденные объекты? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# ------------------------------------------------------------
#             Способ 1: очистка по лог-файлу
# ------------------------------------------------------------
clean_by_log() {
    local log_to_delete="$1"
    local file_count folder_count

    if [[ ! -f "$log_to_delete" ]]; then
        echo "Error: лог-файл не найден: $log_to_delete" >&2
        return 1
    fi

    file_count=$(awk -F'|' '$1 == "FILE" {count++} END {print count+0}' "$log_to_delete")
    folder_count=$(awk -F'|' '$1 == "FOLDER" {count++} END {print count+0}' "$log_to_delete")
    echo "Найдено в логе: файлов — $file_count, папок — $folder_count"

    if (( file_count == 0 && folder_count == 0 )); then
        echo "Нечего удалять."
        return 0
    fi

    confirm || { echo "Operation cancelled."; return 0; }

    # Сначала файлы, потом папки (чтобы папки к моменту удаления были пустыми)
    while IFS='|' read -r type path _date _size; do
        if [[ "$type" == "FILE" && -f "$path" ]]; then
            rm -f -- "$path"
            echo "Удалён файл: $path"
        fi
    done < "$log_to_delete"

    while IFS='|' read -r type path _date _size; do
        if [[ "$type" == "FOLDER" && -d "$path" ]]; then
            rmdir -- "$path" 2>/dev/null || true
            echo "Удалена папка: $path"
        fi
    done < "$log_to_delete"

    echo "Очистка по логу завершена"
}

# ------------------------------------------------------------
#          Способ 2: очистка по дате и времени создания
# ------------------------------------------------------------
clean_by_date() {
    local start_raw="$1"
    local end_raw="$2"
    local start_delete end_delete start_ts end_ts

    start_delete=$(to_iso "$start_raw")
    end_delete=$(to_iso "$end_raw")

    if ! start_ts=$(date -d "$start_delete" +%s 2>/dev/null); then
        echo "Неверное начальное время." >&2
        return 1
    fi
    if ! end_ts=$(date -d "$end_delete" +%s 2>/dev/null); then
        echo "Неверное конечное время." >&2
        return 1
    fi
    if (( start_ts >= end_ts )); then
        echo "Время начала должно быть раньше времени конца." >&2
        return 1
    fi

    mapfile -t files < <(
        find / -type f -newermt "$start_delete" ! -newermt "$end_delete" 2>/dev/null |
        grep -Ev '(^|/)(s?bin)(/|$)'
    )
    mapfile -t dirs < <(
        find / -type d -newermt "$start_delete" ! -newermt "$end_delete" 2>/dev/null |
        grep -Ev '(^|/)(s?bin)(/|$)'
    )

    if (( ${#files[@]} == 0 && ${#dirs[@]} == 0 )); then
        echo "Ничего не найдено в указанном диапазоне."
        return 0
    fi

    echo "Найдено: файлов — ${#files[@]}, папок — ${#dirs[@]}"
    confirm || { echo "Operation cancelled."; return 0; }

    for file in "${files[@]}"; do
        [[ -f "$file" ]] && rm -f -- "$file" && echo "Файл удалён: $file"
    done
    for dir in "${dirs[@]}"; do
        [[ -d "$dir" ]] && { rmdir -- "$dir" 2>/dev/null || true; echo "Папка удалена: $dir"; }
    done

    echo "Очистка завершена"
}

# ------------------------------------------------------------
#               Способ 3: очистка по маске имени
# ------------------------------------------------------------
clean_by_mask() {
    local letters_dir="$1"
    local letters_file="$2"
    local selected_date="$3"

    if ! [[ "$letters_dir" =~ ^[a-zA-Z]+$ ]]; then
        echo "Error: буквы папки должны быть латинскими" >&2
        return 1
    fi
    if [[ "$letters_file" != *.* ]]; then
        echo "Error: буквы файла должны быть в формате 'name.ext'" >&2
        return 1
    fi
    if ! [[ "$selected_date" =~ ^[0-9]{6}$ ]]; then
        echo "Error: дата должна быть в формате ddmmyy (6 цифр)" >&2
        return 1
    fi

    local file_name_part="${letters_file%%.*}"
    local file_ext_part="${letters_file#*.}"

    # Папка: /<буквы>+_<дата>(конец пути или "/")
    local folder_regex
    folder_regex="/$(build_letter_pattern "$letters_dir")_${selected_date}(/|\$)"

    # Файл: /<буквы>+_<дата>.<буквы>+  в конце строки
    local file_regex
    file_regex="/$(build_letter_pattern "$file_name_part")_${selected_date}\.$(build_letter_pattern "$file_ext_part")\$"

    mapfile -t folders < <(
        find / -type d 2>/dev/null |
        grep -E "$folder_regex" |
        grep -Ev '(^|/)(bin|sbin)(/|$)'
    )
    mapfile -t files < <(
        find / -type f 2>/dev/null |
        grep -E "$file_regex" |
        grep -Ev '(^|/)(bin|sbin)(/|$)'
    )

    if (( ${#folders[@]} == 0 && ${#files[@]} == 0 )); then
        echo "Ничего не найдено по маске."
        return 0
    fi

    echo "Найдено: файлов — ${#files[@]}, папок — ${#folders[@]}"
    confirm || { echo "Operation cancelled."; return 0; }

    for file in "${files[@]}"; do
        rm -f -- "$file"
        echo "Удалён файл: $file"
    done
    for folder in "${folders[@]}"; do
        rmdir -- "$folder" 2>/dev/null || true
        echo "Удалена папка: $folder"
    done

    echo "Очистка по маске завершена"
}
