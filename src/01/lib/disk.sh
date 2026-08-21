#!/bin/bash
check_disk_space() {
    local disk_limit=$((1024 * 1024 * 1024))
    local avail_space
    avail_space=$(df --output=avail -B1 / | tail -n 1 | tr -d ' ')

    if (( avail_space <= disk_limit )); then
        echo "Error: 1GB or less free space remaining on /, stopping" >&2
        exit 1
    fi
}
