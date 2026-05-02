#!/bin/bash

# GitHub Pages deployment helper script
# Usage: ./deploy.sh "Your commit message"

SITE_DIR="/home/jaypa/github-pages-site"
REPO_NAME="YOUR_USERNAME.github.io"  # Change this to your actual username

cd "$SITE_DIR"

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "Initializing git repository..."
    git init
    git remote add origin "https://github.com/$REPO_NAME.git"
fi

# Add all files
git add .

# Commit
if [ -z "$1" ]; then
    COMMIT_MSG="Update site - $(date '+%Y-%m-%d %H:%M')"
else
    COMMIT_MSG="$1"
fi

git commit -m "$COMMIT_MSG"

# Push to GitHub
git push -u origin main

echo ""
echo "✓ Deployed to GitHub Pages!"
echo "  Your site will be live at: https://$REPO_NAME"
echo "  (Wait 1-2 minutes for the first deployment)"
