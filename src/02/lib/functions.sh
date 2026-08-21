#!/bin/bash
# --- Валидация ---

validate_letters() {
    local letters="$1"
    local max_len="$2"
    local label="$3"
    if ! [[ "$letters" =~ ^[a-zA-Z]+$ ]]; then
        echo "Error: ${label} must contain only English letters" >&2
        exit 2
    fi
    if (( ${#letters} > max_len )); then
        echo "Error: ${label} must be at most ${max_len} characters" >&2
        exit 2
    fi
}

validate_file_letters() {
    local file_letters="$1"

    if [[ "$file_letters" != *.* ]]; then
        echo "Error: parameter 2 must be in format 'name.ext' (e.g. az.az)" >&2
        exit 3
    fi

    NAME_PART="${file_letters%%.*}"
    EXT_PART="${file_letters#*.}"

    validate_letters "$NAME_PART" 7 "file name part (before the dot)"
    validate_letters "$EXT_PART" 3 "file extension part (after the dot)"
}

validate_size_mb() {
    local raw="$1"
    local max_size="$2"
    local numeric="${raw%[Mm][Bb]}"

    if ! [[ "$numeric" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: parameter 3 must be a number followed by 'Mb' (e.g. 3Mb)" >&2
        exit 4
    fi
    if (( numeric > max_size )); then
        echo "Error: size must not exceed ${max_size}Mb" >&2
        exit 4
    fi

    SIZE_MB="$numeric"
}

generate_name() {
    local input_str="$1"
    local min_len="$2"
    local word=""
    local char
    local repeat
    local i j

    for (( i=0; i<${#input_str}; i++ )); do
        char="${input_str:$i:1}"
        (( repeat = RANDOM % 3 + 1 ))
        for (( j=0; j<repeat; j++ )); do
            word+="$char"
        done
    done

    while (( ${#word} < min_len )); do
        word+="${word: -1}"
    done

    echo "$word"
}


check_disk_space() {
    local avail_human avail_bytes
    local disk_limit=$((1 * 1024 * 1024 * 1024))

    avail_human=$(df -h --output=avail / | tail -n 1 | tr -d ' ')
    avail_bytes=$(numfmt --from=iec "$avail_human")

    if (( avail_bytes <= disk_limit )); then
        echo "Space limit (1GB) has been reached, stopping" >&2
        finish 1
    fi
}


finish() {
    local exit_code="$1"
    local end_time end_ts duration

    end_time=$(date +"%d.%m.%Y %H:%M:%S")
    end_ts=$(date +%s)
    duration=$(( end_ts - start_ts ))

    echo "Начало: $start_time"
    echo "Конец: $end_time"
    echo "Длительность: ${duration} сек."

    {
        echo "START|${start_time}"
        echo "END|${end_time}"
        echo "DURATION|${duration}sec"
    } >> "$log_file"

    exit "$exit_code"
}
