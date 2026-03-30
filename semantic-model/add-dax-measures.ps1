# Add DAX Measures to RDW Analytics Semantic Model
# Uses XMLA endpoint via Analysis Services PowerShell module

param(
    [string]$WorkspaceName = "RDWAgents",
    [string]$DatasetName = "RDW Analytics"
)

# Check if module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.AnalysisServices.Administration)) {
    Write-Host "Installing Microsoft.AnalysisServices.Administration module..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.AnalysisServices.Administration -Scope CurrentUser -Force
}

Import-Module Microsoft.AnalysisServices.Administration

# Connect to XMLA endpoint
$xmlaEndpoint = "powerbi://api.powerbi.com/v1.0/myorg/$WorkspaceName"

Write-Host "Connecting to XMLA endpoint: $xmlaEndpoint" -ForegroundColor Cyan

try {
    # Create server connection
    $server = New-Object Microsoft.AnalysisServices.Tabular.Server
    $server.Connect($xmlaEndpoint)
    
    Write-Host "Connected successfully!" -ForegroundColor Green
    
    # Find the database (semantic model)
    $database = $server.Databases | Where-Object { $_.Name -eq $DatasetName }
    
    if (-not $database) {
        Write-Error "Semantic model '$DatasetName' not found. Available models: $($server.Databases.Name -join ', ')"
        exit 1
    }
    
    Write-Host "Found semantic model: $DatasetName" -ForegroundColor Green
    
    # Get the model
    $model = $database.Model
    
    # Define DAX measures
    $measures = @(
        @{
            Name = "Total Vehicles"
            Expression = "COUNTROWS(fact_vehicle_registration)"
            Table = "fact_vehicle_registration"
            FormatString = "#,0"
            Description = "Total count of registered vehicles"
        },
        @{
            Name = "Avg CO2 Emissions"
            Expression = "AVERAGE(fact_vehicle_emissions[co2_emission])"
            Table = "fact_vehicle_emissions"
            FormatString = "#,0.00"
            Description = "Average CO2 emissions in grams per kilometer"
        },
        @{
            Name = "CO2 Z-Score"
            Expression = @"
VAR AvgCO2 = CALCULATE(AVERAGE(fact_vehicle_emissions[co2_emission]), ALL(fact_vehicle_emissions))
VAR StdDevCO2 = CALCULATE(STDEV.P(fact_vehicle_emissions[co2_emission]), ALL(fact_vehicle_emissions))
RETURN
DIVIDE(AVERAGE(fact_vehicle_emissions[co2_emission]) - AvgCO2, StdDevCO2, BLANK())
"@
            Table = "fact_vehicle_emissions"
            FormatString = "0.00"
            Description = "Z-score for CO2 emissions (>2 or <-2 indicates outlier)"
        },
        @{
            Name = "CO2 Outliers (>2 SD)"
            Expression = @"
CALCULATE(
    COUNTROWS(fact_vehicle_emissions),
    FILTER(
        fact_vehicle_emissions,
        VAR AvgCO2 = CALCULATE(AVERAGE(fact_vehicle_emissions[co2_emission]), ALL(fact_vehicle_emissions))
        VAR StdDevCO2 = CALCULATE(STDEV.P(fact_vehicle_emissions[co2_emission]), ALL(fact_vehicle_emissions))
        VAR ZScore = DIVIDE(fact_vehicle_emissions[co2_emission] - AvgCO2, StdDevCO2, 0)
        RETURN ABS(ZScore) > 2
    )
)
"@
            Table = "fact_vehicle_emissions"
            FormatString = "#,0"
            Description = "Count of vehicles with CO2 emissions more than 2 standard deviations from mean"
        },
        @{
            Name = "Fuel Efficiency Z-Score"
            Expression = @"
VAR AvgEff = CALCULATE(AVERAGE(fact_vehicle_emissions[fuel_efficiency]), ALL(fact_vehicle_emissions))
VAR StdDevEff = CALCULATE(STDEV.P(fact_vehicle_emissions[fuel_efficiency]), ALL(fact_vehicle_emissions))
RETURN
DIVIDE(AVERAGE(fact_vehicle_emissions[fuel_efficiency]) - AvgEff, StdDevEff, BLANK())
"@
            Table = "fact_vehicle_emissions"
            FormatString = "0.00"
            Description = "Z-score for fuel efficiency"
        },
        @{
            Name = "Total Fuel Distribution"
            Expression = "SUM(fact_fuel_distribution[fuel_count])"
            Table = "fact_fuel_distribution"
            FormatString = "#,0"
            Description = "Total number of vehicles in fuel distribution"
        },
        @{
            Name = "Fuel Market Share %"
            Expression = @"
DIVIDE(
    [Total Fuel Distribution],
    CALCULATE([Total Fuel Distribution], ALL(dim_fuel_type)),
    0
) * 100
"@
            Table = "fact_fuel_distribution"
            FormatString = "0.00%"
            Description = "Market share percentage for selected fuel types"
        },
        @{
            Name = "Total Parking Capacity"
            Expression = "SUM(fact_parking_capacity[total_spots])"
            Table = "fact_parking_capacity"
            FormatString = "#,0"
            Description = "Total parking spots across all areas"
        },
        @{
            Name = "Paid Parking %"
            Expression = @"
DIVIDE(
    SUM(fact_parking_capacity[paid_spots]),
    [Total Parking Capacity],
    0
) * 100
"@
            Table = "fact_parking_capacity"
            FormatString = "0.00%"
            Description = "Percentage of parking spots that are paid"
        },
        @{
            Name = "Disabled Parking %"
            Expression = @"
DIVIDE(
    SUM(fact_parking_capacity[disabled_spots]),
    [Total Parking Capacity],
    0
) * 100
"@
            Table = "fact_parking_capacity"
            FormatString = "0.00%"
            Description = "Percentage of parking spots designated for disabled"
        },
        @{
            Name = "P50 Emissions"
            Expression = "PERCENTILE.INC(fact_vehicle_emissions[co2_emission], 0.5)"
            Table = "fact_vehicle_emissions"
            FormatString = "#,0.00"
            Description = "Median (50th percentile) CO2 emissions"
        },
        @{
            Name = "P90 Emissions"
            Expression = "PERCENTILE.INC(fact_vehicle_emissions[co2_emission], 0.9)"
            Table = "fact_vehicle_emissions"
            FormatString = "#,0.00"
            Description = "90th percentile CO2 emissions"
        },
        @{
            Name = "P99 Emissions"
            Expression = "PERCENTILE.INC(fact_vehicle_emissions[co2_emission], 0.99)"
            Table = "fact_vehicle_emissions"
            FormatString = "#,0.00"
            Description = "99th percentile CO2 emissions (high outliers)"
        }
    )
    
    Write-Host "`nAdding $($measures.Count) DAX measures..." -ForegroundColor Cyan
    
    $addedCount = 0
    $skippedCount = 0
    
    foreach ($measureDef in $measures) {
        $tableName = $measureDef.Table
        $table = $model.Tables | Where-Object { $_.Name -eq $tableName }
        
        if (-not $table) {
            Write-Warning "Table '$tableName' not found, skipping measure '$($measureDef.Name)'"
            continue
        }
        
        # Check if measure already exists
        $existingMeasure = $table.Measures | Where-Object { $_.Name -eq $measureDef.Name }
        
        if ($existingMeasure) {
            Write-Host "  ⚠ Measure '$($measureDef.Name)' already exists, skipping..." -ForegroundColor Yellow
            $skippedCount++
            continue
        }
        
        # Create new measure
        $measure = New-Object Microsoft.AnalysisServices.Tabular.Measure
        $measure.Name = $measureDef.Name
        $measure.Expression = $measureDef.Expression
        $measure.FormatString = $measureDef.FormatString
        $measure.Description = $measureDef.Description
        
        $table.Measures.Add($measure)
        
        Write-Host "  ✓ Added measure: $($measureDef.Name)" -ForegroundColor Green
        $addedCount++
    }
    
    # Save changes
    if ($addedCount -gt 0) {
        Write-Host "`nSaving changes to semantic model..." -ForegroundColor Cyan
        $model.SaveChanges()
        Write-Host "✓ Successfully added $addedCount measures!" -ForegroundColor Green
    }
    
    if ($skippedCount -gt 0) {
        Write-Host "⚠ Skipped $skippedCount existing measures" -ForegroundColor Yellow
    }
    
    Write-Host "`nSemantic model updated successfully!" -ForegroundColor Green
    Write-Host "Open the model in Fabric portal to see the new measures." -ForegroundColor Cyan
    
} catch {
    Write-Error "Failed to add measures: $_"
    Write-Host "`nCommon issues:" -ForegroundColor Yellow
    Write-Host "1. Ensure you have Contributor role in the workspace" -ForegroundColor Yellow
    Write-Host "2. Run 'Connect-PowerBIServiceAccount' if not authenticated" -ForegroundColor Yellow
    Write-Host "3. Check that the semantic model name is correct: '$DatasetName'" -ForegroundColor Yellow
} finally {
    if ($server -and $server.Connected) {
        $server.Disconnect()
    }
}
