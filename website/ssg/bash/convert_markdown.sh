#!/bin/bash
INPUT_DIR="/var/www/markdown_site/markdown"
OUTPUT_DIR="/var/www/markdown_site/html"
TEMPLATE_DIR="/var/www/markdown_site/html/templates"
CSS_PATH="/var/www/markdown_site/html/css/custom-style.css"

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
        "$TEMPLATE_DIR/post_template.html" > "$temp_file"

    # Insert the converted HTML content into the placeholder {{post_content}}
    awk -v content="$content" '{gsub(/{{post_content}}/, content); print}' "$temp_file" > "$output_file"

    # Display only the generated file path and name
    echo "Generated file: $output_file"

    # Remove the temporary file
    rm "$temp_file"
done
