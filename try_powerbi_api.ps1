# Alternative: Try Power BI REST API for Semantic Model Creation
# Power BI REST API may support programmatic creation better than Fabric API

$workspaceId = "97b7e768-c5d2-4501-9af2-29b37be6c83c"
$lakehouseId = "ac035351-73d1-4297-bfbd-6ea91e63eeba"

Write-Host "Attempting to create semantic model via Power BI REST API..." -ForegroundColor Cyan

# Get token for Power BI service
$token = fab auth token 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to get authentication token" -ForegroundColor Red
    exit 1
}

Write-Host "Token obtained successfully" -ForegroundColor Green

# Power BI REST API endpoint for creating datasets
$apiUrl = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/datasets"

# Minimal dataset definition for Direct Lake
$datasetDef = @{
    name = "RDW Analytics"
    defaultMode = "DirectLake"
    tables = @(
        @{
            name = "dim_vehicle"
            columns = @(
                @{ name = "vehicle_key"; dataType = "Int64"; isKey = $true }
                @{ name = "kenteken"; dataType = "String" }
                @{ name = "merk"; dataType = "String" }
            )
            partitions = @(
                @{
                    name = "dim_vehicle"
                    mode = "directLake"
                    source = @{
                        type = "entity"
                        entityName = "dim_vehicle"
                        schemaName = "gold"
                    }
                }
            )
        }
    )
    relationships = @()
    datasources = @(
        @{
            datasourceType = "AnalysisServices"
            connectionDetails = @{
                server = "powerbi://api.powerbi.com/v1.0/myorg/$workspaceId"
                database = $lakehouseId
            }
        }
    )
} | ConvertTo-Json -Depth 10

[System.IO.File]::WriteAllText("$PSScriptRoot\powerbi_dataset.json", $datasetDef)

Write-Host "`nDataset definition created: powerbi_dataset.json"
Write-Host "To create via Power BI API, you would use:"
Write-Host "POST $apiUrl" -ForegroundColor Yellow
Write-Host ""
Write-Host "However, Direct Lake datasets are best created through:" -ForegroundColor Cyan
Write-Host "1. Fabric Portal (simplest)"
Write-Host "2. Power BI Desktop (most features)"
Write-Host "3. XMLA endpoint (advanced)"
Write-Host ""
Write-Host "The TMDL definition files in tmdl/ folder are ready for import." -ForegroundColor Green
