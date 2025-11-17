#!/bin/bash
# Script to update the "Last updated" date in privacy-policy.html from git

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE="$SCRIPT_DIR/privacy-policy.html"

# Get relative path from repo root for git commands
GIT_FILE="docs/privacy-policy.html"

# Check if file is tracked in git
if ! git ls-files --error-unmatch "$GIT_FILE" >/dev/null 2>&1; then
    echo "Error: $GIT_FILE is not tracked in git"
    exit 1
fi

# Get the last commit date for the file
LAST_DATE=$(git log -1 --format="%ai" -- "$GIT_FILE")
if [ -z "$LAST_DATE" ]; then
    echo "Error: No git history found for $GIT_FILE"
    exit 1
fi

# Format the date nicely
FORMATTED_DATE=$(date -d "$LAST_DATE" +"%B %d, %Y" 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S %z" "$LAST_DATE" +"%B %d, %Y" 2>/dev/null || echo "$LAST_DATE")

# Update the HTML file
if [ -f "$FILE" ]; then
    # Replace "Last updated: " followed by any date (handles both placeholder and existing dates)
    # Pattern matches: "Last updated: " followed by any text until </p>
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - use sed with extended regex
        sed -i '' -E "s|(Last updated: )[^<]*(</p>)|\1$FORMATTED_DATE\2|g" "$FILE"
    else
        # Linux - use sed with extended regex
        sed -i -E "s|(Last updated: )[^<]*(</p>)|\1$FORMATTED_DATE\2|g" "$FILE"
    fi
    echo "Updated privacy policy date to: $FORMATTED_DATE"
else
    echo "Error: $FILE not found"
    exit 1
fi
