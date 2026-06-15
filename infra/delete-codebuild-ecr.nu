#!/usr/bin/env nu

def main [
  --stack-name: string = "crud-codebuild-ecr"
  --repository-name: string = "crud/fastapi"
  --region: string = "us-east-1"
  --wait
] {
print $"Emptying ECR repository ($repository_name) in ($region)"

let image_ids = (
  aws ecr list-images --repository-name $repository_name --region $region --query "imageIds" --output json
  | from json
)

if (($image_ids | length) > 0) {
  let image_ids_json = ($image_ids | to json)

  aws ecr batch-delete-image --repository-name $repository_name --region $region --image-ids $image_ids_json
} else {
  print $"No images found in ($repository_name)"
}

print $"Deleting CloudFormation stack ($stack_name) in ($region)"

aws cloudformation delete-stack --stack-name $stack_name --region $region

if $wait {
  print $"Waiting for stack ($stack_name) deletion to complete"
  aws cloudformation wait stack-delete-complete --stack-name $stack_name --region $region
  print $"Deleted stack ($stack_name)"
}
}
