#!/bin/bash
# Script to update the "Last updated" date in privacy-policy.html from git

FILE="privacy-policy.html"
DATE_PLACEHOLDER='<span id="date"></span>'

# Get the last commit date for the file
if git ls-files --error-unmatch "$FILE" >/dev/null 2>&1; then
    # File is tracked in git, get the last commit date
    LAST_DATE=$(git log -1 --format="%ai" -- "$FILE")
    if [ -n "$LAST_DATE" ]; then
        # Format the date nicely
        FORMATTED_DATE=$(date -d "$LAST_DATE" +"%B %d, %Y" 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S %z" "$LAST_DATE" +"%B %d, %Y" 2>/dev/null || echo "$LAST_DATE")
    else
        # Fallback to current date if no git history
        FORMATTED_DATE=$(date +"%B %d, %Y")
    fi
else
    # File not in git yet, use current date
    FORMATTED_DATE=$(date +"%B %d, %Y")
fi

# Update the HTML file
if [ -f "$FILE" ]; then
    # Replace the placeholder with the actual date
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|$DATE_PLACEHOLDER|$FORMATTED_DATE|g" "$FILE"
    else
        # Linux
        sed -i "s|$DATE_PLACEHOLDER|$FORMATTED_DATE|g" "$FILE"
    fi
    echo "Updated privacy policy date to: $FORMATTED_DATE"
else
    echo "Error: $FILE not found"
    exit 1
fi
