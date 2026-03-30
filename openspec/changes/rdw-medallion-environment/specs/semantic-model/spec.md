## ADDED Requirements

### Requirement: Semantic model creation
A Power BI semantic model named `RDW Analytics` SHALL be created in the `RDWAgents` workspace using Direct Lake mode, connecting to all Gold schema tables in `RDWAgentsLake`.

#### Scenario: Direct Lake connectivity
- **WHEN** the semantic model is deployed
- **THEN** all Gold dimension and fact tables SHALL be available as tables in the model
- **THEN** the model SHALL use Direct Lake storage mode (no data import)

### Requirement: Star schema relationships
The semantic model SHALL define relationships between fact and dimension tables following star schema conventions.

#### Scenario: Fact-to-dimension relationships
- **WHEN** the model is configured
- **THEN** `fact_vehicle_registration` SHALL have many-to-one relationships to `dim_vehicle`, `dim_date` (3 role-playing relationships for different date columns)
- **THEN** `fact_vehicle_emissions` SHALL have many-to-one relationships to `dim_vehicle`, `dim_fuel_type`
- **THEN** `fact_fuel_distribution` SHALL have many-to-one relationship to `dim_location`
- **THEN** `fact_parking_capacity` SHALL have many-to-one relationships to `dim_parking_area`, `dim_location`, `dim_date` (2 role-playing relationships)

### Requirement: DAX measures for outlier detection
The semantic model SHALL contain DAX measures that enable outlier detection using statistical methods.

#### Scenario: Z-score measures for emissions
- **WHEN** a report consumer filters by vehicle category
- **THEN** measures `CO2 Z-Score`, `Fuel Consumption Z-Score` SHALL compute per-record z-scores as `(value - AVG) / STDEV` across the filtered context
- **THEN** measure `Outlier Count (>2σ)` SHALL count records where absolute z-score exceeds 2
- **THEN** measure `Outlier Count (>3σ)` SHALL count records where absolute z-score exceeds 3

#### Scenario: Percentile measures
- **WHEN** a report consumer views a distribution
- **THEN** measures `P25`, `P50 (Median)`, `P75`, `P95`, `P99` SHALL return the corresponding percentiles of the selected metric

### Requirement: DAX measures for counts and aggregations
The semantic model SHALL contain DAX measures for count-based analysis across all fact tables.

#### Scenario: Vehicle count measures
- **WHEN** data is sliced by any dimension
- **THEN** measure `Total Vehicles` SHALL return the distinct count of `kenteken`
- **THEN** measure `Vehicles by Fuel Type` SHALL return count per `brandstof_omschrijving`
- **THEN** measure `Vehicles by Brand` SHALL return count per `merk`

#### Scenario: Fuel distribution measures
- **WHEN** `fact_fuel_distribution` is queried
- **THEN** measure `Total Vehicle Count` SHALL return `SUM(aantal)`
- **THEN** measure `EV Share %` SHALL return the percentage of vehicles with electric fuel types
- **THEN** measure `Externally Chargeable %` SHALL return the percentage where `extern_oplaadbaar` is true

#### Scenario: Parking measures
- **WHEN** `fact_parking_capacity` is queried
- **THEN** measure `Total Parking Capacity` SHALL return `SUM(capacity)`
- **THEN** measure `EV Charging Coverage %` SHALL return `SUM(charging_point_capacity) / SUM(capacity)`
- **THEN** measure `Accessible Parking %` SHALL return proportion with `disabled_access > 0`
