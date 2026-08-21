#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/functions.sh"

usage() {
    echo "Usage: $0 <1|2|3>" >&2
    echo "  1 - clean by log file" >&2
    echo "  2 - clean by creation date/time range" >&2
    echo "  3 - clean by name mask" >&2
}

if [[ $# -ne 1 ]]; then
    echo "Error: expected 1 argument, got $#" >&2
    usage
    exit 1
fi

method="$1"

case "$method" in
    1)
        read -r -p "Введите путь к логу для очистки: " remove_log
        clean_by_log "$remove_log"
        ;;
    2)
        read -r -p "Введите дату начала (DD.MM.YYYY HH:MM): " start_date
        read -r -p "Введите дату конца (DD.MM.YYYY HH:MM): " end_date
        clean_by_date "$start_date" "$end_date"
        ;;
    3)
        read -r -p "Введите символы для имени папки (например aazz): " dir_letters
        read -r -p "Введите символы для имени файла (например az.za): " file_letters
        read -r -p "Введите дату (ddmmyy): " cr_date
        clean_by_mask "$dir_letters" "$file_letters" "$cr_date"
        ;;
    *)
        echo "Error: неверный метод, ожидается 1, 2 или 3" >&2
        usage
        exit 1
        ;;
esac

