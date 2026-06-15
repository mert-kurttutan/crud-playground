#!/usr/bin/env nu

def main [
  --image-uri: string
] {
let stack_name = ($env.STACK_NAME? | default "crud-serverless-api")
let aws_region = ($env.AWS_REGION? | default "us-east-1")
let template_file = ($env.TEMPLATE_FILE? | default "infra/serverless-api.yml")
let custom_domain_name = ($env.CUSTOM_DOMAIN_NAME? | default "api.crud.mert-kurttutan.com")

if ($image_uri == null) {
  error make { msg: "--image-uri is required" }
}

let env_certificate_arn = ($env.CERTIFICATE_ARN? | default "")
let certificate_arn = if ($env_certificate_arn != "") {
  $env_certificate_arn
} else {
  aws acm list-certificates --region $aws_region --query $"CertificateSummaryList[?DomainName=='($custom_domain_name)' && Status=='ISSUED'].CertificateArn | [0]" --output text
  | str trim
}

if (($certificate_arn == "") or ($certificate_arn == "None")) {
  error make { msg: $"Could not find an issued ACM certificate for ($custom_domain_name) in ($aws_region). Set CERTIFICATE_ARN to override." }
}

aws cloudformation deploy --template-file $template_file --stack-name $stack_name --capabilities CAPABILITY_NAMED_IAM --region $aws_region --parameter-overrides $"ImageUri=($image_uri)" $"CustomDomainName=($custom_domain_name)" $"CertificateArn=($certificate_arn)"
}
