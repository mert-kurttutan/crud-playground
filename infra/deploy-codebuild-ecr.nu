#!/usr/bin/env nu

def main [
  --stack-name: string = "crud-codebuild-ecr"
  --region: string = "us-east-1"
  --template-file: string = "infra/codebuild-ecr.yml"
  --project-name: string = "crud-backend-image"
  --github-repository-url: string = "https://github.com/mert-kurttutan/crud-playground"
  --source-version: string = "main"
  --image-repository-name: string = "crud/fastapi"
  --start-build
] {
aws cloudformation deploy --template-file $template_file --stack-name $stack_name --capabilities CAPABILITY_NAMED_IAM --region $region --parameter-overrides $"ProjectName=($project_name)" $"GitHubRepositoryUrl=($github_repository_url)" $"SourceVersion=($source_version)" $"ImageRepositoryName=($image_repository_name)"

if $start_build {
  aws codebuild start-build --project-name $project_name --region $region
}
}
