#!/bin/bash
set -euo pipefail
trap 'echo "ERROR: line $LINENO, command: $BASH_COMMAND" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/functions.sh"

usage() {
    echo "Usage: $0 <dir_letters> <file_letters.ext> <size_mb>" >&2
    echo "Example: $0 az az.az 3Mb" >&2
}

if [[ $# -ne 3 ]]; then
    echo "Error: expected 3 arguments, got $#" >&2
    usage
    exit 1
fi

dir_letters="$1"
file_letters="$2"
size_raw="$3"

validate_letters "$dir_letters" 7 "directory letters (parameter 1)"
validate_file_letters "$file_letters"     # заполняет NAME_PART / EXT_PART
validate_size_mb "$size_raw" 100           # заполняет SIZE_MB

log_file="${SCRIPT_DIR}/created.log"

start_time=$(date +"%d.%m.%Y %H:%M:%S")
start_ts=$(date +%s)

# Кандидаты для размещения — вся ФС, кроме bin/sbin, только доступные для записи
#mapfile -t candidate_dirs < <(
#    find -xdev / -maxdepth 4 -type d -writable 2>/dev/null | grep -v -e '/bin' -e '/sbin'
#)

mapfile -t candidate_dirs < <(
    find /tmp /home /var/tmp -maxdepth 3 -type d -writable 2>/dev/null |
    grep -Ev '(^|/)(bin|sbin)(/|$)'
)


if (( ${#candidate_dirs[@]} == 0 )); then
    echo "Error: no writable directories found." >&2
    exit 1
fi

folder_count=$(( RANDOM % 100 + 1 ))

for (( i=1; i<=folder_count; i++ )); do
    check_disk_space

    random_dir="${candidate_dirs[RANDOM % ${#candidate_dirs[@]}]}"
    folder_name="$(generate_name "$dir_letters" 5)_$(date +%d%m%y)"
    full_folder_path="${random_dir}/${folder_name}"
    mkdir -p "$full_folder_path"
    echo "FOLDER|${full_folder_path}|$(date '+%d.%m.%Y %H:%M:%S')" >> "$log_file"

    # Случайное число файлов в этой папке (своё для каждой папки)
    files_count=$(( RANDOM % 30 + 1 ))

    for (( j=1; j<=files_count; j++ )); do
        check_disk_space

        file_base="$(generate_name "$NAME_PART" 5)_$(date +%d%m%y)"
        file_ext="$(generate_name "$EXT_PART" 1)"
        file_name="${file_base}.${file_ext}"
        full_file_path="${full_folder_path}/${file_name}"

        dd if=/dev/zero of="$full_file_path" bs="${SIZE_MB}M" count=1 

        echo "FILE|${full_file_path}|$(date '+%d.%m.%Y %H:%M:%S')|${SIZE_MB}Mb" >> "$log_file"
    done
done

finish 0
