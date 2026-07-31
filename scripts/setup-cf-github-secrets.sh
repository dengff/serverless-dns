#!/usr/bin/env bash
# Configure GitHub Actions secrets required by .github/workflows/cf.yml
# Usage:
#   ./scripts/setup-cf-github-secrets.sh
#   CF_API_TOKEN=... CF_ACCOUNT_ID=... ./scripts/setup-cf-github-secrets.sh
set -euo pipefail

REPO="${REPO:-dengff/serverless-dns}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI required. Install: brew install gh && gh auth login"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI not logged in. Run: gh auth login"
  exit 1
fi

if [ -z "${CF_ACCOUNT_ID:-}" ]; then
  if command -v npx >/dev/null 2>&1; then
    echo "Resolving CF_ACCOUNT_ID via wrangler whoami (if logged in)..."
    CF_ACCOUNT_ID="$(npx wrangler whoami 2>/dev/null | awk -F'│' '/Account ID/ {gsub(/ /,"",$3); if($3 ~ /^[a-f0-9]{32}$/) print $3}' | tail -1 || true)"
  fi
fi

if [ -z "${CF_ACCOUNT_ID:-}" ]; then
  read -r -p "CF_ACCOUNT_ID: " CF_ACCOUNT_ID
fi

if [ -z "${CF_API_TOKEN:-}" ]; then
  echo "Create a token at https://dash.cloudflare.com/profile/api-tokens"
  echo "Use template: Edit Cloudflare Workers"
  read -r -s -p "CF_API_TOKEN (input hidden): " CF_API_TOKEN
  echo
fi

if [ -z "$CF_ACCOUNT_ID" ] || [ -z "$CF_API_TOKEN" ]; then
  echo "Both CF_ACCOUNT_ID and CF_API_TOKEN are required"
  exit 1
fi

printf '%s' "$CF_ACCOUNT_ID" | gh secret set CF_ACCOUNT_ID -R "$REPO"
printf '%s' "$CF_API_TOKEN" | gh secret set CF_API_TOKEN -R "$REPO"

echo "Configured secrets on $REPO:"
gh secret list -R "$REPO"
echo "Re-run the CF workflow: gh workflow run cf.yml -R $REPO"
