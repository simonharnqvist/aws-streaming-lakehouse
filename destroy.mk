.PHONY: destroy clean_up

# Load .env if present
ifneq (,$(wildcard .env))
include .env
endif

# Export Terraform variables
export TF_VAR_ldbws_token  = $(LDBWS_TOKEN)
export TF_VAR_clean_bucket = $(CLEAN_BUCKET)
export TF_VAR_station_crs  = $(STATION_CRS)

destroy:
	terraform init
	terraform destroy -auto-approve
	$(MAKE) -f destroy.mk clean_up