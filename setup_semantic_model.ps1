# RDW Analytics Direct Lake Semantic Model - Creation Guide
# ==========================================================
# The Fabric REST API has limitations for creating Direct Lake semantic models.
# This script provides the TMDL definition and guidance for manual creation.

$workspaceId = "97b7e768-c5d2-4501-9af2-29b37be6c83c"
$lakehouseId = "ac035351-73d1-4297-bfbd-6ea91e63eeba"
$modelName = "RDW Analytics"

Write-Host "=== RDW Analytics Semantic Model Setup ===" -ForegroundColor Yellow
Write-Host ""

# Method 1: Create via Fabric Portal (Recommended)
Write-Host "METHOD 1: Create via Fabric Portal (Recommended)" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "1. Navigate to: https://app.fabric.microsoft.com/groups/$workspaceId"
Write-Host "2. Click '+ New' > 'Semantic model' > 'Direct Lake'"
Write-Host "3. Select lakehouse: RDWAgentsLake (ID: $lakehouseId)"
Write-Host "4. Name it: $modelName"
Write-Host "5. Select these 9 Gold tables:"
Write-Host "   - gold.dim_vehicle"
Write-Host "   - gold.dim_fuel_type"
Write-Host "   - gold.dim_location"
Write-Host "   - gold.dim_parking_area"
Write-Host "   - gold.dim_date"
Write-Host "   - gold.fact_vehicle_registration"
Write-Host "   - gold.fact_vehicle_emissions"
Write-Host "   - gold.fact_fuel_distribution"
Write-Host "   - gold.fact_parking_capacity"
Write-Host "6. Click 'Auto-create relationships' or configure manually"
Write-Host ""

# Method 2: Create via Power BI Desktop
Write-Host "METHOD 2: Create via Power BI Desktop with TMDL" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "1. Open Power BI Desktop (latest version with TMDL support)"
Write-Host "2. File > Import > TMDL folder"
Write-Host "3. Select folder: $PSScriptRoot\tmdl"
Write-Host "4. Review the model structure"
Write-Host "5. Publish to workspace: RDWAgents ($workspaceId)"
Write-Host ""

# Method 3: Use VS Code Fabric Extension
Write-Host "METHOD 3: VS Code Fabric Extension" -ForegroundColor Cyan
Write-Host "-----------------------------------" -ForegroundColor Cyan
Write-Host "1. Install 'Microsoft Fabric' extension in VS Code"
Write-Host "2. Open Fabric workspace view"
Write-Host "3. Right-click RDWAgents workspace > 'Create Item' > 'Semantic Model'"
Write-Host "4. Configure Direct Lake connection to RDWAgentsLake"
Write-Host ""

# Display configuration summary
Write-Host "=== Model Configuration Summary ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "Workspace ID: $workspaceId" -ForegroundColor White
Write-Host "Lakehouse ID: $lakehouseId" -ForegroundColor White
Write-Host "Model Name: $modelName" -ForegroundColor White
Write-Host ""
Write-Host "Tables (9):" -ForegroundColor Green
Write-Host "  Dimensions (5):"
Write-Host "    - dim_vehicle       (vehicle details)"
Write-Host "    - dim_fuel_type     (fuel types)"
Write-Host "    - dim_location      (postal codes, cities)"
Write-Host "    - dim_parking_area  (parking zones)"
Write-Host "    - dim_date          (date dimension)"
Write-Host "  Facts (4):"
Write-Host "    - fact_vehicle_registration  (vehicle counts by type & location)"
Write-Host "    - fact_vehicle_emissions     (CO2, weight, power)"
Write-Host "    - fact_fuel_distribution     (fuel types by location)"
Write-Host "    - fact_parking_capacity      (parking capacity by area)"
Write-Host ""
Write-Host "Relationships (10):" -ForegroundColor Green
Write-Host "  1. fact_vehicle_registration -> dim_vehicle      (vehicle_key)"
Write-Host "  2. fact_vehicle_registration -> dim_fuel_type    (fuel_type_key)"
Write-Host "  3. fact_vehicle_registration -> dim_location     (location_key)"
Write-Host "  4. fact_vehicle_registration -> dim_date         (registration_date_key)"
Write-Host "  5. fact_vehicle_emissions    -> dim_vehicle      (vehicle_key)"
Write-Host "  6. fact_vehicle_emissions    -> dim_fuel_type    (fuel_type_key)"
Write-Host "  7. fact_fuel_distribution    -> dim_fuel_type    (fuel_type_key)"
Write-Host "  8. fact_fuel_distribution    -> dim_location     (location_key)"
Write-Host "  9. fact_parking_capacity     -> dim_parking_area (parking_area_key)"
Write-Host " 10. fact_parking_capacity     -> dim_location     (location_key)"
Write-Host ""
Write-Host "DAX Measures (10):" -ForegroundColor Green
Write-Host "  - Total Vehicles"
Write-Host "  - Total CO2 Emissions"
Write-Host "  - Average CO2 per Vehicle"
Write-Host "  - Total Parking Capacity"
Write-Host "  - Electric Vehicles"
Write-Host "  - Hybrid Vehicles"
Write-Host "  - Average Vehicle Weight"
Write-Host "  - Average Engine Power"
Write-Host "  - Vehicles by Fuel Type"
Write-Host "  - Top Brand Market Share"
Write-Host ""
Write-Host "All TMDL definition files are ready in: $PSScriptRoot\tmdl\" -ForegroundColor Cyan
Write-Host ""

# Create a quick reference JSON file
$reference = @{
    workspace = @{
        id = $workspaceId
        name = "RDWAgents"
    }
    lakehouse = @{
        id = $lakehouseId
        name = "RDWAgentsLake"
    }
    semanticModel = @{
        name = $modelName
        type = "DirectLake"
        status = "Ready for creation"
        tables = @(
            "dim_vehicle",
            "dim_fuel_type",
            "dim_location",
            "dim_parking_area",
            "dim_date",
            "fact_vehicle_registration",
            "fact_vehicle_emissions",
            "fact_fuel_distribution",
            "fact_parking_capacity"
        )
        relationshipCount = 10
        measureCount = 10
    }
    tmdlLocation = "$PSScriptRoot\tmdl\"
    portalUrl = "https://app.fabric.microsoft.com/groups/$workspaceId"
}

$reference | ConvertTo-Json -Depth 10 | Out-File "$PSScriptRoot\semantic_model_reference.json"

Write-Host "Reference file saved: semantic_model_reference.json" -ForegroundColor Green
Write-Host ""
Write-Host "NOTE: Due to Direct Lake API limitations, manual creation is recommended." -ForegroundColor Yellow
Write-Host "The TMDL files in the tmdl/ folder contain the complete model definition." -ForegroundColor Yellow
