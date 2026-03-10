.PHONY: deploy build

ifneq (,$(wildcard .env))
include .env
endif

include infra/variables.mk

deploy: build
	terraform -chdir=infra init
	terraform -chdir=infra apply -auto-approve

build:
	$(MAKE) -f infra/build.mk build
