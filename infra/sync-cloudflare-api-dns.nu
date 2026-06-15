#!/usr/bin/env nu

let record_name = ($env.RECORD_NAME? | default "api.crud.mert-kurttutan.com")
let stack_name = ($env.STACK_NAME? | default "crud-serverless-api")
let aws_region = ($env.AWS_REGION? | default "us-east-1")
let output_key = ($env.OUTPUT_KEY? | default "CustomDomainRegionalTarget")
let proxied = (($env.CLOUDFLARE_PROXIED? | default "false") == "true")
let ttl = ($env.CLOUDFLARE_TTL? | default "1" | into int)
let token = ($env.CLOUDFLARE_API_TOKEN? | default "")
let zone_id = ($env.CLOUDFLARE_ZONE_ID? | default "")

let target = (
  aws cloudformation describe-stacks --stack-name $stack_name --region $aws_region --query $"Stacks[0].Outputs[?OutputKey=='($output_key)'].OutputValue" --output text
  | str trim
)

if (($target == "") or ($target == "None")) {
  error make { msg: $"Could not find ($output_key) output on stack ($stack_name)" }
}

if ($token == "") {
  error make { msg: "CLOUDFLARE_API_TOKEN is required" }
}

if ($zone_id == "") {
  error make { msg: "CLOUDFLARE_ZONE_ID is required" }
}

let api_base = $"https://api.cloudflare.com/client/v4/zones/($zone_id)/dns_records"
let auth_header = $"Authorization: Bearer ($token)"

let existing = (
  curl -fsS -H $auth_header $"($api_base)?type=CNAME&name=($record_name)"
  | from json
)

let record_id = (
  $existing.result
  | get --optional 0.id
  | default ""
)

let payload = {
  type: "CNAME"
  name: $record_name
  content: $target
  ttl: $ttl
  proxied: $proxied
} | to json

if ($record_id != "") {
  print $"Updating CNAME ($record_name) -> ($target)"

  let response = (
    curl -fsS -X PUT $"($api_base)/($record_id)" -H $auth_header -H "Content-Type: application/json" --data $payload
    | from json
  )

  {
    success: $response.success
    result: {
      id: $response.result.id
      name: $response.result.name
      content: $response.result.content
      proxied: $response.result.proxied
    }
  }
} else {
  print $"Creating CNAME ($record_name) -> ($target)"

  let response = (
    curl -fsS -X POST $api_base -H $auth_header -H "Content-Type: application/json" --data $payload
    | from json
  )

  {
    success: $response.success
    result: {
      id: $response.result.id
      name: $response.result.name
      content: $response.result.content
      proxied: $response.result.proxied
    }
  }
}
