#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/functions.sh"

if [[ $# -ne 0 ]]; then
    echo "Error: this script does not take any arguments" >&2
    echo "Usage: $0" >&2
    exit 1
fi

RANDOM=$$

output_dir="${SCRIPT_DIR}/logs"
mkdir -p "$output_dir"

current_date=$(date '+%Y-%m-%d')

for (( day = 1; day <= 5; day++ )); do
    log_file="${output_dir}/access-$(date -d "$current_date" '+%Y-%m-%d').log"

    generate_log "$log_file" "$current_date"
    echo "Создан: $log_file"

    current_date=$(date -d "$current_date + 1 day" '+%Y-%m-%d')
done

echo "Генерация завершена. Логи находятся в: $output_dir"
