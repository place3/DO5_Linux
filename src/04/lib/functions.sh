#!/bin/bash
# ============================================================
# Функции для генерации nginx access-логов в Combined Log Format
# ============================================================

# HTTP-коды и их значение:
#
# 200 - OK: запрос успешно выполнен
# 201 - Created: ресурс успешно создан
# 400 - Bad Request: некорректный запрос клиента
# 401 - Unauthorized: требуется аутентификация
# 403 - Forbidden: доступ запрещён
# 404 - Not Found: ресурс не найден
# 500 - Internal Server Error: внутренняя ошибка сервера
# 501 - Not Implemented: сервер не поддерживает необходимую функциональность
# 502 - Bad Gateway: сервер получил некорректный ответ от вышестоящего сервера
# 503 - Service Unavailable: сервер временно недоступен

status_codes=(200 201 400 401 403 404 500 501 502 503)

methods=(
    "GET"
    "POST"
    "PUT"
    "PATCH"
    "DELETE"
)

urls=(
    "/"
    "/index.html"
    "/about"
    "/contact"
    "/login"
    "/logout"
    "/products"
    "/products/1"
    "/products/2"
    "/api/users"
    "/api/users/1"
    "/api/orders"
    "/api/orders/1"
    "/admin"
    "/search"
    "/profile"
    "/settings"
)

agents=(
    "Mozilla"
    "Google Chrome"
    "Opera"
    "Safari"
    "Internet Explorer"
    "Microsoft Edge"
    "Crawler and bot"
    "Library and net tool"
)

# Случайный корректный IP (первый октет 1-255, чтобы избежать 0.x.x.x)
generate_ip() {
    echo "$((RANDOM % 255 + 1)).$((RANDOM % 256)).$((RANDOM % 256)).$((RANDOM % 256))"
}

# Случайное количество секунд от начала суток: 0 = 00:00:00, 86399 = 23:59:59
generate_time() {
    echo $((RANDOM % 86400))
}

# Секунды -> "HH:MM:SS"
format_time() {
    local seconds=$1
    printf "%02d:%02d:%02d" \
        $((seconds / 3600)) \
        $(((seconds % 3600) / 60)) \
        $((seconds % 60))
}

# Генерирует один лог-файл за указанный день (100-1000 записей, время по возрастанию)
generate_log() {
    local log_file="$1"
    local log_date="$2"

    local records=$((RANDOM % 901 + 100))
    local -a timestamps

    for (( i = 0; i < records; i++ )); do
        timestamps[i]=$(generate_time)
    done

    mapfile -t timestamps < <(printf "%s\n" "${timestamps[@]}" | sort -n)

    local day_formatted
    day_formatted="$(date -d "$log_date" '+%d/%b/%Y')"

    for (( i = 0; i < records; i++ )); do
        local ip time status method url agent response_size

        ip=$(generate_ip)
        time=$(format_time "${timestamps[i]}")
        status="${status_codes[RANDOM % ${#status_codes[@]}]}"
        method="${methods[RANDOM % ${#methods[@]}]}"
        url="${urls[RANDOM % ${#urls[@]}]}"
        agent="${agents[RANDOM % ${#agents[@]}]}"
        response_size=$((RANDOM % 100000 + 100))

        # Combined Log Format:
        # IP - - [DATE:TIME +0300] "METHOD URL HTTP/1.1" STATUS SIZE "REFERER" "USER-AGENT"
        printf '%s - - [%s:%s +0300] "%s %s HTTP/1.1" %s %s "-" "%s"\n' \
            "$ip" "$day_formatted" "$time" "$method" "$url" "$status" "$response_size" "$agent"

    done > "$log_file"
}
