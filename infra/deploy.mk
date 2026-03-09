.PHONY: deploy build

ifneq (,$(wildcard .env))
include .env
endif

export TF_VAR_ldbws_token  = $(LDBWS_TOKEN)
export TF_VAR_station_crs  = $(STATION_CRS)
export TF_VAR_clean_bucket = $(CLEAN_BUCKET)
export TF_VAR_glue_scripts_bucket = $(GLUE_SCRIPTS_BUCKET)

deploy: build
	terraform -chdir=infra init
	terraform -chdir=infra apply -auto-approve

build:
	$(MAKE) -f infra/build.mk build
