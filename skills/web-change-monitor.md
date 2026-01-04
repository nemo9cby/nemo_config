# Web Change Monitor Skill

A skill to help users set up automated web page monitoring with change detection and notifications.

## Description

This skill guides users through creating a complete web monitoring system that:
- Fetches content from URLs (single page, list, or pattern-based)
- Detects changes by comparing with stored versions
- Generates HTML diff reports
- Sends notifications via Telegram, Slack, Discord, or email
- Deploys reports to GitHub Pages, local server, or cloud storage

## Workflow

### Step 1: Gather Requirements

Ask the user about their monitoring needs:

1. **What to monitor?**
   - Single URL
   - List of URLs
   - URL pattern (e.g., `https://docs.example.com/{page}.html`)
   - Sitemap-based discovery
   - RSS/Atom feed

2. **What content to track?**
   - Full page content
   - Specific CSS selector (e.g., `.main-content`, `#price`)
   - Specific XPath
   - JSON path (for API endpoints)

3. **How to be notified?**
   - Telegram bot
   - Slack webhook
   - Discord webhook
   - Email (SMTP)
   - Custom webhook

4. **Where to host reports?**
   - GitHub Pages (free, requires GitHub repo)
   - Local server (for development/private use)
   - No reports (notification only)

5. **How to schedule?**
   - GitHub Actions (free, recommended for public repos)
   - Local cron job
   - Manual trigger only

### Step 2: Generate Project Structure

Based on requirements, create:

```
{project-name}/
├── src/
│   ├── __init__.py
│   ├── config.py          # Configuration loader
│   ├── fetcher.py         # Async HTTP fetcher
│   ├── differ.py          # Diff computation
│   ├── reporter.py        # HTML report generator
│   ├── notifier.py        # Notification sender
│   └── main.py            # CLI orchestrator
├── tests/
│   └── test_*.py          # pytest tests
├── templates/
│   ├── page_diff.html
│   ├── daily_index.html
│   └── main_index.html
├── config/
│   ├── config.yaml        # Main configuration
│   └── pages.yaml         # URLs/pages to monitor (if applicable)
├── .github/workflows/
│   └── monitor.yml        # GitHub Actions workflow (if selected)
├── .env.example           # Environment variables template
├── pyproject.toml
└── README.md
```

### Step 3: Core Components

#### Config (src/config.py)
```python
from dataclasses import dataclass
from pathlib import Path
import yaml
import os

@dataclass
class Config:
    source_urls: list[str]
    storage_dir: Path
    reports_dir: Path
    telegram_token: str | None
    telegram_chat_id: str | None
    slack_webhook: str | None
    base_url: str

    @classmethod
    def load(cls, config_path: Path) -> "Config":
        # Load from YAML + environment variables
        ...
```

#### Fetcher (src/fetcher.py)
```python
import httpx
from dataclasses import dataclass

@dataclass
class FetchResult:
    url: str
    content: str | None
    status_code: int
    error: str | None

class Fetcher:
    async def fetch(self, url: str) -> FetchResult:
        # Async HTTP fetch with retries
        ...

    async def fetch_all(self, urls: list[str]) -> list[FetchResult]:
        # Concurrent fetching with rate limiting
        ...
```

#### Differ (src/differ.py)
```python
from dataclasses import dataclass
import difflib

@dataclass
class DiffResult:
    url: str
    has_changes: bool
    added_lines: int
    removed_lines: int
    unified_diff: str
    html_diff: str

class Differ:
    def compute(self, old: str, new: str, url: str) -> DiffResult:
        # Generate unified and HTML diffs
        ...
```

#### Reporter (src/reporter.py)
```python
from jinja2 import Environment, FileSystemLoader
from pathlib import Path
from datetime import datetime

class Reporter:
    def generate_page_diff(self, diff: DiffResult, timestamp: datetime) -> Path:
        # Generate individual page diff HTML
        ...

    def generate_daily_index(self, diffs: list[DiffResult], timestamp: datetime) -> Path:
        # Generate daily index with all changes
        # Support multiple batches per day
        ...

    def update_main_index(self) -> Path:
        # Update main index listing all dates
        ...
```

#### Notifier (src/notifier.py)
```python
class TelegramNotifier:
    async def send(self, changes: list[DiffResult], report_url: str) -> bool:
        # Send Telegram notification
        ...

class SlackNotifier:
    async def send(self, changes: list[DiffResult], report_url: str) -> bool:
        # Send Slack notification
        ...

class DiscordNotifier:
    async def send(self, changes: list[DiffResult], report_url: str) -> bool:
        # Send Discord notification
        ...
```

#### Main (src/main.py)
```python
import click
import asyncio

@click.command()
@click.option("--config", default="config/config.yaml")
@click.option("--no-notify", is_flag=True)
def main(config: str, no_notify: bool):
    # Orchestrate: fetch -> diff -> report -> notify
    ...
```

### Step 4: Configuration Templates

#### config/config.yaml
```yaml
source:
  type: url_list  # url_list | url_pattern | sitemap
  urls:
    - https://example.com/page1
    - https://example.com/page2
  # OR for pattern:
  # pattern: "https://example.com/docs/{page}.html"
  # pages: [intro, guide, api]

storage:
  docs_dir: "data/docs"
  reports_dir: "reports"

notifications:
  telegram:
    enabled: true
    # bot_token: from TELEGRAM_BOT_TOKEN env
    # chat_id: from TELEGRAM_CHAT_ID env
  slack:
    enabled: false
    # webhook_url: from SLACK_WEBHOOK_URL env

reports:
  base_url: "https://user.github.io/repo"

fetcher:
  concurrency: 5
  delay: 0.5
  timeout: 30
  retry_count: 3
```

### Step 5: GitHub Actions Workflow

```yaml
name: Monitor Web Changes

on:
  schedule:
    - cron: '0 * * * *'  # Hourly
  workflow_dispatch:

jobs:
  monitor:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: pip install -e .

      - name: Run monitor
        env:
          TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          TELEGRAM_CHAT_ID: ${{ secrets.TELEGRAM_CHAT_ID }}
        run: python -m src.main

      - name: Commit changes
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add data/ reports/
          git diff --staged --quiet || git commit -m "Update $(date +%Y-%m-%d)"
          git pull --rebase || true
          git push

  deploy-pages:
    needs: monitor
    runs-on: ubuntu-latest
    permissions:
      pages: write
      id-token: write
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/checkout@v4
        with:
          ref: main
      - uses: actions/configure-pages@v4
      - uses: actions/upload-pages-artifact@v3
        with:
          path: reports/
      - uses: actions/deploy-pages@v4
        id: deployment
```

### Step 6: Setup Instructions

After generating the project, guide the user through:

1. **Create GitHub repo** (if using GitHub Pages)
   ```bash
   gh repo create {repo-name} --public
   git init && git add . && git commit -m "Initial commit"
   git remote add origin https://github.com/{user}/{repo}.git
   git push -u origin main
   ```

2. **Set up Telegram bot** (if using Telegram)
   - Message @BotFather on Telegram
   - Send `/newbot` and follow prompts
   - Copy the bot token
   - Send a message to your bot
   - Get chat ID from: `https://api.telegram.org/bot{TOKEN}/getUpdates`

3. **Configure secrets** (for GitHub Actions)
   ```bash
   gh secret set TELEGRAM_BOT_TOKEN
   gh secret set TELEGRAM_CHAT_ID
   ```

4. **Enable GitHub Pages**
   - Go to repo Settings > Pages
   - Set Source to "GitHub Actions"

5. **Test locally**
   ```bash
   python -m venv .venv && source .venv/bin/activate
   pip install -e ".[dev]"
   python -m src.main --no-notify
   ```

6. **Trigger first run**
   ```bash
   gh workflow run monitor.yml
   ```

## Example Use Cases

### 1. Documentation Monitor
Monitor technical documentation for updates:
```yaml
source:
  type: url_pattern
  pattern: "https://docs.example.com/{page}.html"
  pages: [getting-started, api-reference, changelog]
```

### 2. Price Tracker
Monitor product prices:
```yaml
source:
  type: url_list
  urls:
    - https://store.com/product/123
extractor:
  type: css_selector
  selector: ".price"
```

### 3. Competitor Blog Monitor
Track competitor blog posts:
```yaml
source:
  type: rss
  url: https://competitor.com/blog/feed.xml
```

### 4. API Status Monitor
Monitor API responses:
```yaml
source:
  type: api
  url: https://api.example.com/status
  headers:
    Authorization: "Bearer ${API_TOKEN}"
extractor:
  type: json_path
  path: "$.status"
```

## Dependencies

```toml
[project]
dependencies = [
    "httpx>=0.27",
    "jinja2>=3.1",
    "pyyaml>=6.0",
    "click>=8.1",
    "rich>=13.0",
    "python-telegram-bot>=21.0",
    "diff-match-patch>=20230430",
]

[project.optional-dependencies]
dev = ["pytest", "pytest-asyncio", "pytest-mock", "respx", "ruff"]
slack = ["slack-sdk"]
discord = ["discord.py"]
```

## Testing Approach

Use TDD - write tests first:
- Mock external HTTP calls with `respx`
- Mock Telegram/Slack with `pytest-mock`
- Use `tmp_path` fixture for file operations
- Run `pytest -xvs` before declaring complete

## Key Features to Implement

1. **Multiple batches per day**: Accumulate changes from multiple runs under one date
2. **Graceful error handling**: Continue on individual page failures
3. **Rate limiting**: Respect target site's resources
4. **Retry logic**: Handle transient failures
5. **HTML diff visualization**: Side-by-side and inline diffs
6. **Configurable notifications**: Template-based messages
