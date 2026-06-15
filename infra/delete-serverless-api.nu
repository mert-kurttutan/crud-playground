#!/usr/bin/env nu

def main [
  --stack-name: string = "crud-serverless-api"
  --region: string = "us-east-1"
  --wait
] {
print $"Deleting CloudFormation stack ($stack_name) in ($region)"

aws cloudformation delete-stack --stack-name $stack_name --region $region

if $wait {
  print $"Waiting for stack ($stack_name) deletion to complete"
  aws cloudformation wait stack-delete-complete --stack-name $stack_name --region $region
  print $"Deleted stack ($stack_name)"
}
}
