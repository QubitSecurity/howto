#!/bin/bash
INPUT_DIR="/usr/share/nginx/html/w_plura_markdown"
OUTPUT_DIR="/usr/share/nginx/html/w_plura"
TEMPLATE_DIR="/usr/share/nginx/html/w_plura/templates"
CSS_PATH="/usr/share/nginx/html/w_plura/css/custom-style.css"
GITHUB_BASE_URL="https://github.com/qubitsec/plura/blob/main"  # Base URL of your GitHub repo

# Ensure the output directory exists
mkdir -p "$OUTPUT_DIR"

# Loop through all markdown files in INPUT_DIR and its subdirectories
find "$INPUT_DIR" -type f -name "*.md" | while read -r file; do
    # Extract the filename and directory path
    filename=$(basename "$file" .md)
    title=$(head -n 1 "$file" | sed 's/# //')  # Extract title from the first line of each file
    lang="en"  # Default language code for each file

    # Define the relative path for the output file within OUTPUT_DIR
    relative_path=$(dirname "${file#$INPUT_DIR/}")
    output_dir="$OUTPUT_DIR/$relative_path"
    output_file="$output_dir/${filename}.html"

    # Ensure the output directory exists
    mkdir -p "$output_dir"

    # Construct the source link for the original GitHub file
    source_link="$GITHUB_BASE_URL/$relative_path/$filename.md"

    # Convert the markdown content to HTML using Pandoc
    content=$(pandoc "$file" -f markdown -t html)

    # Define the language switcher HTML
    language_switcher="<div class=\"language-switcher\"><a href=\"index.en.html\">EN</a> / <a href=\"index.ko.html\">KO</a> / <a href=\"index.ja.html\">JA</a></div>"

    # Create a temporary file and replace placeholders
    temp_file=$(mktemp)
    sed -e "s|{{post_title}}|$title|g" \
        -e "s|{{lang}}|$lang|g" \
        -e "s|{{year}}|$(date +'%Y')|g" \
        -e "s|{{language_switcher}}|$language_switcher|g" \
        -e "s|{{source_link}}|$source_link|g" \
        "$TEMPLATE_DIR/post_template.html" > "$temp_file"

    # Insert the converted HTML content into the placeholder {{post_content}}
    awk -v content="$content" '{gsub(/{{post_content}}/, content); print}' "$temp_file" > "$output_file"

    # Display only the generated file path and name
    echo "Generated file: $output_file"

    # Remove the temporary file
    rm "$temp_file"
done
