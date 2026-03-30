## ADDED Requirements

### Requirement: Date column normalization
The Silver layer SHALL parse all date columns from their raw formats (integer YYYYMMDD, string ISO, epoch milliseconds) into proper `date` type columns.

#### Scenario: Integer date parsing
- **WHEN** `Vervaldatum_APK` contains integer value `20260315`
- **THEN** `silver.vehicles.vervaldatum_apk` SHALL contain date `2026-03-15`

#### Scenario: String date parsing
- **WHEN** `Datum_eerste_toelating` contains string `"20180601"`
- **THEN** `silver.vehicles.datum_eerste_toelating` SHALL contain date `2018-06-01`

#### Scenario: Epoch date parsing for parking specs
- **WHEN** `StartDateSpecifications` contains epoch milliseconds value `1609459200000`
- **THEN** `silver.parking_area_specs.start_date` SHALL contain date `2021-01-01`

#### Scenario: Null date handling
- **WHEN** a date column contains null or empty string
- **THEN** the Silver date column SHALL contain null (not a default date)

### Requirement: Numeric column type casting
The Silver layer SHALL cast string-typed numeric columns to their correct numeric types.

#### Scenario: String-to-integer casting
- **WHEN** `Bruto_BPM` contains string `"12500"`
- **THEN** `silver.vehicles.bruto_bpm` SHALL contain integer `12500`

#### Scenario: String-to-double casting
- **WHEN** `Catalogusprijs` contains string `"45999.00"`
- **THEN** `silver.vehicles.catalogusprijs` SHALL contain double `45999.0`

#### Scenario: Non-numeric string handling
- **WHEN** a numeric column contains a non-parseable string (e.g., `"N/A"`, `""`)
- **THEN** the Silver column SHALL contain null

### Requirement: Column name standardization
All Silver table column names SHALL be lowercase snake_case, consistent with Python/Spark conventions.

#### Scenario: Column renaming
- **WHEN** source column is `Kenteken`
- **THEN** Silver column SHALL be `kenteken`

#### Scenario: Special character handling
- **WHEN** source column contains `/` (e.g., `Maximum_last_onder_de_vooras_sen_tezamen_/koppeling`)
- **THEN** Silver column SHALL replace special characters with underscores: `maximum_last_onder_de_vooras_sen_tezamen_koppeling`

### Requirement: Silver vehicles table
The notebook SHALL create `silver.vehicles` from `bronze.gekentekende_voertuigen` with all columns properly typed and cleaned.

#### Scenario: Silver vehicles output
- **WHEN** the Bronze-to-Silver notebook is executed
- **THEN** `silver.vehicles` SHALL exist as a Delta table
- **THEN** the table SHALL contain one row per unique `kenteken` (license plate)
- **THEN** all date columns SHALL be date type, all numeric columns SHALL be numeric types

### Requirement: Silver vehicle_fuels table
The notebook SHALL create `silver.vehicle_fuels` from `bronze.gekentekende_voertuigen_brandstof`.

#### Scenario: Silver vehicle_fuels output
- **WHEN** the Bronze-to-Silver notebook is executed
- **THEN** `silver.vehicle_fuels` SHALL exist as a Delta table
- **THEN** the table SHALL contain one row per `kenteken` + `brandstof_volgnummer` combination
- **THEN** emission and consumption columns SHALL be properly typed as double/integer

### Requirement: Silver fuels_by_postal_code table
The notebook SHALL create `silver.fuels_by_postal_code` from `bronze.brandstoffen_op_pc4`.

#### Scenario: Silver fuels_by_postal_code output
- **WHEN** the Bronze-to-Silver notebook is executed
- **THEN** `silver.fuels_by_postal_code` SHALL exist as a Delta table
- **THEN** `extern_oplaadbaar` SHALL be cast to boolean type

### Requirement: Silver parking tables
The notebook SHALL create `silver.parking_addresses` from `bronze.parkeeradres` and `silver.parking_area_specs` from `bronze.specificaties_parkeergebied`.

#### Scenario: Silver parking_addresses output
- **WHEN** the Bronze-to-Silver notebook is executed
- **THEN** `silver.parking_addresses` SHALL exist as a Delta table with properly typed columns

#### Scenario: Silver parking_area_specs output
- **WHEN** the Bronze-to-Silver notebook is executed
- **THEN** `silver.parking_area_specs` SHALL exist as a Delta table
- **THEN** `start_date` and `end_date` SHALL be date type (converted from epoch milliseconds)

### Requirement: Overwrite mode for idempotency
The notebook SHALL write all Silver tables using overwrite mode to ensure idempotent re-execution.

#### Scenario: Re-execution produces same result
- **WHEN** the Bronze-to-Silver notebook is executed multiple times
- **THEN** Silver tables SHALL contain the same data as a single execution (no duplicates)
