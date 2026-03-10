.PHONY: destroy clean_up

# Load .env if present
ifneq (,$(wildcard .env))
include .env
endif

include infra/variables.mk

destroy:
	terraform -chdir=infra init
	terraform -chdir=infra destroy -auto-approve
	$(MAKE) -f destroy.mk clean_up