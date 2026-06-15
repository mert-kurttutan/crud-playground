#!/usr/bin/env nu

def main [
  --image-uri: string
  --function-name: string = "crud-fastapi"
  --region: string = "us-east-1"
  --wait
] {
aws lambda update-function-code --function-name $function_name --image-uri $image_uri --region $region

if $wait {
  aws lambda wait function-updated --function-name $function_name --region $region
}
}
