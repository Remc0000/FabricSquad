# Creating the RDW Analytics Semantic Model

This guide walks through creating a Direct Lake semantic model on top of the Gold layer tables.

## Prerequisites
- Gold layer tables created in `RDWAgentsLake` lakehouse
- Contributor role in RDWAgents workspace
- Power BI Desktop (optional, for advanced relationship configuration)

---

## Part 1: Create the Semantic Model via Fabric Portal

### Step 1: Navigate to the SQL Analytics Endpoint

1. Open the Fabric portal: https://app.fabric.microsoft.com
2. Navigate to **RDWAgents workspace**
3. Find **RDWAgentsLake** lakehouse
4. Click the **SQL analytics endpoint** (not the lakehouse itself)

### Step 2: Create the Semantic Model

1. In the SQL analytics endpoint view, you'll see all tables across schemas
2. Click **Reporting** tab at the top
3. Click **New semantic model**
4. Name it: `RDW Analytics`
5. Select the Gold layer tables:
   - ✅ gold.dim_vehicle
   - ✅ gold.dim_fuel_type
   - ✅ gold.dim_location
   - ✅ gold.dim_parking_area
   - ✅ gold.dim_date
   - ✅ gold.fact_vehicle_registration
   - ✅ gold.fact_vehicle_emissions
   - ✅ gold.fact_fuel_distribution
   - ✅ gold.fact_parking_capacity
6. Click **Confirm**

The semantic model will be created in Direct Lake mode, providing real-time access to the lakehouse data.

---

## Part 2: Configure Relationships

Fabric auto-detects some relationships, but you may need to configure the star schema manually.

### Option A: Via Web Modeling (Recommended for Workshop)

1. Open the **RDW Analytics** semantic model
2. Click **Open data model** at the top
3. In the model view, create relationships by dragging:

**Vehicle Registrations Fact:**
- `fact_vehicle_registration.vehicle_key` → `dim_vehicle.vehicle_key`
- `fact_vehicle_registration.fuel_key` → `dim_fuel_type.fuel_key`
- `fact_vehicle_registration.location_key` → `dim_location.location_key`
- `fact_vehicle_registration.date_key` → `dim_date.date_key`

**Vehicle Emissions Fact:**
- `fact_vehicle_emissions.vehicle_key` → `dim_vehicle.vehicle_key`
- `fact_vehicle_emissions.fuel_key` → `dim_fuel_type.fuel_key`

**Fuel Distribution Fact:**
- `fact_fuel_distribution.fuel_key` → `dim_fuel_type.fuel_key`
- `fact_fuel_distribution.location_key` → `dim_location.location_key`
- `fact_fuel_distribution.date_key` → `dim_date.date_key`

**Parking Capacity Fact:**
- `fact_parking_capacity.parking_area_key` → `dim_parking_area.parking_area_key`
- `fact_parking_capacity.location_key` → `dim_location.location_key`

4. Ensure all relationships are **Many-to-One** (from fact to dimension)
5. Set cross-filter direction to **Single** (default)
6. Click **Save**

### Option B: Via Power BI Desktop (Advanced)

1. Open Power BI Desktop
2. Get Data → More → Power Platform → **Semantic models**
3. Select **RDW Analytics**
4. Connect in **DirectQuery** mode (not import!)
5. Use Model view to configure relationships (same as above)
6. Publish back to the workspace

---

## Part 3: Add DAX Measures

### Option A: Via Web Modeling

1. Open the semantic model
2. Click **Open data model**
3. In the model view, click **New measure** in the ribbon
4. Add each measure from the list below:

#### Vehicle Analytics Measures

```dax
Total Vehicles = COUNTROWS(fact_vehicle_registration)
```

```dax
Avg CO2 Emissions = AVERAGE(fact_vehicle_emissions[co2_emission])
```

```dax
CO2 Z-Score = 
VAR AvgCO2 = CALCULATE(AVERAGE(fact_vehicle_emissions[co2_emission]), ALL(fact_vehicle_emissions))
VAR StdDevCO2 = CALCULATE(STDEV.P(fact_vehicle_emissions[co2_emission]), ALL(fact_vehicle_emissions))
RETURN
DIVIDE([Avg CO2 Emissions] - AvgCO2, StdDevCO2, BLANK())
```

```dax
CO2 Outliers (>2 SD) = 
CALCULATE(
    COUNTROWS(fact_vehicle_emissions),
    ABS([CO2 Z-Score]) > 2
)
```

```dax
Fuel Efficiency Z-Score = 
VAR AvgEff = CALCULATE(AVERAGE(fact_vehicle_emissions[fuel_efficiency]), ALL(fact_vehicle_emissions))
VAR StdDevEff = CALCULATE(STDEV.P(fact_vehicle_emissions[fuel_efficiency]), ALL(fact_vehicle_emissions))
RETURN
DIVIDE(AVERAGE(fact_vehicle_emissions[fuel_efficiency]) - AvgEff, StdDevEff, BLANK())
```

#### Fuel Distribution Measures

```dax
Total Fuel Distribution = SUM(fact_fuel_distribution[fuel_count])
```

```dax
Fuel Market Share % = 
DIVIDE(
    [Total Fuel Distribution],
    CALCULATE([Total Fuel Distribution], ALL(dim_fuel_type)),
    0
) * 100
```

#### Parking Measures

```dax
Total Parking Capacity = SUM(fact_parking_capacity[total_spots)
```

```dax
Paid Parking % = 
DIVIDE(
    SUM(fact_parking_capacity[paid_spots]),
    [Total Parking Capacity],
    0
) * 100
```

```dax
Disabled Parking % = 
DIVIDE(
    SUM(fact_parking_capacity[disabled_spots]),
    [Total Parking Capacity],
    0
) * 100
```

#### Statistical Measures

```dax
P50 Emissions = PERCENTILE.INC(fact_vehicle_emissions[co2_emission], 0.5)
```

```dax
P90 Emissions = PERCENTILE.INC(fact_vehicle_emissions[co2_emission], 0.9)
```

```dax
P99 Emissions = PERCENTILE.INC(fact_vehicle_emissions[co2_emission], 0.99)
```

5. Save the semantic model

### Option B: Via PowerShell Script

```powershell
# Install required module (first time only)
# Install-Module -Name Az.Accounts
# Install-Module -Name Microsoft.AnalysisServices.Administration

# Use the provided script: add-dax-measures.ps1
.\add-dax-measures.ps1
```

---

## Part 4: Verify the Semantic Model

1. In the Fabric portal, open **RDW Analytics** semantic model
2. Click **Explore this data** button
3. You should see:
   - 9 tables (5 dimensions + 4 facts)
   - All relationships displayed in diagram view
   - All measures visible in the Fields pane
4. Try creating a simple visual:
   - Drag `dim_vehicle.brand_name` to a table
   - Add `Total Vehicles` measure
   - Should show vehicle counts by brand

---

## Next Steps

Once the semantic model is configured, proceed to:
- **Part 5:** Create Power BI report pages (see `reports/README.md`)
- **Part 6:** Final validation and documentation updates

---

## Troubleshooting

### Issue: "Cannot create semantic model"
- **Cause:** Workspace not on Fabric capacity
- **Solution:** Verify RDWAgents workspace is assigned to trial capacity

### Issue: "Tables not appearing"
- **Cause:** Gold tables not yet created
- **Solution:** Run notebook `02_silver_to_gold.ipynb` first

### Issue: "Relationship detection failed"
- **Cause:** Key columns don't match between fact/dimension
- **Solution:** Manually create relationships as shown above

### Issue: "DAX measure returns BLANK()"
- **Cause:** Relationships not configured or wrong direction
- **Solution:** Check relationship direction (Many-to-One from facts)

---

## Alternative: Programmatic Creation via XMLA

For advanced users or CI/CD scenarios, you can use the XMLA endpoint:

**Endpoint:** `powerbi://api.powerbi.com/v1.0/myorg/RDWAgents`

**Tools:**
- Tabular Editor 3
- PowerShell with Analysis Services module
- C# with TOM (Tabular Object Model)

See `xmla-scripts/` folder for examples.
