## Why

The RDW (Rijksdienst voor het Wegverkeer) Open Data workspace contains raw ingested data from the Dutch Vehicle Authority in a single lakehouse (`RDWLake`) with 5 tables in the `dbo` schema. This data covers vehicle registrations, fuel types, emissions, and parking facilities across the Netherlands. Currently, the data sits as flat, denormalized tables with no analytical structure — making it difficult to detect outliers, compute aggregated counts, or build meaningful reports. A dedicated `RDWAgents` workspace with a medallion architecture (Bronze → Silver → Gold) in the same lakehouse using separate schemas will transform this raw data into an optimized dimensional model ready for analysis and reporting.

## What Changes

- **New workspace**: Create `RDWAgents` workspace on trial capacity
- **Shortcut**: Create a OneLake shortcut in `RDWAgents` pointing to the `RDWLake` tables in `RDW - Open Data` workspace (Bronze layer)
- **Silver schema**: Create `silver` schema in the lakehouse with cleansed, typed, and deduplicated tables:
  - `silver.vehicles` — cleaned `gekentekende_voertuigen` with proper date parsing, numeric casting, and null handling
  - `silver.vehicle_fuels` — cleaned `gekentekende_voertuigen_brandstof` with normalized fuel metrics
  - `silver.fuels_by_postal_code` — cleaned `brandstoffen_op_pc4`
  - `silver.parking_addresses` — cleaned `parkeeradres`
  - `silver.parking_area_specs` — cleaned `specificaties_parkeergebied` with epoch-to-date conversion
- **Gold schema**: Create `gold` schema with a dimensional star model optimized for outlier detection and count-based analysis:
  - `gold.dim_vehicle` — Vehicle dimension (Kenteken as business key, brand, model, type, color, category, mass, dimensions)
  - `gold.dim_fuel_type` — Fuel type dimension (fuel description, emission class, hybrid classification)
  - `gold.dim_location` — Location dimension (postal code, street, city, province, country)
  - `gold.dim_parking_area` — Parking area dimension (area ID, capacity, disabled access, height limits)
  - `gold.dim_date` — Date dimension (generated, covering all date fields: first registration, APK expiry, registration date)
  - `gold.fact_vehicle_registration` — Fact table: one row per vehicle registration event with keys to all dimensions, measures for mass, cylinder count/volume, speed, seat count, door count, BPM, catalog price
  - `gold.fact_vehicle_emissions` — Fact table: one row per vehicle-fuel combination with CO2 emissions, fuel consumption (city/highway/combined), WLTP metrics, particulate emissions, electric range
  - `gold.fact_fuel_distribution` — Fact table: vehicle counts by postal code, vehicle type, fuel type, and electric charging capability
  - `gold.fact_parking_capacity` — Fact table: parking area capacity over time with charging points and accessibility metrics
- **Notebooks**: Create Spark notebooks for Bronze→Silver and Silver→Gold transformations
- **Semantic model**: Create a Power BI semantic model on the Gold layer
- **Reports**: Create Power BI reports with dashboards for:
  - Vehicle fleet composition analysis (counts by brand, fuel type, vehicle category, color)
  - Emissions outlier detection (CO2, particulates, fuel consumption vs fleet averages)
  - Geographic distribution (fuel type adoption by postal code region)
  - Parking infrastructure analysis (capacity, EV charging coverage, accessibility)
  - Trend analysis (registration dates, APK expiry patterns)

## Capabilities

### New Capabilities

- `workspace-setup`: Provision RDWAgents workspace on trial capacity and create OneLake shortcut to source data
- `bronze-to-silver`: Spark notebook transforming raw Bronze tables into cleansed Silver schema with proper typing, deduplication, and null handling
- `silver-to-gold`: Spark notebook building dimensional star model in Gold schema from Silver tables, optimized for outlier analysis and aggregated counts
- `semantic-model`: Power BI semantic model with relationships, measures (DAX) for outlier detection (z-scores, percentiles), and count aggregations
- `reports`: Power BI reports with visuals for fleet composition, emissions outliers, geographic distribution, parking capacity, and trend analysis

### Modified Capabilities

_(none — this is a greenfield project)_

## Impact

- **Workspaces**: New `RDWAgents` workspace created on trial capacity
- **OneLake**: Shortcut from `RDWAgents` lakehouse to `RDW - Open Data/RDWLake` Bronze tables (no data duplication for Bronze)
- **Lakehouse schemas**: New `silver` and `gold` schemas in the RDWAgents lakehouse
- **Compute**: Spark notebooks will run transformations; trial capacity limits apply
- **Dependencies**: Source data must remain available in `RDW - Open Data` workspace; shortcut requires cross-workspace read permissions
- **Semantic model**: Direct Lake mode on Gold schema tables for optimal query performance
- **Reports**: Published to `RDWAgents` workspace for consumption
