#!/bin/bash
create_structure() {
    local abs_path="$1"
    local dir_count="$2"
    local dir_letters="$3"
    local file_count="$4"
    local name_part="$5"
    local ext_part="$6"
    local size_kb="$7"
    local log_file="$8"

    local today
    today=$(date +"%d%m%y")

    local i j
    local folder_name full_folder_path
    local file_base file_ext file_name full_file_path

    mkdir -p "$abs_path"

    for (( i=1; i<=dir_count; i++ )); do
        check_disk_space

        folder_name="$(generate_name "$dir_letters" 4)_${today}"
        full_folder_path="${abs_path}/${folder_name}"
        mkdir -p "$full_folder_path"
        echo "FOLDER|${full_folder_path}|$(date '+%d.%m.%Y %H:%M:%S')" >> "$log_file"

        for (( j=1; j<=file_count; j++ )); do
            check_disk_space

            file_base="$(generate_name "$name_part" 4)"
            file_ext="$(generate_name "$ext_part" 1)"
            file_name="${file_base}_${today}.${file_ext}"
            full_file_path="${full_folder_path}/${file_name}"

            dd if=/dev/zero of="$full_file_path" bs=1K count="$size_kb" 2>/dev/null

            echo "FILE|${full_file_path}|$(date '+%d.%m.%Y %H:%M:%S')|${size_kb}KB" >> "$log_file"
        done
    done
}
