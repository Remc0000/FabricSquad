# Automated Environment Validation Script
# Verifies that RDW Medallion environment is fully operational

param(
    [string]$WorkspaceId = "97b7e768-c5d2-4501-9af2-29b37be6c83c",
    [string]$WorkspaceName = "RDWAgents",
    [string]$LakehouseName = "RDWAgentsLake",
    [string]$SemanticModelName = "RDW Analytics"
)

$ErrorActionPreference = "Continue"
$passCount = 0
$failCount = 0
$warnCount = 0

function Test-Step {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [switch]$Optional
    )
    
    Write-Host "`nTesting: $Name" -ForegroundColor Cyan
    
    try {
        $result = & $Test
        if ($result -eq $true) {
            Write-Host "  ✓ PASS" -ForegroundColor Green
            $script:passCount++
            return $true
        } else {
            if ($Optional) {
                Write-Host "  ⚠ WARN (optional check)" -ForegroundColor Yellow
                $script:warnCount++
            } else {
                Write-Host "  ✗ FAIL" -ForegroundColor Red
                $script:failCount++
            }
            return $false
        }
    } catch {
        if ($Optional) {
            Write-Host "  ⚠ WARN: $_" -ForegroundColor Yellow
            $script:warnCount++
        } else {
            Write-Host "  ✗ FAIL: $_" -ForegroundColor Red
            $script:failCount++
        }
        return $false
    }
}

Write-Host "========================================" -ForegroundColor Magenta
Write-Host " RDW Medallion Environment Validation" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

# Test 1: fab CLI available
Test-Step "fab CLI installed" -Test {
    $fabPath = Get-Command fab -ErrorAction SilentlyContinue
    if ($fabPath) {
        Write-Host "    Found: $($fabPath.Source)" -ForegroundColor Gray
        return $true
    }
    return $false
}

# Test 2: Authentication
Test-Step "fab CLI authenticated" -Test {
    $authStatus = fab auth status 2>&1 | Out-String
    if ($authStatus -match "Authenticated|Logged in") {
        return $true
    }
    Write-Host "    Run: fab auth login" -ForegroundColor Yellow
    return $false
}

# Test 3: Workspace exists
Test-Step "RDWAgents workspace exists" -Test {
    $workspaces = fab api -X get "workspaces" | ConvertFrom-Json
    $workspace = $workspaces.value | Where-Object { $_.id -eq $WorkspaceId -or $_.displayName -eq $WorkspaceName }
    if ($workspace) {
        Write-Host "    Workspace ID: $($workspace.id)" -ForegroundColor Gray
        return $true
    }
    return $false
}

# Test 4: Lakehouse exists
Test-Step "RDWAgentsLake lakehouse exists" -Test {
    $lakehouses = fab api -X get "workspaces/$WorkspaceId/items?type=Lakehouse" | ConvertFrom-Json
    $lakehouse = $lakehouses.value | Where-Object { $_.displayName -eq $LakehouseName }
    if ($lakehouse) {
        Write-Host "    Lakehouse ID: $($lakehouse.id)" -ForegroundColor Gray
        $script:lakehouseId = $lakehouse.id
        return $true
    }
    return $false
}

# Test 5: Bronze shortcuts
Test-Step "Bronze shortcuts (5 expected)" -Test {
    $shortcuts = fab api -X get "workspaces/$WorkspaceId/lakehouses/$script:lakehouseId/shortcuts?path=Tables/bronze" 2>&1 | ConvertFrom-Json
    if ($shortcuts.value.Count -eq 5) {
        Write-Host "    Found $($shortcuts.value.Count) shortcuts" -ForegroundColor Gray
        return $true
    }
    Write-Host "    Found $($shortcuts.value.Count)/5 shortcuts" -ForegroundColor Yellow
    return $false
}

# Test 6: Silver tables
Test-Step "Silver tables (5 expected)" -Test {
    $result = fab ls "/$WorkspaceName/$LakehouseName/Tables/silver" 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0 -and $result) {
        # Count lines (approximate table count)
        $lineCount = ($result -split "`n" | Where-Object { $_ -match "\.delta$" }).Count
        Write-Host "    Found ~$lineCount tables" -ForegroundColor Gray
        return $lineCount -ge 5
    }
    return $false
}

# Test 7: Gold tables
Test-Step "Gold tables (9 expected)" -Test {
    $result = fab ls "/$WorkspaceName/$LakehouseName/Tables/gold" 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0 -and $result) {
        $lineCount = ($result -split "`n" | Where-Object { $_ -match "\.delta$" }).Count
        Write-Host "    Found ~$lineCount tables" -ForegroundColor Gray
        return $lineCount -ge 9
    }
    return $false
}

# Test 8: Semantic model exists
Test-Step "Semantic model exists" -Test {
    $models = fab api -X get "workspaces/$WorkspaceId/items?type=SemanticModel" 2>&1 | ConvertFrom-Json
    $model = $models.value | Where-Object { $_.displayName -eq $SemanticModelName }
    if ($model) {
        Write-Host "    Model ID: $($model.id)" -ForegroundColor Gray
        return $true
    }
    return $false
}

# Test 9: Reports exist
Test-Step "Reports exist (at least 1 expected)" -Optional -Test {
    $reports = fab api -X get "workspaces/$WorkspaceId/items?type=Report" 2>&1 | ConvertFrom-Json
    if ($reports.value.Count -gt 0) {
        Write-Host "    Found $($reports.value.Count) report(s)" -ForegroundColor Gray
        foreach ($report in $reports.value) {
            Write-Host "      - $($report.displayName)" -ForegroundColor Gray
        }
        return $true
    }
    Write-Host "    No reports found (optional)" -ForegroundColor Yellow
    return $false
}

# Test 10: Notebooks exist
Test-Step "Notebooks exist (2 expected)" -Test {
    $notebooks = fab api -X get "workspaces/$WorkspaceId/items?type=Notebook" 2>&1 | ConvertFrom-Json
    if ($notebooks.value.Count -ge 2) {
        Write-Host "    Found $($notebooks.value.Count) notebook(s)" -ForegroundColor Gray
        foreach ($nb in $notebooks.value) {
            Write-Host "      - $($nb.displayName)" -ForegroundColor Gray
        }
        return $true
    }
    Write-Host "    Found $($notebooks.value.Count)/2 notebooks" -ForegroundColor Yellow
    return $false
}

# Summary
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "           Validation Summary" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "PASSED:  $passCount tests" -ForegroundColor Green
Write-Host "FAILED:  $failCount tests" -ForegroundColor Red
Write-Host "WARNED:  $warnCount tests" -ForegroundColor Yellow

if ($failCount -eq 0) {
    Write-Host "`n🎉 Environment is fully operational!" -ForegroundColor Green
    Write-Host "All critical components validated successfully." -ForegroundColor Green
    exit 0
} elseif ($failCount -le 2) {
    Write-Host "`n⚠ Environment is mostly operational with minor issues." -ForegroundColor Yellow
    Write-Host "Review failed tests above and fix before workshop delivery." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "`n❌ Environment has critical issues." -ForegroundColor Red
    Write-Host "Please fix failed tests before proceeding." -ForegroundColor Red
    exit 2
}
