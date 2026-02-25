echo "=== Building dependencies layer ==="
rm -rf layer/python
mkdir -p layer/python
docker run --rm \
  -v "$PWD/layer:/layer" \
  public.ecr.aws/lambda/python:3.12 \
  pip install \
    --platform linux/x86_64 \
    --implementation cp \
    --python-version 3.12 \
    --only-binary=:all: \
    -r /layer/requirements.txt \
    -t /layer/python

rm -f layer/layer.zip
cd layer && zip -r layer.zip python && cd ..
echo "Done"

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


echo "=== Validating build artifacts ==="

# Layer ZIP exists
if [ ! -f layer/layer.zip ]; then
  echo "❌ ❌ ❌ ERROR: layer.zip not found ❌ ❌ ❌"
  exit 1
else
    echo "✅ layer.zip found"
fi

# Layer ZIP contains python/ directory
if ! unzip -l layer/layer.zip | grep -q "python/"; then
  echo "❌ ❌ ❌ ERROR: layer.zip does not contain python/ directory ❌ ❌ ❌"
  exit 1
else
    echo "✅ layer.zip contains python/"
fi

# Layer ZIP contains compiled lxml (critical for Lambda)
if ! unzip -l layer/layer.zip | grep -q "lxml/etree"; then
  echo "❌ ❌ ❌ ERROR: lxml not found in layer.zip (etree missing) ❌ ❌ ❌"
  exit 1
else
    echo "✅ lxml found in layer.zip"
fi

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
