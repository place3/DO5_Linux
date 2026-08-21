#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/validate.sh"
source "${SCRIPT_DIR}/lib/generate.sh"
source "${SCRIPT_DIR}/lib/disk.sh"
source "${SCRIPT_DIR}/lib/create_structure.sh"

usage() {
    echo "Usage: $0 <abs_path> <dir_count> <dir_letters> <file_count> <file_letters.ext> <size_kb>" >&2
    echo "Example: $0 /opt/test 4 az 5 az.az 3kb" >&2
}

# --- Проверка количества аргументов ---
if [[ $# -ne 6 ]]; then
    echo "Error: expected 6 arguments, got $#" >&2
    usage
    exit 1
fi

abs_path="$1"
dir_count="$2"
dir_letters="$3"
file_count="$4"
file_letters="$5"
size_raw="$6"

# --- Валидация всех параметров ---
validate_path "$abs_path"
validate_number "$dir_count" "directory count (parameter 2)"
validate_letters "$dir_letters" 7 "directory letters (parameter 3)"
validate_number "$file_count" "file count (parameter 4)"
validate_file_letters "$file_letters"      # заполняет NAME_PART / EXT_PART
validate_size_kb "$size_raw" 100            # заполняет SIZE_KB

log_file="${abs_path}/creation.log"
mkdir -p "$abs_path"

echo "Starting generation in ${abs_path} ..."
create_structure "$abs_path" "$dir_count" "$dir_letters" "$file_count" \
                  "$NAME_PART" "$EXT_PART" "$SIZE_KB" "$log_file"

echo "Done. Log written to: $log_file"
