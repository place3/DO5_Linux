#!/bin/bash
# Проверяет, что путь абсолютный
validate_path() {
    local path="$1"
    if ! [[ "$path" =~ ^/ ]]; then
        echo "Error: parameter 1 must be an absolute path (must start with /)" >&2
        exit 2
    fi
}

validate_number() {
    local value="$1"
    local label="$2"
    if ! [[ "$value" =~ ^[0-9]+$ ]] || (( value == 0 )); then
        echo "Error: ${label} must be a positive integer" >&2
        exit 3
    fi
}


validate_letters() {
    local letters="$1"
    local max_len="$2"
    local label="$3"
    if ! [[ "$letters" =~ ^[a-zA-Z]+$ ]]; then
        echo "Error: ${label} must contain only English letters" >&2
        exit 4
    fi
    if (( ${#letters} > max_len )); then
        echo "Error: ${label} must be at most ${max_len} characters" >&2
        exit 4
    fi
}


validate_file_letters() {
    local file_letters="$1"

    if [[ "$file_letters" != *.* ]]; then
        echo "Error: parameter 5 must be in format 'name.ext' (e.g. az.az)" >&2
        exit 5
    fi

    NAME_PART="${file_letters%%.*}"
    EXT_PART="${file_letters#*.}"

    validate_letters "$NAME_PART" 7 "file name part (before the dot)"
    validate_letters "$EXT_PART" 3 "file extension part (after the dot)"
}

validate_size_kb() {
    local raw="$1"
    local max_size="$2"
    local numeric="${raw%[Kk][Bb]}"

    if ! [[ "$numeric" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: parameter 6 must be a number followed by 'kb' (e.g. 3kb)" >&2
        exit 6
    fi

    if (( numeric > max_size )); then
        echo "Error: size must not exceed ${max_size}kb" >&2
        exit 6
    fi

    SIZE_KB="$numeric"
}
