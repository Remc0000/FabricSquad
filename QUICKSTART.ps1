# Quick Start: Create Semantic Model & Reports
# This script opens the necessary URLs in your browser to create the semantic model

param(
    [string]$WorkspaceId = "97b7e768-c5d2-4501-9af2-29b37be6c83c",
    [string]$LakehouseId = "ac035351-73d1-4297-bfbd-6ea91e63eeba"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " RDW Analytics - Quick Setup Guide" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nOpening Fabric portal in your browser..." -ForegroundColor Green

# Step 1: Open SQL endpoint
$sqlEndpointUrl = "https://app.fabric.microsoft.com/groups/$WorkspaceId/lakehouses/$LakehouseId/sqlEndpoint"
Write-Host "`n[Step 1] Opening SQL Analytics Endpoint..." -ForegroundColor Yellow
Start-Process $sqlEndpointUrl

Start-Sleep -Seconds 2

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  FOLLOW THESE STEPS IN FABRIC PORTAL" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

Write-Host "`n📊 STEP 1: Create Semantic Model" -ForegroundColor Yellow
Write-Host "   1. In the SQL endpoint view, click 'Reporting' tab" -ForegroundColor White
Write-Host "   2. Click 'New semantic model'" -ForegroundColor White
Write-Host "   3. Name it: 'RDW Analytics'" -ForegroundColor White
Write-Host "   4. Select ALL gold.* tables (9 tables)" -ForegroundColor White
Write-Host "      ✓ gold.dim_vehicle" -ForegroundColor Gray
Write-Host "      ✓ gold.dim_fuel_type" -ForegroundColor Gray
Write-Host "      ✓ gold.dim_location" -ForegroundColor Gray
Write-Host "      ✓ gold.dim_parking_area" -ForegroundColor Gray
Write-Host "      ✓ gold.dim_date" -ForegroundColor Gray
Write-Host "      ✓ gold.fact_vehicle_registration" -ForegroundColor Gray
Write-Host "      ✓ gold.fact_vehicle_emissions" -ForegroundColor Gray
Write-Host "      ✓ gold.fact_fuel_distribution" -ForegroundColor Gray
Write-Host "      ✓ gold.fact_parking_capacity" -ForegroundColor Gray
Write-Host "   5. Click 'Confirm'" -ForegroundColor White

Write-Host "`n🔗 STEP 2: Configure Relationships" -ForegroundColor Yellow
Write-Host "   1. Open the semantic model" -ForegroundColor White
Write-Host "   2. Click 'Open data model'" -ForegroundColor White
Write-Host "   3. Switch to 'Model view'" -ForegroundColor White
Write-Host "   4. Create 11 relationships by dragging:" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "      FROM fact_vehicle_registration:" -ForegroundColor Cyan
Write-Host "        • vehicle_key → dim_vehicle.vehicle_key" -ForegroundColor Gray
Write-Host "        • fuel_key → dim_fuel_type.fuel_key" -ForegroundColor Gray
Write-Host "        • location_key → dim_location.location_key" -ForegroundColor Gray
Write-Host "        • date_key → dim_date.date_key" -ForegroundColor Gray
Write-Host "" -ForegroundColor White
Write-Host "      FROM fact_vehicle_emissions:" -ForegroundColor Cyan
Write-Host "        • vehicle_key → dim_vehicle.vehicle_key" -ForegroundColor Gray
Write-Host "        • fuel_key → dim_fuel_type.fuel_key" -ForegroundColor Gray
Write-Host "" -ForegroundColor White
Write-Host "      FROM fact_fuel_distribution:" -ForegroundColor Cyan
Write-Host "        • fuel_key → dim_fuel_type.fuel_key" -ForegroundColor Gray
Write-Host "        • location_key → dim_location.location_key" -ForegroundColor Gray
Write-Host "        • date_key → dim_date.date_key" -ForegroundColor Gray
Write-Host "" -ForegroundColor White
Write-Host "      FROM fact_parking_capacity:" -ForegroundColor Cyan
Write-Host "        • parking_area_key → dim_parking_area.parking_area_key" -ForegroundColor Gray
Write-Host "        • location_key → dim_location.location_key" -ForegroundColor Gray
Write-Host "   5. Verify all are Many-to-One, Single direction" -ForegroundColor White
Write-Host "   6. Click 'Save'" -ForegroundColor White

Write-Host "`n📐 STEP 3: Add DAX Measures" -ForegroundColor Yellow
Write-Host "   In model view, click 'New measure' and add these:" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "   Total Vehicles = COUNTROWS(fact_vehicle_registration)" -ForegroundColor Gray
Write-Host "   Avg CO2 Emissions = AVERAGE(fact_vehicle_emissions[co2_emission])" -ForegroundColor Gray
Write-Host "   P50 Emissions = PERCENTILE.INC(fact_vehicle_emissions[co2_emission], 0.5)" -ForegroundColor Gray
Write-Host "   ... (see semantic-model/README.md for all 13 measures)" -ForegroundColor Gray

Write-Host "`n📊 STEP 4: Create Report" -ForegroundColor Yellow
Write-Host "   1. In workspace, click '+ New' → 'Report'" -ForegroundColor White
Write-Host "   2. Select 'RDW Analytics' semantic model" -ForegroundColor White
Write-Host "   3. Create 5 pages (see reports/README.md for designs)" -ForegroundColor White

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  ALTERNATIVE: Run Automation Scripts" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$runAutomation = Read-Host "`nWould you like to try the PowerShell automation scripts instead? (yes/no)"

if ($runAutomation -eq "yes") {
    Write-Host "`n⚠️  NOTE: Automation requires:" -ForegroundColor Yellow
    Write-Host "   • Microsoft.AnalysisServices.Administration module" -ForegroundColor Gray
    Write-Host "   • Power BI / XMLA endpoint permissions" -ForegroundColor Gray
    Write-Host "   • Additional authentication setup" -ForegroundColor Gray
    
    $proceed = Read-Host "`nProceed with automation? (yes/no)"
    
    if ($proceed -eq "yes") {
        Write-Host "`nRunning automation scripts..." -ForegroundColor Green
        
        # Try to run the automation scripts
        Push-Location ..\semantic-model
        
        try {
            Write-Host "`n1. Configuring relationships..." -ForegroundColor Cyan
            .\configure-relationships.ps1 -WorkspaceName "RDWAgents" -DatasetName "RDW Analytics"
            
            Write-Host "`n2. Adding DAX measures..." -ForegroundColor Cyan
            .\add-dax-measures.ps1 -WorkspaceName "RDWAgents" -DatasetName "RDW Analytics"
            
            Write-Host "`n✅ Automation complete!" -ForegroundColor Green
        } catch {
            Write-Host "`n❌ Automation failed: $_" -ForegroundColor Red
            Write-Host "`nFalling back to manual creation via portal." -ForegroundColor Yellow
        }
        
        Pop-Location
    }
} else {
    Write-Host "`n✅ Follow the steps above in the Fabric portal." -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Documentation References" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`n📖 Detailed guides:" -ForegroundColor White
Write-Host "   • semantic-model/README.md - Full model creation guide" -ForegroundColor Gray
Write-Host "   • semantic-model/RELATIONSHIPS.md - Relationship diagrams" -ForegroundColor Gray
Write-Host "   • reports/README.md - Report page designs" -ForegroundColor Gray
Write-Host "   • validation/VALIDATION-CHECKLIST.md - Verification steps" -ForegroundColor Gray

Write-Host "`n🎯 Quick validation:" -ForegroundColor White
Write-Host "   Run: .\validation\validate-environment.ps1" -ForegroundColor Gray

Write-Host "`n🚀 Happy building!" -ForegroundColor Green
