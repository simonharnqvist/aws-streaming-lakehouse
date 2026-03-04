.PHONY: deploy build

ifneq (,$(wildcard .env))
include .env
endif

export TF_VAR_ldbws_token  = $(LDBWS_TOKEN)
export TF_VAR_station_crs  = $(STATION_CRS)
export TF_VAR_clean_bucket = $(CLEAN_BUCKET)
export TF_VAR_scripts_bucket = $(SCRIPTS_BUCKET)

deploy: build
	terraform apply -auto-approve

build:
	$(MAKE) -f build.mk build
