#!/usr/bin/env nu

def main [
  --record-name: string = "api.crud.mert-kurttutan.com"
] {
let token = ($env.CLOUDFLARE_API_TOKEN? | default "")
let zone_id = ($env.CLOUDFLARE_ZONE_ID? | default "")

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

if ($record_id == "") {
  print $"No CNAME found for ($record_name)"
  return
}

print $"Deleting CNAME ($record_name)"

let response = (
  curl -fsS -X DELETE $"($api_base)/($record_id)" -H $auth_header
  | from json
)

{
  success: $response.success
  deleted_record_id: $record_id
  record_name: $record_name
}
}
