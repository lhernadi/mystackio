# Setup Guide — Levente's AI Stack

A complete setup guide for running Claude Code with a local model proxy, private web search, and a full suite of plugins.

---

## What you're setting up

This stack has three layers:

| Layer | What it is | Why |
|---|---|---|
| **Claude Code** | The AI coding assistant | The main interface |
| **Anthropic API** | Direct API connection | Powers Claude — you'll need an API key |
| **SearXNG** | Self-hosted search engine (port 8080) | Private web search — Claude's web searches go here instead of external APIs |

Plus 6 plugins (superpowers, GitHub, Atlassian, Slack, Figma, Chrome DevTools) and 5 MCP servers that extend what Claude can do.

---

## Prerequisites

- Mac (Apple Silicon or Intel)
- [Homebrew](https://brew.sh) installed
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- An [Anthropic API key](https://console.anthropic.com/settings/keys)

---

## Step 1 — Install Claude Code

```bash
brew install --cask claude
```

Or download from [claude.ai/download](https://claude.ai/download).

---

## Step 2 — Get an Anthropic API key

1. Go to [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys)
2. Sign in or create an account
3. Click **Create Key**, give it a name, and copy the key — you'll need it in the next step

---

## Step 3 — Configure Claude Code

Open (or create) `~/.claude/settings.json` and add:

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "YOUR_ANTHROPIC_API_KEY"
  },
  "permissions": {
    "defaultMode": "default"
  }
}
```

Replace `YOUR_ANTHROPIC_API_KEY` with the key you copied in Step 2.

That's all you need — Claude Code will connect directly to the Anthropic API.

---

## Step 4 — Install plugins

```bash
claude plugin install superpowers@claude-plugins-official
claude plugin install github@claude-plugins-official
claude plugin install atlassian@claude-plugins-official
claude plugin install slack@claude-plugins-official
claude plugin install figma@claude-plugins-official
claude plugin install chrome-devtools-mcp@claude-plugins-official
```

---

## Step 5 — Configure MCP servers

Add the following to the `mcpServers` section of `~/.claude/settings.json`. Replace each placeholder with your own credentials.

```json
"mcpServers": {
  "github": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-github"],
    "env": {
      "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_GITHUB_PAT"
    }
  },
  "confluence": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-confluence"],
    "env": {
      "CONFLUENCE_API_TOKEN": "YOUR_ATLASSIAN_API_TOKEN",
      "CONFLUENCE_EMAIL": "your@email.com",
      "CONFLUENCE_URL": "https://yourcompany.atlassian.net/wiki"
    }
  },
  "jira": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-jira"],
    "env": {
      "JIRA_API_TOKEN": "YOUR_ATLASSIAN_API_TOKEN",
      "JIRA_EMAIL": "your@email.com",
      "JIRA_URL": "https://yourcompany.atlassian.net"
    }
  },
  "figma": {
    "command": "npx",
    "args": ["-y", "figma-developer-mcp", "--figma-api-key", "YOUR_FIGMA_API_KEY"]
  },
  "chrome-devtools": {
    "command": "npx",
    "args": ["chrome-devtools-mcp@latest", "--browserUrl", "http://127.0.0.1:9222"]
  }
}
```

**Where to get each credential:**

| Credential | Where to get it |
|---|---|
| GitHub PAT | [github.com/settings/tokens](https://github.com/settings/tokens) — needs `repo`, `read:org` scopes |
| Atlassian API token | [id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens) |
| Figma API key | Figma → Account Settings → Personal access tokens |

---

## Step 6 — Install additional skills

### Deep Research skill

An enterprise-grade research pipeline with 8 phases, source credibility scoring, and citation tracking — more powerful than the built-in web search.

```bash
git clone https://github.com/199-biotechnologies/claude-deep-research-skill.git ~/.claude/skills/deep-research
```

Use it with `/deep-research <topic>` in Claude Code.

### Council of High Intelligence

18 AI personas (Aristotle, Feynman, Kahneman, Torvalds, and more) deliberate your hardest decisions in a structured multi-round format.

```bash
curl -fsSL https://raw.githubusercontent.com/0xNyk/council-of-high-intelligence/main/install.sh | bash
```

Use it with `/council` in Claude Code.

---

## Step 7 — Set up private web search (SearXNG)

This gives Claude private, local web search. No search queries leave your machine.

### Install the hook script

```bash
mkdir -p ~/.claude/scripts
curl -fsSL https://raw.githubusercontent.com/lhernadi/mystackio/main/scripts/websearch.sh \
  -o ~/.claude/scripts/websearch.sh
chmod +x ~/.claude/scripts/websearch.sh
```

### Start SearXNG

```bash
docker pull searx/searx
docker run -d \
  --name searxng \
  -p 8080:8080 \
  --restart unless-stopped \
  searx/searx
```

Verify it's running: open [http://localhost:8080](http://localhost:8080) in your browser.

### Add the hook to Claude Code settings

Add the following to `~/.claude/settings.json`:

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "WebSearch",
      "hooks": [
        {
          "type": "command",
          "command": "~/.claude/scripts/websearch.sh",
          "timeout": 30,
          "statusMessage": "Searching via SearXNG..."
        }
      ]
    }
  ]
}
```

From now on, whenever Claude searches the web, it uses your local SearXNG instead of any external service.

---

## Step 8 — Verify everything works

Open Claude Code in any project folder and try:

```
/brainstorm    → AI-assisted feature planning
/commit        → generate a git commit message
/deep-research → multi-source research with a written report
```

Ask Claude to search the web — you should see "Searching via SearXNG..." in the status bar.

Check your MCP servers are connected:
```bash
claude mcp list
```

---

## Keeping it running

- **SearXNG** — runs as a Docker container with `--restart unless-stopped`, so it restarts with Docker Desktop

To restart SearXNG manually:
```bash
docker restart searxng
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Claude Code can't connect to API | Check your `ANTHROPIC_AUTH_TOKEN` in `~/.claude/settings.json` is correct |
| Web search not working | Check SearXNG is running: `curl http://localhost:8080` |
| MCP server not showing | Run `claude mcp list` — check for error messages next to the server name |
| Chrome DevTools not connecting | Open Chrome with `--remote-debugging-port=9222` flag first |
