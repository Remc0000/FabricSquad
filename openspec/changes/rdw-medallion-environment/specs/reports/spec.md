## ADDED Requirements

### Requirement: Fleet composition report
A Power BI report page SHALL visualize the vehicle fleet composition across multiple dimensions.

#### Scenario: Brand distribution
- **WHEN** a user opens the Fleet Composition page
- **THEN** a bar chart SHALL display vehicle counts by top 20 brands (Merk)
- **THEN** a slicer SHALL allow filtering by vehicle type (Voertuigsoort), fuel type, and color

#### Scenario: Vehicle category breakdown
- **WHEN** a user views the fleet composition
- **THEN** a treemap or stacked bar SHALL show vehicle counts by European vehicle category and Dutch subcategory
- **THEN** a card visual SHALL display total vehicle count

### Requirement: Emissions outlier report
A Power BI report page SHALL highlight emission outliers using statistical measures.

#### Scenario: Outlier scatter plot
- **WHEN** a user opens the Emissions Outliers page
- **THEN** a scatter plot SHALL display CO2 emissions vs engine displacement (cilinderinhoud) with outliers (>2σ) highlighted in a contrasting color
- **THEN** a table SHALL list the top 50 outlier vehicles with their kenteken, merk, model, and emission values

#### Scenario: Distribution analysis
- **WHEN** a user selects a metric (CO2, fuel consumption, particulate emissions)
- **THEN** a histogram SHALL display the distribution with percentile markers (P25, P50, P75, P95)
- **THEN** KPI cards SHALL show mean, median, standard deviation, and outlier count

### Requirement: Geographic distribution report
A Power BI report page SHALL show fuel type adoption patterns across Dutch postal code regions.

#### Scenario: Postal code heatmap
- **WHEN** a user opens the Geographic Distribution page
- **THEN** a filled map or matrix SHALL display vehicle counts by 4-digit postal code area
- **THEN** slicers SHALL allow filtering by fuel type and vehicle type

#### Scenario: EV adoption view
- **WHEN** a user selects the EV filter
- **THEN** the map SHALL show EV concentration by postal code
- **THEN** a KPI card SHALL display overall EV share percentage and externally chargeable percentage

### Requirement: Parking infrastructure report
A Power BI report page SHALL analyze parking facility capacity and accessibility.

#### Scenario: Capacity overview
- **WHEN** a user opens the Parking Infrastructure page
- **THEN** KPI cards SHALL display total parking capacity, total EV charging points, and accessible parking percentage
- **THEN** a bar chart SHALL show parking capacity by province

#### Scenario: EV charging coverage
- **WHEN** a user views charging infrastructure
- **THEN** a chart SHALL compare total parking capacity vs EV charging capacity by area
- **THEN** areas with zero charging points SHALL be highlighted

### Requirement: Trend analysis report
A Power BI report page SHALL show trends over time based on vehicle registration dates.

#### Scenario: Registration trends
- **WHEN** a user opens the Trends page
- **THEN** a line chart SHALL display new vehicle registrations over time (by datum_eerste_toelating) grouped by year and month
- **THEN** slicers SHALL allow filtering by brand, fuel type, and vehicle category

#### Scenario: APK expiry analysis
- **WHEN** a user selects the APK view
- **THEN** a bar chart SHALL show count of vehicles with upcoming APK expiry dates grouped by month
- **THEN** vehicles with expired APK SHALL be highlighted separately
