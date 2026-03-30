# Validation Tools

This folder contains tools for validating your RDW Medallion environment.

## Quick Validation

Run the automated validation script:

```powershell
.\validate-environment.ps1
```

This will check:
- ✅ fab CLI installed and authenticated
- ✅ RDWAgents workspace and lakehouse exist
- ✅ Bronze shortcuts (5 expected)
- ✅ Silver tables (5 expected)
- ✅ Gold tables (9 expected)
- ✅ Semantic model exists
- ✅ Notebooks exist (2 expected)
- ⚠️ Reports exist (optional)

**Exit codes:**
- `0` - All critical tests passed
- `1` - Minor issues (warnings only)
- `2` - Critical failures

---

## Manual Validation

For detailed step-by-step validation, follow:

📖 **[VALIDATION-CHECKLIST.md](VALIDATION-CHECKLIST.md)**

This comprehensive checklist covers:
- Infrastructure validation
- Data quality checks (row counts, nulls, date parsing)
- Star schema integrity (foreign key validation)
- Semantic model structure (relationships, measures)
- Report functionality (visuals, interactivity, performance)
- End-to-end data flow testing

---

## Troubleshooting Failed Tests

### Test: "fab CLI authenticated" fails
**Fix:**
```powershell
fab auth login
```
Choose authentication method (user or service principal)

### Test: "Bronze shortcuts (5 expected)" fails
**Fix:**
Re-run shortcut creation:
```powershell
cd c:\Projects\FabricSquad\infrastructure
.\create-shortcuts.ps1
```

### Test: "Silver tables (5 expected)" fails
**Fix:**
Re-run Bronze-to-Silver notebook:
```powershell
# Get notebook ID
$notebooks = fab api -X get "workspaces/97b7e768-c5d2-4501-9af2-29b37be6c83c/items?type=Notebook" | ConvertFrom-Json
$nb1 = $notebooks.value | Where-Object { $_.displayName -eq "01_bronze_to_silver" }

# Run notebook
fab api -X post "workspaces/97b7e768-c5d2-4501-9af2-29b37be6c83c/items/$($nb1.id)/jobs/instances?jobType=RunNotebook"
```

### Test: "Gold tables (9 expected)" fails
**Fix:**
Re-run Silver-to-Gold notebook (same approach as above, use notebook ID for `02_silver_to_gold`)

### Test: "Semantic model exists" fails
**Fix:**
Follow instructions in `semantic-model/README.md` to create the model via Fabric portal

---

## CI/CD Integration

For automated pipeline validation, export and import the scripts:

```powershell
# Add to your pipeline
.\validation\validate-environment.ps1
if ($LASTEXITCODE -ne 0) {
    throw "Environment validation failed"
}
```

Or use as a GitHub Actions workflow:

```yaml
name: Validate Fabric Environment
on: [push, pull_request]
jobs:
  validate:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install fab CLI
        run: uv tool install ms-fabric-cli
      - name: Authenticate
        run: fab auth login --service-principal --client-id ${{ secrets.SPN_CLIENT_ID }} --client-secret ${{ secrets.SPN_SECRET }} --tenant-id ${{ secrets.TENANT_ID }}
      - name: Run validation
        run: .\validation\validate-environment.ps1
```

---

## Workshop Usage

Before each workshop session:

1. Run `validate-environment.ps1` to ensure environment is ready
2. If any tests fail, fix before workshop starts
3. Take note of row counts and table stats for reference during workshop
4. Optionally, reset environment to clean state (delete Silver/Gold tables, re-run notebooks)

During workshop:

1. Demonstrate the validation script at the beginning
2. Run validation again after each major step (Bronze, Silver, Gold)
3. Use validation results to show participants their progress

After workshop:

1. Run validation to confirm all participants completed successfully
2. Use results to identify common issues for next workshop iteration

---

## Performance Benchmarks

Expected execution times on typical hardware:

| Test | Expected Duration |
|------|-------------------|
| fab CLI checks | < 1 second |
| API calls (workspace, items) | 1-3 seconds each |
| `fab ls` operations | 3-10 seconds each (terminal rendering) |
| Full validation suite | 20-40 seconds |

If tests take significantly longer, check:
- Network connectivity to Fabric APIs
- Capacity load (if trial capacity is oversubscribed)
- `fab` CLI version (update if outdated)

---

## Extending Validation

To add custom tests:

```powershell
# Example: Check for specific Gold table
Test-Step "fact_vehicle_registration exists" -Test {
    $result = fab ls "/$WorkspaceName/$LakehouseName/Tables/gold/fact_vehicle_registration" 2>&1 | Out-String
    return $LASTEXITCODE -eq 0
}
```

Add your custom tests to `validate-environment.ps1` or create a separate script: `validate-custom.ps1`
