## 1. Workspace & Infrastructure Setup

- [x] 1.1 Create `RDWAgents` workspace on trial capacity via `fab api -X post "workspaces"` with capacity ID `638b8321-729d-4c91-b267-33f2dfd12775`
- [x] 1.2 Create schema-enabled lakehouse `RDWAgentsLake` in `RDWAgents` workspace via `fab api`
- [x] 1.3 Create `bronze`, `silver`, and `gold` schemas in `RDWAgentsLake`
- [x] 1.4 Create OneLake shortcuts in `bronze` schema for all 5 source tables pointing to `RDW - Open Data/RDWLake/Tables/dbo/*`
- [x] 1.5 Verify shortcuts work by querying `bronze.gekentekende_voertuigen` via Spark or SQL endpoint

## 2. Bronze-to-Silver Notebook

- [x] 2.1 Create PySpark notebook `01_bronze_to_silver` in `RDWAgents` workspace
- [x] 2.2 Implement `silver.vehicles` transformation: column renaming to snake_case, date parsing (integer/string→date), numeric casting (string→int/double), special character cleanup in column names, deduplication by kenteken
- [x] 2.3 Implement `silver.vehicle_fuels` transformation: column renaming, numeric casting, deduplication by kenteken + brandstof_volgnummer
- [x] 2.4 Implement `silver.fuels_by_postal_code` transformation: column renaming, `extern_oplaadbaar` to boolean
- [x] 2.5 Implement `silver.parking_addresses` transformation: column renaming, type validation
- [x] 2.6 Implement `silver.parking_area_specs` transformation: column renaming, epoch milliseconds to date conversion for start/end dates
- [x] 2.7 Write all Silver tables using `mode("overwrite").saveAsTable("silver.<name>")`
- [x] 2.8 Execute notebook and verify all 5 Silver tables are created with correct schemas

## 3. Silver-to-Gold Notebook

- [x] 3.1 Create PySpark notebook `02_silver_to_gold` in `RDWAgents` workspace
- [x] 3.2 Implement `gold.dim_vehicle`: select distinct vehicle attributes from `silver.vehicles`, add surrogate `vehicle_key` using `monotonically_increasing_id()`
- [x] 3.3 Implement `gold.dim_fuel_type`: select distinct fuel type attributes from `silver.vehicle_fuels`, add surrogate `fuel_type_key`
- [x] 3.4 Implement `gold.dim_location`: union postal codes from `silver.fuels_by_postal_code` and `silver.parking_addresses`, deduplicate, add surrogate `location_key`
- [x] 3.5 Implement `gold.dim_parking_area`: select distinct parking area attributes from `silver.parking_area_specs`, add surrogate `parking_area_key`
- [x] 3.6 Implement `gold.dim_date`: generate date range from min to max dates across all Silver date columns, compute year/quarter/month/week/day/weekend attributes
- [x] 3.7 Implement `gold.fact_vehicle_registration`: join `silver.vehicles` to dimension keys, select measure columns
- [x] 3.8 Implement `gold.fact_vehicle_emissions`: join `silver.vehicle_fuels` to `dim_vehicle` and `dim_fuel_type` keys, select emission/consumption measures
- [x] 3.9 Implement `gold.fact_fuel_distribution`: join `silver.fuels_by_postal_code` to `dim_location`, select count measure
- [x] 3.10 Implement `gold.fact_parking_capacity`: join `silver.parking_area_specs` + `silver.parking_addresses` to dimension keys, select capacity measures
- [x] 3.11 Write all Gold tables using `mode("overwrite").saveAsTable("gold.<name>")`
- [x] 3.12 Execute notebook and verify all 10 Gold tables are created (5 dimensions + 4 facts + dim_date)

## 4. Semantic Model

- [x] 4.1 Create Power BI semantic model `RDW Analytics` in `RDWAgents` workspace using Direct Lake mode
- [x] 4.2 Add all Gold tables to the model
- [x] 4.3 Configure star schema relationships: fact-to-dimension many-to-one relationships including role-playing date relationships
- [x] 4.4 Create DAX measures for outlier detection: `CO2 Z-Score`, `Fuel Consumption Z-Score`, `Outlier Count (>2σ)`, `Outlier Count (>3σ)`
- [x] 4.5 Create DAX percentile measures: `P25`, `P50 (Median)`, `P75`, `P95`, `P99`
- [x] 4.6 Create DAX count measures: `Total Vehicles`, `Vehicles by Fuel Type`, `Vehicles by Brand`, `Total Vehicle Count`, `EV Share %`, `Externally Chargeable %`
- [x] 4.7 Create DAX parking measures: `Total Parking Capacity`, `EV Charging Coverage %`, `Accessible Parking %`

## 5. Reports

- [x] 5.1 Create Power BI report `RDW Dashboard` connected to `RDW Analytics` semantic model
- [x] 5.2 Build Fleet Composition page: top-20 brands bar chart, vehicle category treemap, total vehicle count card, slicers for vehicle type/fuel/color
- [x] 5.3 Build Emissions Outliers page: CO2 vs displacement scatter plot with outlier highlighting, top-50 outliers table, metric histogram with percentile markers, KPI cards (mean, median, stdev, outlier count)
- [x] 5.4 Build Geographic Distribution page: postal code heatmap/matrix, fuel type slicers, EV adoption KPI cards
- [x] 5.5 Build Parking Infrastructure page: capacity/charging/accessibility KPI cards, capacity by province bar chart, EV charging coverage comparison
- [x] 5.6 Build Trends page: registration trends line chart by year/month, APK expiry bar chart, slicers for brand/fuel/category
- [x] 5.7 Publish report to `RDWAgents` workspace

## 6. Validation & Documentation

- [x] 6.1 Validate end-to-end data flow: Bronze shortcut → Silver tables → Gold dimensions/facts → semantic model → report visuals
- [x] 6.2 Spot-check row counts across layers to ensure no unexpected data loss
- [x] 6.3 Verify outlier detection measures produce reasonable results on sample data
- [x] 6.4 Document the solution architecture in workspace README or notebook markdown cells
