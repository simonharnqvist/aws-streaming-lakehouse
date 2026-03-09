import sys
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

args = getResolvedOptions(sys.argv, ["TARGET_DATE", "SILVER_PREFIX"])
date = args["TARGET_DATE"]
station = args["STATION"]
prefix = args["SILVER_PREFIX"]

sc = SparkContext
glueContext = GlueContext(sc)
spark = glueContext.spark_session

input_path = f"{prefix}/date={date}/station={station}"
df = spark.read_parquet(input_path)

df = df.repartition(8)

temp_path = f"{prefix}/date={date}/station={station}_tmp/"
df.write_mode("overwrite").parquet(temp_path)
