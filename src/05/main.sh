#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/functions.sh"

# Логи лежат там, куда их кладёт Part 4 (src/04/logs)
log_dir="${SCRIPT_DIR}/../04/logs"

usage() {
    echo "Usage: $0 <1|2|3|4>" >&2
}

if [[ $# -ne 1 ]]; then
    echo "Error: expected 1 argument, got $#" >&2
    usage
    exit 1
fi

mode="$1"

check_logs_exist "$log_dir"

case "$mode" in
    1) report_sorted_by_status "$log_dir" ;;
    2) report_unique_ips "$log_dir" ;;
    3) report_error_requests "$log_dir" ;;
    4) report_unique_error_ips "$log_dir" ;;
    *)
        echo "Error: неверный режим, ожидается 1, 2, 3 или 4" >&2
        usage
        exit 1
        ;;
esac
