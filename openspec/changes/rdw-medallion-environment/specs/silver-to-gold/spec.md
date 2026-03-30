## ADDED Requirements

### Requirement: Dimension - dim_vehicle
The Gold layer SHALL contain `gold.dim_vehicle` with one row per unique vehicle, derived from `silver.vehicles`.

#### Scenario: dim_vehicle structure
- **WHEN** the Silver-to-Gold notebook is executed
- **THEN** `gold.dim_vehicle` SHALL contain columns: `vehicle_key` (surrogate integer), `kenteken` (business key), `voertuigsoort`, `merk`, `handelsbenaming`, `inrichting`, `eerste_kleur`, `tweede_kleur`, `europese_voertuigcategorie`, `subcategorie_nederland`, `aantal_zitplaatsen`, `aantal_deuren`, `aantal_wielen`, `massa_ledig_voertuig`, `massa_rijklaar`, `lengte`, `breedte`, `hoogte_voertuig`, `cilinderinhoud`, `aantal_cilinders`, `maximale_constructiesnelheid`, `export_indicator`, `taxi_indicator`, `wam_verzekerd`

#### Scenario: One row per vehicle
- **WHEN** `silver.vehicles` contains multiple rows (if any duplicates exist)
- **THEN** `gold.dim_vehicle` SHALL contain exactly one row per unique `kenteken`

### Requirement: Dimension - dim_fuel_type
The Gold layer SHALL contain `gold.dim_fuel_type` with one row per unique fuel type, derived from `silver.vehicle_fuels`.

#### Scenario: dim_fuel_type structure
- **WHEN** the Silver-to-Gold notebook is executed
- **THEN** `gold.dim_fuel_type` SHALL contain columns: `fuel_type_key` (surrogate), `brandstof_omschrijving`, `emissieklasse`, `milieuklasse_eg_goedkeuring_licht`, `milieuklasse_eg_goedkeuring_zwaar`, `klasse_hybride_elektrisch_voertuig`, `co2_emissieklasse`, `uitlaatemissieniveau`

#### Scenario: Distinct fuel types
- **WHEN** multiple vehicles share the same fuel type attributes
- **THEN** `gold.dim_fuel_type` SHALL contain exactly one row per unique combination of fuel type attributes

### Requirement: Dimension - dim_location
The Gold layer SHALL contain `gold.dim_location` with one row per unique location, derived from `silver.fuels_by_postal_code` and `silver.parking_addresses`.

#### Scenario: dim_location structure
- **WHEN** the Silver-to-Gold notebook is executed
- **THEN** `gold.dim_location` SHALL contain columns: `location_key` (surrogate), `postcode` (4-digit), `street_name`, `house_number`, `zip_code` (full), `place`, `province`, `country`

#### Scenario: Postal code coverage
- **WHEN** `silver.fuels_by_postal_code` contains postal codes not present in `silver.parking_addresses`
- **THEN** `gold.dim_location` SHALL include those postal codes with null values for street-level fields

### Requirement: Dimension - dim_parking_area
The Gold layer SHALL contain `gold.dim_parking_area` with one row per unique parking area, derived from `silver.parking_area_specs`.

#### Scenario: dim_parking_area structure
- **WHEN** the Silver-to-Gold notebook is executed
- **THEN** `gold.dim_parking_area` SHALL contain columns: `parking_area_key` (surrogate), `area_manager_id`, `area_id`, `capacity`, `charging_point_capacity`, `disabled_access`, `maximum_vehicle_height`, `limited_access`

### Requirement: Dimension - dim_date
The Gold layer SHALL contain a generated `gold.dim_date` covering all dates present in the dataset.

#### Scenario: dim_date structure
- **WHEN** the Silver-to-Gold notebook is executed
- **THEN** `gold.dim_date` SHALL contain columns: `date_key` (integer YYYYMMDD), `full_date` (date), `year`, `quarter`, `month`, `month_name`, `week_of_year`, `day_of_month`, `day_of_week`, `day_name`, `is_weekend` (boolean)

#### Scenario: Date range coverage
- **WHEN** dates range from 1950 to 2030 across all source date fields
- **THEN** `gold.dim_date` SHALL contain one row per calendar date in that range

### Requirement: Fact - fact_vehicle_registration
The Gold layer SHALL contain `gold.fact_vehicle_registration` with one row per vehicle registration, linking to all relevant dimensions.

#### Scenario: fact_vehicle_registration structure
- **WHEN** the Silver-to-Gold notebook is executed
- **THEN** `gold.fact_vehicle_registration` SHALL contain foreign keys: `vehicle_key`, `date_key_eerste_toelating`, `date_key_tenaamstelling`, `date_key_apk_vervaldatum`
- **THEN** the table SHALL contain measures: `bruto_bpm`, `catalogusprijs`, `massa_rijklaar`, `massa_ledig_voertuig`, `cilinderinhoud`, `aantal_cilinders`, `maximale_constructiesnelheid`, `laadvermogen`, `aantal_zitplaatsen`, `aantal_deuren`

#### Scenario: Outlier detection readiness
- **WHEN** `fact_vehicle_registration` is queried
- **THEN** numeric measures SHALL be queryable for aggregation (AVG, STDEV, MIN, MAX, COUNT) to support z-score outlier detection

### Requirement: Fact - fact_vehicle_emissions
The Gold layer SHALL contain `gold.fact_vehicle_emissions` with one row per vehicle-fuel combination.

#### Scenario: fact_vehicle_emissions structure
- **WHEN** the Silver-to-Gold notebook is executed
- **THEN** `gold.fact_vehicle_emissions` SHALL contain foreign keys: `vehicle_key`, `fuel_type_key`
- **THEN** the table SHALL contain measures: `co2_uitstoot_gecombineerd`, `co2_uitstoot_gewogen`, `brandstofverbruik_stad`, `brandstofverbruik_buiten_de_stad`, `brandstofverbruik_gecombineerd`, `nettomaximumvermogen`, `roetuitstoot`, `uitstoot_deeltjes_licht`, `uitstoot_deeltjes_zwaar`, `actieradius`, `actieradius_extern_oplaadbaar`, `emissie_co2_gecombineerd_wltp`, `actie_radius_enkel_elektrisch_wltp`

### Requirement: Fact - fact_fuel_distribution
The Gold layer SHALL contain `gold.fact_fuel_distribution` derived from `silver.fuels_by_postal_code`.

#### Scenario: fact_fuel_distribution structure
- **WHEN** the Silver-to-Gold notebook is executed
- **THEN** `gold.fact_fuel_distribution` SHALL contain foreign keys: `location_key`
- **THEN** the table SHALL contain degenerate dimensions: `voertuigsoort`, `brandstof`, `extern_oplaadbaar`
- **THEN** the table SHALL contain measure: `aantal` (vehicle count)

#### Scenario: Count analysis readiness
- **WHEN** `fact_fuel_distribution` is queried grouped by `voertuigsoort` and `brandstof`
- **THEN** `aantal` SHALL represent the count of vehicles for that combination in the given postal code area

### Requirement: Fact - fact_parking_capacity
The Gold layer SHALL contain `gold.fact_parking_capacity` joining parking specs with parking addresses.

#### Scenario: fact_parking_capacity structure
- **WHEN** the Silver-to-Gold notebook is executed
- **THEN** `gold.fact_parking_capacity` SHALL contain foreign keys: `parking_area_key`, `location_key`, `date_key_start`, `date_key_end`
- **THEN** the table SHALL contain measures: `capacity`, `charging_point_capacity`, `disabled_access`

### Requirement: Overwrite mode for idempotency
The notebook SHALL write all Gold tables using overwrite mode.

#### Scenario: Re-execution idempotency
- **WHEN** the Silver-to-Gold notebook is executed multiple times
- **THEN** Gold tables SHALL reflect the current state of Silver data without duplicates
