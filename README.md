# 🚆 Train Delays Streaming Pipeline (AWS + Terraform)

A fully serverless, event‑driven data pipeline that streams live departure board data from Edinburgh Waverley (or any UK station) into an AWS‑based lakehouse.  
Built to practise real‑time ingestion, micro‑batching, and infrastructure‑as‑code — and to demonstrate clean engineering patterns across Lambda, Kinesis, S3, Glue, and Athena.

The result is a continuously updated dataset of train movements and delays, queryable in seconds via Athena.

---

## 🏗️ Architecture Overview

This project implements a compact but production‑shaped streaming system:

### **Ingestion**
- **Lambda (fetcher)** polls the National Rail LDBWS API for live departures.
- **Kinesis Data Streams** buffers events and decouples ingestion from processing.

### **Processing**
- **Lambda (consumer)** reads from Kinesis and writes raw JSON to S3.
- **Lambda (transformer)** converts raw events into partitioned Parquet (`date=` / `station=`) for efficient analytics.

### **Storage & Lakehouse**
- **S3** stores raw and cleaned datasets.
- **Glue Catalog** defines schema and partitions.
- **Glue job** performs hourly compaction to avoid the small‑files problem.
- **Lambda (update_partitions)** registers new partitions automatically.

### **Querying**
- **Athena** provides SQL access to the lakehouse with sub‑second metadata refresh.

### **Infrastructure**
- **Terraform** provisions all AWS resources.
- **Make** orchestrates builds, validation, and deployment.

The whole system is lightweight, reproducible, and easy to extend.

---

## 🚀 Getting Started

### 1. Configure environment variables

Create a `.env` file with your National Rail token (free to obtain):

```env
LDBWS_TOKEN=abc123
```

And remaining variables:
```env
STATION_CRS=EDB
CLEAN_BUCKET=my-clean-train-delays-data
GLUE_SCRIPTS_BUCKET=my-train-delays-glue-scripts
REGION=eu-west-2
GLUE_DATABASE=train_delays_catalog
GLUE_TABLE=train_delays
```

### 2. Build Lambda functions and layers
```bash
make build
```

The build system validates all artifacts and fails fast with clear, human‑readable errors if anything is missing.


### 3. Deploy the full stack
```bash
make deploy
```

Terraform provisions the entire pipeline: Kinesis, Lambdas, S3 buckets, Glue Catalog, Athena workgroup, IAM roles, and triggers.

### 4. Tear everything down
```bash
make destroy
```

All AWS resources are removed cleanly.

## 📊 Querying the Data

Once deployed, you can query live and historical train data in Athena, for example:
```sql
SELECT *
FROM train_delays
WHERE date = '2025-03-10'
ORDER BY delay DESC
LIMIT 20;
```

Partition updates are handled automatically by the `update_partitions` Lambda, triggered by an S3 event each time a new date partition is created.
