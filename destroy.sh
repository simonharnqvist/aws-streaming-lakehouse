source .env 
export TF_VAR_ldbws_token="${LDBWS_TOKEN}"

terraform destroy -target=aws_s3_bucket.raw
terraform destroy -auto-approve