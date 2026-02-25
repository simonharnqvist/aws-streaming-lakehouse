source .env 
export TF_VAR_ldbws_token="${LDBWS_TOKEN}"
export TF_VAR_clean_bucket="${CLEAN_BUCKET}"
export TF_VAR_station_crs="${STATION_CRS}"

terraform init
terraform destroy -auto-approve