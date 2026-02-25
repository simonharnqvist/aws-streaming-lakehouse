

# === PyArrow Layer ===
echo "=== Building PyArrow layer ==="
rm -rf layer_pyarrow/python
mkdir -p layer_pyarrow/python
docker run --rm \
  --entrypoint "" \
  -v "$PWD/layer_pyarrow:/opt" \
  public.ecr.aws/lambda/python:3.12 \
  bash -c "pip install pyarrow -t /opt/python"

cd layer_pyarrow && zip -r layer_pyarrow.zip . && cd ..

# === Other Dependencies Layer ===
echo "=== Building deps layer ==="
rm -rf layer_deps/python
mkdir -p layer_deps/python
cat requirements.txt | grep -v pyarrow > requirements_no_pyarrow.txt
docker run --rm \
  --entrypoint "" \
  -v "$PWD/layer_deps:/opt" \
  -v "$PWD/requirements_no_pyarrow.txt:/requirements.txt" \
  public.ecr.aws/lambda/python:3.12 \
  bash -c "pip install -r /requirements.txt -t /opt/python"

cd layer_deps && zip -r layer_deps.zip . && cd ..

# === Validate ===
echo "PyArrow layer size: $(du -sh layer_pyarrow.zip | cut -f1)"
echo "Deps layer size:    $(du -sh layer_deps.zip | cut -f1)"

echo "=== Building fetcher ==="
rm -f fetcher/fetcher.zip
zip -j fetcher/fetcher.zip fetcher/fetcher.py
echo "Done"

echo "=== Building consumer ==="
rm -f consumer/consumer.zip
zip -j consumer/consumer.zip consumer/consumer.py
echo "Done"

echo "=== Building transformer ==="
rm -f transformer/transformer.zip
zip -j transformer/transformer.zip transformer/transformer.py
echo "Done"

echo "=== Validating layers ==="

###############################################
# Validate layer_deps.zip
###############################################

# Layer ZIP exists
if [ ! -f layer_deps/layer_deps.zip ]; then
  echo "❌ ❌ ❌ ERROR: layer_deps.zip not found ❌ ❌ ❌"
  exit 1
else
  echo "✅ layer_deps.zip found"
fi

# Layer ZIP contains python/ directory
if ! unzip -l layer_deps/layer_deps.zip | grep -q "python/"; then
  echo "❌ ❌ ❌ ERROR: layer_deps.zip does not contain python/ directory ❌ ❌ ❌"
  exit 1
else
  echo "✅ layer_deps.zip contains python/"
fi

# Layer ZIP contains compiled lxml (critical for Lambda)
if ! unzip -l layer_deps/layer_deps.zip | grep -q "lxml/etree"; then
  echo "❌ ❌ ❌ ERROR: lxml not found in layer_deps.zip (etree missing) ❌ ❌ ❌"
  exit 1
else
  echo "✅ lxml found in layer_deps.zip"
fi


###############################################
# Validate layer_pyarrow.zip
###############################################

# Layer ZIP exists
if [ ! -f layer_pyarrow/layer_pyarrow.zip ]; then
  echo "❌ ❌ ❌ ERROR: layer_pyarrow.zip not found ❌ ❌ ❌"
  exit 1
else
  echo "✅ layer_pyarrow.zip found"
fi

# Layer ZIP contains python/ directory
if ! unzip -l layer_pyarrow/layer_pyarrow.zip | grep -q "python/"; then
  echo "❌ ❌ ❌ ERROR: layer_pyarrow.zip does not contain python/ directory ❌ ❌ ❌"
  exit 1
else
  echo "✅ layer_pyarrow/layer_pyarrow.zip contains python/"
fi

# Layer ZIP contains PyArrow libs
if ! unzip -l layer_pyarrow/layer_pyarrow.zip | grep -q "pyarrow"; then
  echo "❌ ❌ ❌ ERROR: PyArrow missing from layer_pyarrow.zip ❌ ❌ ❌"
  exit 1
else
  echo "✅ PyArrow found in layer_pyarrow.zip"
fi




echo "=== Validating built Lambda functions ==="
# Fetcher ZIP contains fetcher.py
if ! unzip -l fetcher/fetcher.zip | grep -q "fetcher.py"; then
  echo "❌ ❌ ❌ ERROR: fetcher.zip does not contain fetcher.py ❌ ❌ ❌"
  exit 1
else
    echo "✅ fetcher.zip contains fetcher.py"
fi

# Consumer ZIP contains consumer.py
if ! unzip -l consumer/consumer.zip | grep -q "consumer.py"; then
  echo "❌ ❌ ❌ ERROR: consumer.zip does not contain consumer.py ❌ ❌ ❌"
  exit 1
else
    echo "✅ consumer.zip contains consumer.py"
fi

# Transformer ZIP contains transformer.py
if ! unzip -l transformer/transformer.zip | grep -q "transformer.py"; then
  echo "❌ ❌ ❌ ERROR: transformer.zip does not contain transformer.py ❌ ❌ ❌"
  exit 1
else
    echo "✅ transformer.zip contains transformer.py"
fi

echo "=== ✅ ✅ ✅ Build validation passed ✅ ✅ ✅  ==="
