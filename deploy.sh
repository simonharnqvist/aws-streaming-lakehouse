source .env 
export TF_VAR_ldbws_token="${LDBWS_TOKEN}"

terraform init
terraform apply -auto-approve