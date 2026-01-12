#!/bin/bash

clear

# Check if bluebuild is installed
if ! command -v bluebuild &> /dev/null; then
    echo "Error: 'bluebuild' command not found."
    echo "Please install it following the instructions at https://blue-build.org/how-to/local/"
    exit 1
fi

# Directory containing recipes
RECIPE_DIR="./recipes"

# Check if recipes directory exists
if [ ! -d "$RECIPE_DIR" ]; then
    echo "Error: Recipes directory '$RECIPE_DIR' not found."
    exit 1
fi

# Get list of recipe files (assuming .yml extension)
recipes=($(ls "$RECIPE_DIR"/*.yml 2>/dev/null | xargs -n 1 basename))

if [ ${#recipes[@]} -eq 0 ]; then
    echo "No recipes found in '$RECIPE_DIR'."
    exit 1
fi

echo "Available recipes:"
for i in "${!recipes[@]}"; do 
    echo "$((i+1)). ${recipes[$i]}"
done

# Prompt user for selection
read -p "Select a recipe number to build: " selection

# Validate input
if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#recipes[@]}" ]; then
    echo "Invalid selection."
    exit 1
fi

# Get selected recipe
selected_recipe="${recipes[$((selection-1))]}"

echo "Building $selected_recipe..."

# Run bluebuild
bluebuild build "${RECIPE_DIR}/${selected_recipe}"
