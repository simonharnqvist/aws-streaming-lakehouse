.PHONY: build deploy destroy

build:
	$(MAKE) -f build.mk build

deploy:
	$(MAKE) -f deploy.mk deploy

destroy: 
	$(MAKE) -f destroy.mk destroy