#!/bin/bash

PROJECT_ID=$(gcloud config get-value project)
DATASET_NAME="mcp_evstation"
LOCATION="US"

# Generate bucket name if not provided
if [ -z "$1" ]; then
    BUCKET_NAME="gs://mcp-evstation-data-$PROJECT_ID"
    echo "No bucket provided. Using default: $BUCKET_NAME"
else
    BUCKET_NAME=$1
fi

echo "----------------------------------------------------------------"
echo "MCP evstation Demo Setup"
echo "Project: $PROJECT_ID"
echo "Dataset: $DATASET_NAME"
echo "Bucket:  $BUCKET_NAME"
echo "----------------------------------------------------------------"

# 1. Create Bucket if it doesn't exist
echo "[1/9] Checking bucket $BUCKET_NAME..."
if gcloud storage buckets describe $BUCKET_NAME >/dev/null 2>&1; then
    echo "      Bucket already exists."
else
    echo "      Creating bucket $BUCKET_NAME..."
    gcloud storage buckets create $BUCKET_NAME --location=$LOCATION
fi

# 2. Upload Data
echo "[2/9] Uploading data to $BUCKET_NAME..."
gcloud storage cp data/*.csv $BUCKET_NAME

# 3. Create Dataset
echo "[3/9] Creating Dataset '$DATASET_NAME'..."
if bq show "$PROJECT_ID:$DATASET_NAME" >/dev/null 2>&1; then
    echo "      Dataset already exists. Skipping creation."
else    
    bq mk --location=$LOCATION --dataset \
        --description "$DATASET_DESCRIPTION" \
        "$PROJECT_ID:$DATASET_NAME"
    echo "      Dataset created."
fi

# 4. Create Demographics Table
echo "[4/9] Setting up Table: demographics..."
bq query --use_legacy_sql=false \
"CREATE OR REPLACE TABLE \`$PROJECT_ID.$DATASET_NAME.demographics\` (
    zip_code STRING OPTIONS(description='5-digit US Zip Code'),
    city STRING OPTIONS(description='City name, e.g., Los Angeles'),
    neighborhood STRING OPTIONS(description='Common neighborhood name, e.g., Santa Monica, Silver Lake'),
    total_population INT64 OPTIONS(description='Total population count in the zip code'),
    median_age FLOAT64 OPTIONS(description='Median age of residents'),
    bachelors_degree_pct FLOAT64 OPTIONS(description='Percentage of population 25+ with a Bachelors degree or higher'),
    evstation_traffic_index FLOAT64 OPTIONS(description='Index of estimated ev traffic based on commercial density and mobility data')
)
OPTIONS(
    description='Census data by zip code for various California cities.'
);"

bq load --source_format=CSV --skip_leading_rows=1 --ignore_unknown_values=true --replace \
    "$PROJECT_ID:$DATASET_NAME.demographics" "$BUCKET_NAME/demographics.csv"

# 5. Create evstation Prices Table
echo "[5/9] Setting up Table: evstation_prices..."
bq query --use_legacy_sql=false \
"CREATE OR REPLACE TABLE \`$PROJECT_ID.$DATASET_NAME.evstation_prices\` (
    station_name STRING OPTIONS(description='Name of the competitor evstation'),
    ev_type STRING OPTIONS(description='Type of ev vehicle, e.g., Tesla, Toyota, Ford'),
    price FLOAT64 OPTIONS(description='Price per unit in USD'),
    region STRING OPTIONS(description='Geographic region, e.g., Los Angeles Metro, SF Bay Area'),
    is_phev BOOL OPTIONS(description='Whether the product is certified Plug-in hybrid electric vehicles - PHEVs')
)
OPTIONS(
    description='Competitor pricing and details for common ev vehicles.'
);"

bq load --source_format=CSV --skip_leading_rows=1 --replace \
    "$PROJECT_ID:$DATASET_NAME.evstation_prices" "$BUCKET_NAME/evstation_prices.csv"

# 6. Create Sales History Table
echo "[6/9] Setting up Table: sales_history_weekly..."
bq query --use_legacy_sql=false \
"CREATE OR REPLACE TABLE \`$PROJECT_ID.$DATASET_NAME.sales_history_weekly\` (
    week_start_date DATE OPTIONS(description='The start date of the sales week (Monday)'),
    station_location STRING OPTIONS(description='Location of the evstation branch'),
    ev_type STRING OPTIONS(description='EV type: Testla, Toyota, Ford, etc.'),
    quantity_sold INT64 OPTIONS(description='Total units sold this week'),
    total_revenue FLOAT64 OPTIONS(description='Total revenue in USD for this week')
)
OPTIONS(
    description='Weekly sales performance history by station and product.'
);"

bq load --source_format=CSV --skip_leading_rows=1 --replace \
    "$PROJECT_ID:$DATASET_NAME.sales_history_weekly" "$BUCKET_NAME/sales_history_weekly.csv"

# 7. Create EVStation Traffic Table
echo "[7/9] Setting up Table: evstation_traffic..."
bq query --use_legacy_sql=false \
"CREATE OR REPLACE TABLE \`$PROJECT_ID.$DATASET_NAME.evstation_traffic\` (
    zip_code STRING OPTIONS(description='5-digit US Zip Code'),
    time_of_day STRING OPTIONS(description='Time of day: morning, afternoon, evening'),
    evstation_traffic_score FLOAT64 OPTIONS(description='Score of evstation traffic (1-100)')
)
OPTIONS(
    description='evstation traffic scores by zip code and time of day.'
);"

bq load --source_format=CSV --skip_leading_rows=1 --replace \
    "$PROJECT_ID:$DATASET_NAME.evstation_traffic" "$BUCKET_NAME/evstation_traffic.csv"

# 8. Create Vehicle Registrations Table
echo "[8/9] Setting up Table: vehicle_registrations..."
bq query --use_legacy_sql=false \
"CREATE OR REPLACE TABLE \`$PROJECT_ID.$DATASET_NAME.vehicle_registrations\` (
    zip_code STRING OPTIONS(description='5-digit US Zip Code'),
    ev_type STRING OPTIONS(description='Tesla, Toyota, FORD, etc.'),
    registration_year STRING OPTIONS(description='Year: 2020, 2025, 2024, 2023'),
    registration_count INT64 OPTIONS(description='count of ev registration by zip code')
)
OPTIONS(
    description='vehicle registrations by type, year and count.'
);"

bq load --source_format=CSV --skip_leading_rows=1 --replace \
    "$PROJECT_ID:$DATASET_NAME.vehicle_registrations" "$BUCKET_NAME/vehicle_registrations.csv"

# 9. Create Grid Capacity Table
echo "[9/9] Setting up Table: grid_capacity..."
bq query --use_legacy_sql=false \
"CREATE OR REPLACE TABLE \`$PROJECT_ID.$DATASET_NAME.grid_capacity\` (
    zip_code STRING OPTIONS(description='5-digit US Zip Code'),
    average_load_mw FLOAT64 OPTIONS(description='Average Load: 20.2, 24.5'),
    excess_capacity_mw FLOAT64 OPTIONS(description='Excess Capacity: 45.8, 65.5')
)
OPTIONS(
    description='grid capacity by zip code0, load and capacity.'
);"

bq load --source_format=CSV --skip_leading_rows=1 --replace \
    "$PROJECT_ID:$DATASET_NAME.grid_capacity" "$BUCKET_NAME/grid_capacity.csv"

echo "----------------------------------------------------------------"
echo "Setup Complete!"
echo "----------------------------------------------------------------"