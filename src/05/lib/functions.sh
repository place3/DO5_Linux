#!/bin/bash
# Проверяет, что папка с логами существует и содержит *.log файлы
check_logs_exist() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        echo "Error: log directory not found: $dir" >&2
        exit 2
    fi
    if ! compgen -G "${dir}/*.log" > /dev/null; then
        echo "Error: no .log files found in: $dir" >&2
        exit 2
    fi
}

# 1. Все записи, отсортированные по коду ответа (по всем файлам сразу)
report_sorted_by_status() {
    local dir="$1"
    sort -k9,9 -n "${dir}"/*.log
}

# 2. Все уникальные IP
report_unique_ips() {
    local dir="$1"
    awk '{ print $1 }' "${dir}"/*.log | sort -u
}

# 3. Все запросы с ошибками (4xx или 5xx)
report_error_requests() {
    local dir="$1"
    awk '$9 ~ /^[45]/ { print }' "${dir}"/*.log
}

# 4. Уникальные IP среди ошибочных запросов
report_unique_error_ips() {
    local dir="$1"
    awk '$9 ~ /^[45]/ { print $1 }' "${dir}"/*.log | sort -u
}
