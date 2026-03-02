SHELL := /bin/bash

PYTHON_IMAGE := public.ecr.aws/lambda/python:3.12

.PHONY: build

build: all

all: layers functions validate

# ============================
# Layers
# ============================

layers: layer_pyarrow/layer_pyarrow.zip layer_deps/layer_deps.zip

layer_pyarrow/layer_pyarrow.zip:
		@echo "=== Building PyArrow layer ==="
		rm -rf layer_pyarrow/python
		mkdir -p layer_pyarrow/python
		docker run --rm \
			--entrypoint "" \
			-v "$(PWD)/layer_pyarrow:/opt" \
			$(PYTHON_IMAGE) \
			bash -c "pip install pyarrow -t /opt/python"
		cd layer_pyarrow && zip -r layer_pyarrow.zip . && cd ..

layer_deps/layer_deps.zip:
		@echo "=== Building deps layer ==="
		rm -rf layer_deps/python
		mkdir -p layer_deps/python
		cat requirements.txt | grep -v pyarrow > requirements_no_pyarrow.txt
		docker run --rm \
			--entrypoint "" \
			-v "$(PWD)/layer_deps:/opt" \
			-v "$(PWD)/requirements_no_pyarrow.txt:/requirements.txt" \
			$(PYTHON_IMAGE) \
			bash -c "pip install -r /requirements.txt -t /opt/python"
		cd layer_deps && zip -r layer_deps.zip . && cd ..

# ============================
# Lambda functions
# ============================

functions: fetcher/fetcher.zip consumer/consumer.zip transformer/transformer.zip

fetcher/fetcher.zip: fetcher/fetcher.py
		@echo "=== Building fetcher ==="
		rm -f fetcher/fetcher.zip
		zip -j fetcher/fetcher.zip fetcher/fetcher.py

consumer/consumer.zip: consumer/consumer.py
		@echo "=== Building consumer ==="
		rm -f consumer/consumer.zip
		zip -j consumer/consumer.zip consumer/consumer.py

transformer/transformer.zip: transformer/transformer.py
		@echo "=== Building transformer ==="
		rm -f transformer/transformer.zip
		zip -j transformer/transformer.zip transformer/transformer.py

# ============================
# Validation
# ============================

validate: validate_layers validate_functions
		@echo "=== ✅ Build validation passed ==="

validate_layers:
		@echo "=== Validating layers ==="

		@if [ ! -f layer_deps/layer_deps.zip ]; then \
			echo "❌ ERROR: layer_deps.zip not found"; exit 1; \
		else echo "✅ layer_deps.zip found"; fi

		@if ! unzip -l layer_deps/layer_deps.zip | grep -q "python/"; then \
			echo "❌ ERROR: layer_deps.zip missing python/"; exit 1; \
		else echo "✅ python/ found in layer_deps.zip"; fi

		@if ! unzip -l layer_deps/layer_deps.zip | grep -q "lxml/etree"; then \
			echo "❌ ERROR: lxml missing in layer_deps.zip"; exit 1; \
		else echo "✅ lxml found"; fi

		@if [ ! -f layer_pyarrow/layer_pyarrow.zip ]; then \
			echo "❌ ERROR: layer_pyarrow.zip not found"; exit 1; \
		else echo "✅ layer_pyarrow.zip found"; fi

		@if ! unzip -l layer_pyarrow/layer_pyarrow.zip | grep -q "python/"; then \
			echo "❌ ERROR: layer_pyarrow.zip missing python/"; exit 1; \
		else echo "✅ python/ found in layer_pyarrow.zip"; fi

		@if ! unzip -l layer_pyarrow/layer_pyarrow.zip | grep -q "pyarrow"; then \
			echo "❌ ERROR: pyarrow missing in layer_pyarrow.zip"; exit 1; \
		else echo "✅ pyarrow found"; fi

validate_functions:
		@echo "=== Validating Lambda functions ==="

		@if ! unzip -l fetcher/fetcher.zip | grep -q "fetcher.py"; then \
			echo "❌ ERROR: fetcher.zip missing fetcher.py"; exit 1; \
		else echo "✅ fetcher.zip contains fetcher.py"; fi

		@if ! unzip -l consumer/consumer.zip | grep -q "consumer.py"; then \
			echo "❌ ERROR: consumer.zip missing consumer.py"; exit 1; \
		else echo "✅ consumer.zip contains consumer.py"; fi

		@if ! unzip -l transformer/transformer.zip | grep -q "transformer.py"; then \
			echo "❌ ERROR: transformer.zip missing transformer.py"; exit 1; \
		else echo "✅ transformer.zip contains transformer.py"; fi