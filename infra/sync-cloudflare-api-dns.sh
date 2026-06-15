#!/usr/bin/env bash
set -euo pipefail

RECORD_NAME="${RECORD_NAME:-api.crud.mert-kurttutan.com}"
STACK_NAME="${STACK_NAME:-crud-serverless-api}"
AWS_REGION="${AWS_REGION:-us-east-1}"
OUTPUT_KEY="${OUTPUT_KEY:-CustomDomainRegionalTarget}"
PROXIED="${CLOUDFLARE_PROXIED:-false}"
TTL="${CLOUDFLARE_TTL:-1}"

target="$(
  aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='$OUTPUT_KEY'].OutputValue" \
    --output text
)"

if [ -z "$target" ] || [ "$target" = "None" ]; then
  echo "Could not find $OUTPUT_KEY output on stack $STACK_NAME" >&2
  exit 1
fi

if [ -z "${CLOUDFLARE_API_TOKEN:-}" ]; then
  echo "CLOUDFLARE_API_TOKEN is required" >&2
  exit 2
fi

if [ -z "${CLOUDFLARE_ZONE_ID:-}" ]; then
  echo "CLOUDFLARE_ZONE_ID is required" >&2
  exit 2
fi

API_BASE="https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records"

record_id="$(
  curl -fsS \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    "$API_BASE?type=CNAME&name=$RECORD_NAME" \
    | jq -r '.result[0].id // empty'
)"

payload="$(
  jq -n \
    --arg name "$RECORD_NAME" \
    --arg content "$target" \
    --argjson proxied "$PROXIED" \
    --argjson ttl "$TTL" \
    '{
      type: "CNAME",
      name: $name,
      content: $content,
      ttl: $ttl,
      proxied: $proxied
    }'
)"

if [ -n "$record_id" ]; then
  echo "Updating CNAME $RECORD_NAME -> $target"
  curl -fsS \
    -X PUT "$API_BASE/$record_id" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json" \
    --data "$payload" \
    | jq '{success, result: {id: .result.id, name: .result.name, content: .result.content, proxied: .result.proxied}}'
else
  echo "Creating CNAME $RECORD_NAME -> $target"
  curl -fsS \
    -X POST "$API_BASE" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json" \
    --data "$payload" \
    | jq '{success, result: {id: .result.id, name: .result.name, content: .result.content, proxied: .result.proxied}}'
fi
