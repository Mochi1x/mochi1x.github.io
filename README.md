# My Journal Widgets

A simple HTML site hosting custom widgets for embedding into Notion journal.

## Setup

1. Edit `index.html` and add your widget HTML code in the widget container sections
2. Push to GitHub repository named `YOUR_USERNAME.github.io`
3. Enable GitHub Pages in repository settings

## Embedding in Notion

1. Publish your site on GitHub Pages
2. In Notion, add an **Embed** block
3. Enter your site URL: `https://YOUR_USERNAME.github.io`
4. The entire page will embed — you can also embed specific widgets by creating separate HTML files

## Widget Structure

Each widget is in a `.widget` div with an ID. Replace the placeholder content with your actual widget code.

Example widget structure:

```html
<div class="widget">
    <h3>Widget Name</h3>
    <div class="widget-content" id="widget1">
        <!-- Your widget HTML/JS/CSS here -->
    </div>
</div>
```

## Local Preview

```bash
cd /home/jaypa/github-pages-site
python3 -m http.server 8000
# Visit http://localhost:8000
```
