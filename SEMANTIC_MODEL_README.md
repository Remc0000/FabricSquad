# RDW Analytics - Direct Lake Semantic Model

## Overview
This directory contains the complete TMDL (Tabular Model Definition Language) definition for the **RDW Analytics** Direct Lake semantic model.

## Configuration
- **Workspace ID**: `97b7e768-c5d2-4501-9af2-29b37be6c83c`
- **Workspace Name**: RDWAgents
- **Lakehouse ID**: `ac035351-73d1-4297-bfbd-6ea91e63eeba`
- **Lakehouse Name**: RDWAgentsLake
- **Model Type**: Direct Lake (optimized for real-time analytics)

## Model Structure

### Tables (9)

#### Dimension Tables (5)
- **dim_vehicle** - Vehicle master data (license plate, brand, type, color, seats)
- **dim_fuel_type** - Fuel types (electricity, petrol, diesel, hybrid, etc.)
- **dim_location** - Geographic data (postal codes, cities, provinces, coordinates)
- **dim_parking_area** - Parking zones and area managers
- **dim_date** - Date dimension (year, quarter, month, day, day of week)

#### Fact Tables (4)
- **fact_vehicle_registration** - Vehicle registrations by type and location
- **fact_vehicle_emissions** - CO2 emissions, engine power, vehicle weight
- **fact_fuel_distribution** - Fuel type distribution by location
- **fact_parking_capacity** - Parking capacity by area and location

### Relationships (10)
1. fact_vehicle_registration → dim_vehicle (vehicle_key)
2. fact_vehicle_registration → dim_fuel_type (fuel_type_key)
3. fact_vehicle_registration → dim_location (location_key)
4. fact_vehicle_registration → dim_date (registration_date_key)
5. fact_vehicle_emissions → dim_vehicle (vehicle_key)
6. fact_vehicle_emissions → dim_fuel_type (fuel_type_key)
7. fact_fuel_distribution → dim_fuel_type (fuel_type_key)
8. fact_fuel_distribution → dim_location (location_key)
9. fact_parking_capacity → dim_parking_area (parking_area_key)
10. fact_parking_capacity → dim_location (location_key)

### DAX Measures (10)

#### Core Metrics
- **Total Vehicles** - Sum of all registered vehicles
- **Total CO2 Emissions** - Total CO2 output across all vehicles
- **Average CO2 per Vehicle** - CO2 emissions per vehicle

#### Environmental Analysis
- **Electric Vehicles** - Count of fully electric vehicles
- **Hybrid Vehicles** - Count of hybrid vehicles

#### Vehicle Statistics
- **Average Vehicle Weight** - Mean vehicle weight (kg)
- **Average Engine Power** - Mean engine power (kW)

#### Distribution Analysis
- **Vehicles by Fuel Type** - Vehicle count by fuel type
- **Top Brand Market Share** - Market share of leading brand

#### Parking Metrics
- **Total Parking Capacity** - Total parking spaces available

## Creation Methods

### Method 1: Fabric Portal (Recommended) ⭐
**Easiest and most reliable method**

1. Navigate to: https://app.fabric.microsoft.com/groups/97b7e768-c5d2-4501-9af2-29b37be6c83c
2. Click **+ New** → **Semantic model**
3. Choose **Get data** → **OneLake data hub**
4. Select lakehouse: **RDWAgentsLake**
5. Select all 9 gold schema tables:
   - gold.dim_vehicle
   - gold.dim_fuel_type
   - gold.dim_location
   - gold.dim_parking_area
   - gold.dim_date
   - gold.fact_vehicle_registration
   - gold.fact_vehicle_emissions
   - gold.fact_fuel_distribution
   - gold.fact_parking_capacity
6. Name it: **RDW Analytics**
7. Click **Create**
8. On the model view, click **Manage relationships**
9. Click **Auto-detect** to create relationships automatically
10. Review and adjust relationships if needed
11. Add DAX measures from `tmdl/measures.tmdl`

### Method 2: Power BI Desktop with TMDL
**Best for advanced customization**

1. Download and install latest **Power BI Desktop** (version with TMDL support)
2. Open Power BI Desktop
3. Go to **File** → **Import** → **Power BI Project**
4. If TMDL import is available:
   - Select the `tmdl/` folder
   - Review the imported model
   - Publish to **RDWAgents** workspace
5. If direct TMDL import isn't available:
   - Create a new blank report
   - Get data from OneLake
   - Connect to RDWAgentsLake
   - Import the 9 gold tables
   - Manually add relationships using `tmdl/relationships.tmdl` as reference
   - Add measures from `tmdl/measures.tmdl`
   - Publish to workspace

### Method 3: VS Code Fabric Extension
**For developers familiar with VS Code**

1. Install **Microsoft Fabric** extension in VS Code
2. Open Fabric workspace panel
3. Sign in to your Fabric tenant
4. Navigate to **RDWAgents** workspace
5. Right-click → **Create Item** → **Semantic Model**
6. Configure Direct Lake connection
7. Select **RDWAgentsLake** as data source
8. Import the TMDL files from the `tmdl/` folder

### Method 4: XMLA Endpoint (Advanced)
**For programmatic deployment**

```powershell
# Using Tabular Editor 3 or similar XMLA tools
# Connect to XMLA endpoint: powerbi://api.powerbi.com/v1.0/myorg/RDWAgents
# Import TMDL folder or BIM file
```

## TMDL File Structure

```
tmdl/
├── .platform                          # Fabric item metadata
├── model.tmdl                         # Model configuration
├── database.tmdl                      # Database properties
├── DirectLake_RDWAgentsLake.tmdl     # Data source definition
├── dim_vehicle.tmdl                   # Vehicle dimension
├── dim_fuel_type.tmdl                 # Fuel type dimension
├── dim_location.tmdl                  # Location dimension
├── dim_parking_area.tmdl              # Parking area dimension
├── dim_date.tmdl                      # Date dimension
├── fact_vehicle_registration.tmdl     # Registration facts
├── fact_vehicle_emissions.tmdl        # Emissions facts
├── fact_fuel_distribution.tmdl        # Fuel distribution facts
├── fact_parking_capacity.tmdl         # Parking capacity facts
├── relationships.tmdl                 # Star schema relationships
└── measures.tmdl                      # DAX measures
```

## Direct Lake Benefits
- **Real-time analytics** - No import delays, query live data
- **Automatic refresh** - Data changes in lakehouse instantly available
- **Optimized performance** - V-order optimization for fast queries
- **Cost efficient** - No separate storage for imported data
- **Simplified architecture** - Single source of truth in lakehouse

## Next Steps After Creation

1. **Verify Direct Lake Mode**
   - Open semantic model in Power BI Desktop
   - Check Status bar shows "DirectLake" mode

2. **Test Relationships**
   - Create a simple visual crossing dimensions and facts
   - Verify filtering works correctly

3. **Test Measures**
   - Add measures to a table visual
   - Verify calculations are correct

4. **Create Power BI Report**
   - Build visualizations using the semantic model
   - Publish report to workspace

5. **Set Refresh Schedule** (if needed)
   - Direct Lake auto-refreshes
   - Only needed if switching to import mode for specific scenarios

## Troubleshooting

### "Table not found" errors
- Verify gold schema tables exist in lakehouse
- Check table names match exactly (case-sensitive)

### Relationships not auto-detected
- Manually create using the relationship definitions in `tmdl/relationships.tmdl`
- Verify column names and data types match

### Direct Lake mode not available
- Ensure lakehouse is in a Fabric capacity (not Power BI Premium)
- Check that tables are Delta format in the Tables folder

### Performance issues
- Verify V-order optimization is enabled on Delta tables
- Check that appropriate columns are indexed

## Resources
- [Direct Lake Overview](https://learn.microsoft.com/en-us/power-bi/enterprise/directlake-overview)
- [TMDL Documentation](https://learn.microsoft.com/en-us/analysis-services/tmdl/tmdl-overview)
- [Fabric Semantic Models](https://learn.microsoft.com/en-us/fabric/data-warehouse/semantic-models)
- [DAX Reference](https://dax.guide/)

## Files Reference
- `setup_semantic_model.ps1` - Setup guide (run this for instructions)
- `semantic_model_reference.json` - Configuration reference
- `tmdl/` - Complete TMDL definition
- `model.bim` - Alternative BIM JSON format

---

**Created**: 2026-03-30  
**Workspace**: RDWAgents (97b7e768-c5d2-4501-9af2-29b37be6c83c)  
**Data Source**: RDWAgentsLake (ac035351-73d1-4297-bfbd-6ea91e63eeba)  
**Schema**: gold (medallion architecture - gold layer)
