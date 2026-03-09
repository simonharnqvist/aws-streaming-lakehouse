SHELL := /bin/bash

PYTHON_IMAGE := public.ecr.aws/lambda/python:3.12

# ============================
# Paths
# ============================
PYARROW_LAYER_DIR := layers/layer_pyarrow
PYTHON_LAYER_DIR := layers/layer_python
LAMBDAS_DIR := src/lambdas

$(info LAMBDAS_DIR = $(LAMBDAS_DIR))


.PHONY: build

build: all

all: layers functions validate


# ============================
# Layers
# ============================

layers: pyarrow_layer python_layer

pyarrow_layer:
	@echo "=== Building PyArrow layer ==="
	rm -rf $(PYARROW_LAYER_DIR)/python
	mkdir -p $(PYARROW_LAYER_DIR)/python
	docker run --rm \
		--user $(shell id -u):$(shell id -g) \
		--entrypoint "" \
		-v "$(PWD)/$(PYARROW_LAYER_DIR):/opt" \
		$(PYTHON_IMAGE) \
		bash -c "pip install pyarrow -t /opt/python"
	cd $(PYARROW_LAYER_DIR) && rm -f layer_pyarrow.zip && zip -r layer_pyarrow.zip python && cd ..


python_layer:
	@echo "=== Building deps layer ==="
	rm -rf $(PYTHON_LAYER_DIR)/python
	mkdir -p $(PYTHON_LAYER_DIR)/python
	cat requirements.txt | grep -v pyarrow > requirements_no_pyarrow.txt
	docker run --rm \
		--user $(shell id -u):$(shell id -g) \
		--entrypoint "" \
		-v "$(PWD)/$(PYTHON_LAYER_DIR):/opt" \
		-v "$(PWD)/requirements_no_pyarrow.txt:/requirements.txt" \
		$(PYTHON_IMAGE) \
		bash -c "pip install -r /requirements.txt -t /opt/python"
	cd $(PYTHON_LAYER_DIR) && rm -f layer_python.zip && zip -r layer_python.zip python && cd ..


# ============================
# Lambda functions
# ============================

functions: fetcher consumer transformer

fetcher: $(LAMBDAS_DIR)/fetcher/fetcher.py
	@echo "=== Building fetcher ==="
	rm -f $(LAMBDAS_DIR)/fetcher/fetcher.zip
	zip -j $(LAMBDAS_DIR)/fetcher/fetcher.zip $<

consumer: $(LAMBDAS_DIR)/consumer/consumer.py
	@echo "=== Building consumer ==="
	rm -f $(LAMBDAS_DIR)/consumer/consumer.zip
	zip -j $(LAMBDAS_DIR)/consumer/consumer.zip $<

transformer: $(LAMBDAS_DIR)/transformer/transformer.py
	@echo "=== Building transformer ==="
	rm -f $(LAMBDAS_DIR)/transformer/transformer.zip
	zip -j $(LAMBDAS_DIR)/transformer/transformer.zip $<



# ==========================
# Validation
# ==========================


validate: validate_layers validate_functions
	@echo "=== ✅ Build validation passed ==="


validate_layers:
	@echo "=== Validating layers ==="

	# --- deps layer ---
	@if [ ! -f $(PYTHON_LAYER_DIR)/layer_python.zip ]; then \
		echo "❌ ERROR: layer_python.zip not found in $(PYTHON_LAYER_DIR)"; exit 1; \
	else echo "✅ layer_python.zip found"; fi

	@if ! unzip -l $(PYTHON_LAYER_DIR)/layer_python.zip | grep -q "python/"; then \
		echo "❌ ERROR: layer_python.zip missing top-level python/"; exit 1; \
	else echo "✅ python/ found in layer_python.zip"; fi

	@if ! unzip -l $(PYTHON_LAYER_DIR)/layer_python.zip | grep -q "lxml/etree"; then \
		echo "❌ ERROR: lxml missing in layer_python.zip"; exit 1; \
	else echo "✅ lxml found"; fi


	# --- pyarrow layer ---
	@if [ ! -f $(PYARROW_LAYER_DIR)/layer_pyarrow.zip ]; then \
		echo "❌ ERROR: layer_pyarrow.zip not found in $(PYARROW_LAYER_DIR)"; exit 1; \
	else echo "✅ layer_pyarrow.zip found"; fi

	@if ! unzip -l $(PYARROW_LAYER_DIR)/layer_pyarrow.zip | grep -q "python/"; then \
		echo "❌ ERROR: layer_pyarrow.zip missing top-level python/"; exit 1; \
	else echo "✅ python/ found in layer_pyarrow.zip"; fi

	@if ! unzip -l $(PYARROW_LAYER_DIR)/layer_pyarrow.zip | grep -q "pyarrow"; then \
		echo "❌ ERROR: pyarrow missing in layer_pyarrow.zip"; exit 1; \
	else echo "✅ pyarrow found"; fi



validate_functions:
	@echo "=== Validating Lambda functions ==="

	@if ! unzip -l $(LAMBDAS_DIR)/fetcher/fetcher.zip | grep -q "fetcher.py"; then \
		echo "❌ ERROR: fetcher.zip missing fetcher.py"; exit 1; \
	else echo "✅ fetcher.zip contains fetcher.py"; fi

	@if ! unzip -l $(LAMBDAS_DIR)/consumer/consumer.zip | grep -q "consumer.py"; then \
		echo "❌ ERROR: consumer.zip missing consumer.py"; exit 1; \
	else echo "✅ consumer.zip contains consumer.py"; fi

	@if ! unzip -l $(LAMBDAS_DIR)/transformer/transformer.zip | grep -q "transformer.py"; then \
		echo "❌ ERROR: transformer.zip missing transformer.py"; exit 1; \
	else echo "✅ transformer.zip contains transformer.py"; fi
