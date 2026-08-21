#!/bin/bash
generate_name() {
    local input_str="$1"
    local min_len="$2"
    local word=""
    local char
    local repeat
    local i j

    for (( i=0; i<${#input_str}; i++ )); do
        char="${input_str:$i:1}"
        (( repeat = RANDOM % 3 + 1 ))
        for (( j=0; j<repeat; j++ )); do
            word+="$char"
        done
    done

    while (( ${#word} < min_len )); do
        word+="${word: -1}"
    done

    echo "$word"
}
