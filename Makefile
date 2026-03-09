.PHONY: build deploy destroy

build:
	$(MAKE) -f infra/build.mk build

deploy:
	$(MAKE) -f infra/deploy.mk deploy

destroy: 
	$(MAKE) -f infra/destroy.mk destroy