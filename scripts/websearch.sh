#!/usr/bin/env bash
# Claude Code WebSearch hook — redirects to local SearXNG instance
# Input: JSON on stdin with tool_input.query
# Output: JSON with hookSpecificOutput.additionalContext containing search results

SEARXNG_URL="http://localhost:8080"
MAX_RESULTS=10

# Read stdin
INPUT=$(cat)

# Extract query
QUERY=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('query',''))" 2>/dev/null)

if [ -z "$QUERY" ]; then
  # No query found, let Claude handle it normally
  exit 0
fi

# Check if SearXNG is running
if ! curl -sf "${SEARXNG_URL}/healthz" > /dev/null 2>&1 && ! curl -sf "${SEARXNG_URL}" > /dev/null 2>&1; then
  # SearXNG not running — try to start it
  docker run -d --name searxng -p 8080:8080 --restart unless-stopped searx/searx > /dev/null 2>&1
  # Wait up to 10 seconds for it to start
  for i in $(seq 1 10); do
    sleep 1
    if curl -sf "${SEARXNG_URL}" > /dev/null 2>&1; then
      break
    fi
  done
fi

# Perform search
RESULTS=$(curl -sf \
  --max-time 15 \
  --get \
  --data-urlencode "q=${QUERY}" \
  --data "format=json" \
  --data "categories=general" \
  "${SEARXNG_URL}/search" 2>/dev/null)

if [ -z "$RESULTS" ]; then
  # Search failed — let Claude fall back to its own behavior
  exit 0
fi

# Format results as readable text
FORMATTED=$(echo "$RESULTS" | python3 -c "
import sys, json

try:
    data = json.load(sys.stdin)
    results = data.get('results', [])
    query = data.get('query', '')

    if not results:
        print('No results found.')
        sys.exit(0)

    lines = ['Search results for: ' + query + '\n']
    for i, r in enumerate(results[:10], 1):
        title = r.get('title', 'No title')
        url = r.get('url', '')
        content = r.get('content', '').strip()
        lines.append(str(i) + '. ' + title)
        lines.append('   URL: ' + url)
        if content:
            lines.append('   ' + content[:200])
        lines.append('')

    print('\n'.join(lines))
except Exception as e:
    print('Error parsing results: ' + str(e))
    sys.exit(0)
")

# Output JSON for Claude Code hook system
python3 -c "
import json, sys
context = sys.argv[1]
output = {
    'hookSpecificOutput': {
        'hookEventName': 'PreToolUse',
        'additionalContext': context
    }
}
print(json.dumps(output))
" "$FORMATTED"

exit 2
