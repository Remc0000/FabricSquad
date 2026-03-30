# Configure Relationships in RDW Analytics Semantic Model
# Uses TMSL (Tabular Model Scripting Language) via XMLA endpoint

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

# XMLA endpoint
$xmlaEndpoint = "powerbi://api.powerbi.com/v1.0/myorg/$WorkspaceName"

Write-Host "Connecting to XMLA endpoint: $xmlaEndpoint" -ForegroundColor Cyan

try {
    $server = New-Object Microsoft.AnalysisServices.Tabular.Server
    $server.Connect($xmlaEndpoint)
    
    Write-Host "Connected successfully!" -ForegroundColor Green
    
    # Find the database
    $database = $server.Databases | Where-Object { $_.Name -eq $DatasetName }
    
    if (-not $database) {
        Write-Error "Semantic model '$DatasetName' not found."
        exit 1
    }
    
    $model = $database.Model
    
    # Define relationships (star schema)
    $relationships = @(
        # fact_vehicle_registration relationships
        @{
            Name = "rel_fact_vehicle_registration_dim_vehicle"
            FromTable = "fact_vehicle_registration"
            FromColumn = "vehicle_key"
            ToTable = "dim_vehicle"
            ToColumn = "vehicle_key"
        },
        @{
            Name = "rel_fact_vehicle_registration_dim_fuel_type"
            FromTable = "fact_vehicle_registration"
            FromColumn = "fuel_key"
            ToTable = "dim_fuel_type"
            ToColumn = "fuel_key"
        },
        @{
            Name = "rel_fact_vehicle_registration_dim_location"
            FromTable = "fact_vehicle_registration"
            FromColumn = "location_key"
            ToTable = "dim_location"
            ToColumn = "location_key"
        },
        @{
            Name = "rel_fact_vehicle_registration_dim_date"
            FromTable = "fact_vehicle_registration"
            FromColumn = "date_key"
            ToTable = "dim_date"
            ToColumn = "date_key"
        },
        # fact_vehicle_emissions relationships
        @{
            Name = "rel_fact_vehicle_emissions_dim_vehicle"
            FromTable = "fact_vehicle_emissions"
            FromColumn = "vehicle_key"
            ToTable = "dim_vehicle"
            ToColumn = "vehicle_key"
        },
        @{
            Name = "rel_fact_vehicle_emissions_dim_fuel_type"
            FromTable = "fact_vehicle_emissions"
            FromColumn = "fuel_key"
            ToTable = "dim_fuel_type"
            ToColumn = "fuel_key"
        },
        # fact_fuel_distribution relationships
        @{
            Name = "rel_fact_fuel_distribution_dim_fuel_type"
            FromTable = "fact_fuel_distribution"
            FromColumn = "fuel_key"
            ToTable = "dim_fuel_type"
            ToColumn = "fuel_key"
        },
        @{
            Name = "rel_fact_fuel_distribution_dim_location"
            FromTable = "fact_fuel_distribution"
            FromColumn = "location_key"
            ToTable = "dim_location"
            ToColumn = "location_key"
        },
        @{
            Name = "rel_fact_fuel_distribution_dim_date"
            FromTable = "fact_fuel_distribution"
            FromColumn = "date_key"
            ToTable = "dim_date"
            ToColumn = "date_key"
        },
        # fact_parking_capacity relationships
        @{
            Name = "rel_fact_parking_capacity_dim_parking_area"
            FromTable = "fact_parking_capacity"
            FromColumn = "parking_area_key"
            ToTable = "dim_parking_area"
            ToColumn = "parking_area_key"
        },
        @{
            Name = "rel_fact_parking_capacity_dim_location"
            FromTable = "fact_parking_capacity"
            FromColumn = "location_key"
            ToTable = "dim_location"
            ToColumn = "location_key"
        }
    )
    
    Write-Host "`nAdding $($relationships.Count) relationships..." -ForegroundColor Cyan
    
    $addedCount = 0
    $skippedCount = 0
    
    foreach ($relDef in $relationships) {
        # Check if relationship already exists
        $existingRel = $model.Relationships | Where-Object { $_.Name -eq $relDef.Name }
        
        if ($existingRel) {
            Write-Host "  ⚠ Relationship '$($relDef.Name)' already exists, skipping..." -ForegroundColor Yellow
            $skippedCount++
            continue
        }
        
        # Get tables and columns
        $fromTable = $model.Tables | Where-Object { $_.Name -eq $relDef.FromTable }
        $toTable = $model.Tables | Where-Object { $_.Name -eq $relDef.ToTable }
        
        if (-not $fromTable) {
            Write-Warning "FromTable '$($relDef.FromTable)' not found, skipping relationship"
            continue
        }
        
        if (-not $toTable) {
            Write-Warning "ToTable '$($relDef.ToTable)' not found, skipping relationship"
            continue
        }
        
        $fromColumn = $fromTable.Columns | Where-Object { $_.Name -eq $relDef.FromColumn }
        $toColumn = $toTable.Columns | Where-Object { $_.Name -eq $relDef.ToColumn }
        
        if (-not $fromColumn) {
            Write-Warning "FromColumn '$($relDef.FromColumn)' not found in table '$($relDef.FromTable)', skipping"
            continue
        }
        
        if (-not $toColumn) {
            Write-Warning "ToColumn '$($relDef.ToColumn)' not found in table '$($relDef.ToTable)', skipping"
            continue
        }
        
        # Create relationship
        $relationship = New-Object Microsoft.AnalysisServices.Tabular.SingleColumnRelationship
        $relationship.Name = $relDef.Name
        $relationship.FromColumn = $fromColumn
        $relationship.ToColumn = $toColumn
        $relationship.FromCardinality = [Microsoft.AnalysisServices.Tabular.RelationshipEndCardinality]::Many
        $relationship.ToCardinality = [Microsoft.AnalysisServices.Tabular.RelationshipEndCardinality]::One
        $relationship.CrossFilteringBehavior = [Microsoft.AnalysisServices.Tabular.CrossFilteringBehavior]::OneDirection
        $relationship.IsActive = $true
        
        $model.Relationships.Add($relationship)
        
        Write-Host "  ✓ Added relationship: $($relDef.FromTable).$($relDef.FromColumn) → $($relDef.ToTable).$($relDef.ToColumn)" -ForegroundColor Green
        $addedCount++
    }
    
    # Save changes
    if ($addedCount -gt 0) {
        Write-Host "`nSaving changes to semantic model..." -ForegroundColor Cyan
        $model.SaveChanges()
        Write-Host "✓ Successfully added $addedCount relationships!" -ForegroundColor Green
    }
    
    if ($skippedCount -gt 0) {
        Write-Host "⚠ Skipped $skippedCount existing relationships" -ForegroundColor Yellow
    }
    
    Write-Host "`nRelationships configured successfully!" -ForegroundColor Green
    Write-Host "Next: Run .\add-dax-measures.ps1 to add calculated measures" -ForegroundColor Cyan
    
} catch {
    Write-Error "Failed to configure relationships: $_"
    Write-Host "`nCommon issues:" -ForegroundColor Yellow
    Write-Host "1. Ensure semantic model exists first" -ForegroundColor Yellow
    Write-Host "2. Ensure semantic model has been refreshed (schema imported)" -ForegroundColor Yellow
    Write-Host "3. Check column names match exactly (case-sensitive)" -ForegroundColor Yellow
} finally {
    if ($server -and $server.Connected) {
        $server.Disconnect()
    }
}
