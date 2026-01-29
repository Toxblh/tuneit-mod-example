#!/usr/bin/bash

MAIN_YAML_FILE="module.yml"
POT_FILE="./po/module.pot"
ADDITIONAL_YAML_DIR="./sections"

mkdir -p "$(dirname "$POT_FILE")"

declare -A SEEN_MSGS

add_message() {
    local msg="$1"
    local file="$2"
    local line_num="$3"
    if [[ -n "$msg" && -z "${SEEN_MSGS[$msg]}" ]]; then
        SEEN_MSGS[$msg]=1
        echo "#: $file:$line_num" >> "$POT_FILE"
        echo "msgid \"$msg\"" >> "$POT_FILE"
        echo "msgstr \"\"" >> "$POT_FILE"
        echo "" >> "$POT_FILE"
    fi
}

add_header() {
    {
        echo "msgid \"\""
        echo "msgstr \"\""
        echo "\"Project-Id-Version: My Project 1.0\\n\""
        echo "\"Report-Msgid-Bugs-To: bugs@example.com\\n\""
        echo "\"POT-Creation-Date: $(date +"%Y-%m-%d %H:%M%z")\\n\""
        echo "\"PO-Revision-Date: $(date +"%Y-%m-%d %H:%M%z")\\n\""
        echo "\"Last-Translator: Your Name <yourname@example.com>\\n\""
        echo "\"Language-Team: Russian <ru@example.com>\\n\""
        echo "\"MIME-Version: 1.0\\n\""
        echo "\"Content-Type: text/plain; charset=UTF-8\\n\""
        echo "\"Content-Transfer-Encoding: 8bit\\n\""
        echo "\"X-Generator: Custom Script\\n\""
    } > "$POT_FILE"
}

process_file() {
    local file="$1"
    local matches
    matches=$(grep -noP '[\s"'"'"']\K_[^:"]*' "$file")

    if [[ -z "$matches" ]]; then
        echo "В файле '$file' не найдено строк с символом '_'."
    else
        echo "Обработка файла: $file"
        echo "$matches"

        while IFS= read -r match; do
            local line_num
            line_num=$(echo "$match" | cut -d: -f1)
            local line_content
            line_content=$(echo "$match" | cut -d: -f2-)

            local key
            key=$(echo "$line_content" | sed 's/^_//; s/["'"'"']$//')

            if [[ -n "$key" ]]; then
                echo "Добавляем в POT: $key из файла $file:$line_num"
                add_message "$key" "$file" "$line_num"
            fi
        done <<< "$matches"
    fi
}

add_header

process_file "$MAIN_YAML_FILE"

if [[ -d "$ADDITIONAL_YAML_DIR" ]]; then
    for yaml_file in "$ADDITIONAL_YAML_DIR"/*.{yml,yaml}; do
        [[ -e "$yaml_file" ]] || continue
        process_file "$yaml_file"
    done
else
    echo "Дополнительная папка '$ADDITIONAL_YAML_DIR' не найдена."
fi

echo "Генерация POT файла завершена. Результат сохранен в '$POT_FILE'."
