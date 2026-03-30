# Create RDW Analytics Semantic Model via XMLA Endpoint
# This script creates a Direct Lake semantic model programmatically

param(
    [string]$WorkspaceName = "RDWAgents",
    [string]$WorkspaceId = "97b7e768-c5d2-4501-9af2-29b37be6c83c",
    [string]$LakehouseId = "ac035351-73d1-4297-bfbd-6ea91e63eeba",
    [string]$DatasetName = "RDW Analytics",
    [string]$SqlEndpoint = "i3okznlkvxhe3fmmjrbk74yk3i-ndt3pf6syuaulgxsfgzxxzwihq.datawarehouse.fabric.microsoft.com"
)

# Check if module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.AnalysisServices.Administration)) {
    Write-Host "Installing Microsoft.AnalysisServices.Administration module..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.AnalysisServices.Administration -Scope CurrentUser -Force
}

Import-Module Microsoft.AnalysisServices.Administration

# XMLA endpoint URL
$xmlaEndpoint = "powerbi://api.powerbi.com/v1.0/myorg/$WorkspaceName"

Write-Host "Connecting to XMLA endpoint: $xmlaEndpoint" -ForegroundColor Cyan

try {
    # Create server connection
    $server = New-Object Microsoft.AnalysisServices.Tabular.Server
    $server.Connect($xmlaEndpoint)
    
    Write-Host "Connected successfully!" -ForegroundColor Green
    
    # Check if database already exists
    $existingDb = $server.Databases | Where-Object { $_.Name -eq $DatasetName }
    
    if ($existingDb) {
        Write-Host "⚠ Semantic model '$DatasetName' already exists!" -ForegroundColor Yellow
        $answer = Read-Host "Do you want to delete and recreate it? (yes/no)"
        
        if ($answer -eq "yes") {
            Write-Host "Deleting existing model..." -ForegroundColor Yellow
            $existingDb.Drop()
            Write-Host "✓ Deleted" -ForegroundColor Green
        } else {
            Write-Host "Exiting without changes." -ForegroundColor Yellow
            exit 0
        }
    }
    
    # Create new database
    Write-Host "`nCreating new semantic model..." -ForegroundColor Cyan
    
    $database = New-Object Microsoft.AnalysisServices.Tabular.Database
    $database.Name = $DatasetName
    $database.CompatibilityLevel = 1605  # Latest compatibility level
    
    $model = New-Object Microsoft.AnalysisServices.Tabular.Model
    $model.Name = $DatasetName
    $model.Culture = "en-US"
    
    $database.Model = $model
    
    # Create Direct Lake connection
    $expression = New-Object Microsoft.AnalysisServices.Tabular.NamedExpression
    $expression.Name = "DatabaseQuery"
    $expression.Description = "Direct Lake connection to RDWAgentsLake"
    
    # Connection string for Direct Lake
    $connectionString = @"
Provider=Microsoft.PowerBI.DirectLake;
Data Source=`$`$`$powerbi.dataSource;
Initial Catalog=`$`$`$powerbi.database;
DatabaseQuery=lakehouse-$LakehouseId
"@
    
    $expression.Expression = $connectionString
    
    $model.Expressions.Add($expression)
    
    # Define tables (simplified - you'll add columns via TMSL or manually)
    $tables = @(
        @{ Name = "dim_vehicle"; Schema = "gold" },
        @{ Name = "dim_fuel_type"; Schema = "gold" },
        @{ Name = "dim_location"; Schema = "gold" },
        @{ Name = "dim_parking_area"; Schema = "gold" },
        @{ Name = "dim_date"; Schema = "gold" },
        @{ Name = "fact_vehicle_registration"; Schema = "gold" },
        @{ Name = "fact_vehicle_emissions"; Schema = "gold" },
        @{ Name = "fact_fuel_distribution"; Schema = "gold" },
        @{ Name = "fact_parking_capacity"; Schema = "gold" }
    )
    
    Write-Host "Adding tables..." -ForegroundColor Cyan
    
    foreach ($tableDef in $tables) {
        $table = New-Object Microsoft.AnalysisServices.Tabular.Table
        $table.Name = $tableDef.Name
        
        # Create partition with Direct Lake mode
        $partition = New-Object Microsoft.AnalysisServices.Tabular.Partition
        $partition.Name = "$($tableDef.Name)_Partition"
        $partition.Mode = [Microsoft.AnalysisServices.Tabular.ModeType]::DirectLake
        
        # Direct Lake partition references the lakehouse table
        $source = New-Object Microsoft.AnalysisServices.Tabular.EntityPartitionSource
        $source.EntityName = "$($tableDef.Schema).$($tableDef.Name)"
        $source.ExpressionSource = $expression
        
        $partition.Source = $source
        $table.Partitions.Add($partition)
        
        $model.Tables.Add($table)
        
        Write-Host "  ✓ Added table: $($tableDef.Name)" -ForegroundColor Green
    }
    
    # Add database to server
    Write-Host "`nDeploying semantic model to Fabric..." -ForegroundColor Cyan
    $server.Databases.Add($database)
    $database.Update([Microsoft.AnalysisServices.UpdateOptions]::ExpandFull)
    
    Write-Host "✓ Semantic model created successfully!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Open the semantic model in Fabric portal" -ForegroundColor White
    Write-Host "2. Refresh the model to pull schema from lakehouse" -ForegroundColor White
    Write-Host "3. Configure relationships between tables" -ForegroundColor White
    Write-Host "4. Run .\add-dax-measures.ps1 to add calculated measures" -ForegroundColor White
    
} catch {
    Write-Error "Failed to create semantic model: $_"
    Write-Host "`nCommon issues:" -ForegroundColor Yellow
    Write-Host "1. Ensure you're authenticated: Connect-PowerBIServiceAccount" -ForegroundColor Yellow
    Write-Host "2. Ensure you have Contributor role in the workspace" -ForegroundColor Yellow
    Write-Host "3. Ensure the lakehouse ID is correct: $LakehouseId" -ForegroundColor Yellow
    Write-Host "4. Check that Gold tables exist in the lakehouse" -ForegroundColor Yellow
} finally {
    if ($server -and $server.Connected) {
        $server.Disconnect()
    }
}
