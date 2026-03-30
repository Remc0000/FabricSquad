# End-to-End Validation Checklist

This checklist helps you verify that your RDW Medallion environment is fully operational.

## ✅ Infrastructure Validation

### Workspaces
- [ ] `RDWAgents` workspace exists and is assigned to trial capacity
- [ ] You have Contributor role in the workspace
- [ ] `RDW - Open Data` workspace is accessible (for source data)

### Lakehouses
- [ ] `RDWAgentsLake` lakehouse exists in RDWAgents workspace
- [ ] Lakehouse is schema-enabled
- [ ] SQL analytics endpoint is accessible

### Schemas
- [ ] `bronze` schema exists (verify via SQL: `SELECT * FROM INFORMATION_SCHEMA.SCHEMATA`)
- [ ] `silver` schema exists
- [ ] `gold` schema exists

### OneLake Shortcuts (Bronze Layer)
- [ ] `bronze.gekentekende_voertuigen` shortcut exists and is queryable
- [ ] `bronze.gekentekende_voertuigen_brandstof` shortcut exists
- [ ] `bronze.brandstoffen_op_pc4` shortcut exists
- [ ] `bronze.parkeeradres` shortcut exists
- [ ] `bronze.specificaties_parkeergebied` shortcut exists

**Verification Command:**
```powershell
fab ls "/RDWAgents/RDWAgentsLake/Tables/bronze"
```

Expected: 5 shortcuts visible

---

## ✅ Silver Layer Validation

### Tables Exist
- [ ] `silver.vehicles` table exists
- [ ] `silver.vehicle_fuels` table exists
- [ ] `silver.fuels_by_postal_code` table exists
- [ ] `silver.parking_addresses` table exists
- [ ] `silver.parking_area_specs` table exists

**Verification Command:**
```powershell
fab ls "/RDWAgents/RDWAgentsLake/Tables/silver"
```

Expected: 5 Delta tables

### Data Quality
Run these queries in the SQL endpoint:

```sql
-- Check row counts (should be non-zero)
SELECT 'vehicles' AS table_name, COUNT(*) AS row_count FROM silver.vehicles
UNION ALL
SELECT 'vehicle_fuels', COUNT(*) FROM silver.vehicle_fuels
UNION ALL
SELECT 'fuels_by_postal_code', COUNT(*) FROM silver.fuels_by_postal_code
UNION ALL
SELECT 'parking_addresses', COUNT(*) FROM silver.parking_addresses
UNION ALL
SELECT 'parking_area_specs', COUNT(*) FROM silver.parking_area_specs;
```

- [ ] All tables have rows (count > 0)

```sql
-- Check for nulls in critical columns
SELECT COUNT(*) AS null_vehicle_ids FROM silver.vehicles WHERE vehicle_id IS NULL;
```

- [ ] No nulls in primary key columns (kenteken, vehicle_id, etc.)

```sql
-- Check date parsing worked
SELECT MIN(registration_date) AS min_date, MAX(registration_date) AS max_date 
FROM silver.vehicles
WHERE registration_date IS NOT NULL;
```

- [ ] Dates are valid (not in year 1900 or 2100, etc.)

---

## ✅ Gold Layer Validation

### Dimension Tables
- [ ] `gold.dim_vehicle` exists with surrogate key `vehicle_key`
- [ ] `gold.dim_fuel_type` exists with surrogate key `fuel_key`
- [ ] `gold.dim_location` exists with surrogate key `location_key`
- [ ] `gold.dim_parking_area` exists with surrogate key `parking_area_key`
- [ ] `gold.dim_date` exists with surrogate key `date_key`

### Fact Tables
- [ ] `gold.fact_vehicle_registration` exists
- [ ] `gold.fact_vehicle_emissions` exists
- [ ] `gold.fact_fuel_distribution` exists
- [ ] `gold.fact_parking_capacity` exists

**Verification Command:**
```powershell
fab ls "/RDWAgents/RDWAgentsLake/Tables/gold"
```

Expected: 9 Delta tables

### Star Schema Integrity

Run these queries to verify foreign key integrity:

```sql
-- Check vehicle keys match
SELECT COUNT(*) AS orphaned_vehicles
FROM gold.fact_vehicle_registration f
LEFT JOIN gold.dim_vehicle d ON f.vehicle_key = d.vehicle_key
WHERE d.vehicle_key IS NULL;
```

- [ ] Orphaned vehicles = 0

```sql
-- Check fuel keys match
SELECT COUNT(*) AS orphaned_fuel_refs
FROM gold.fact_vehicle_registration f
LEFT JOIN gold.dim_fuel_type d ON f.fuel_key = d.fuel_key
WHERE d.fuel_key IS NULL;
```

- [ ] Orphaned fuel refs = 0

```sql
-- Check location keys match
SELECT COUNT(*) AS orphaned_locations
FROM gold.fact_fuel_distribution f
LEFT JOIN gold.dim_location d ON f.location_key = d.location_key
WHERE d.location_key IS NULL;
```

- [ ] Orphaned locations = 0

```sql
-- Check date keys match
SELECT COUNT(*) AS orphaned_dates
FROM gold.fact_vehicle_registration f
LEFT JOIN gold.dim_date d ON f.date_key = d.date_key
WHERE d.date_key IS NULL;
```

- [ ] Orphaned dates = 0

### Grain Verification

```sql
-- Fact grain check: registrations should be unique per vehicle
SELECT vehicle_key, COUNT(*) AS duplicate_count
FROM gold.fact_vehicle_registration
GROUP BY vehicle_key
HAVING COUNT(*) > 1;
```

- [ ] No duplicates in fact_vehicle_registration

```sql
-- Dimension uniqueness: vehicles should be unique by vehicle_key
SELECT vehicle_key, COUNT(*) AS duplicate_count
FROM gold.dim_vehicle
GROUP BY vehicle_key
HAVING COUNT(*) > 1;
```

- [ ] No duplicates in dim_vehicle

---

## ✅ Semantic Model Validation

### Model Structure
- [ ] Semantic model `RDW Analytics` exists in RDWAgents workspace
- [ ] Model is in **Direct Lake** mode (check properties)
- [ ] All 9 Gold tables are included
- [ ] Model has been refreshed at least once (schema imported)

### Relationships
- [ ] 11 relationships configured (4 for registrations, 2 for emissions, 3 for fuel dist, 2 for parking)
- [ ] All relationships are **Many-to-One** (from fact to dimension)
- [ ] All relationships are **Active**
- [ ] Cross-filtering is **Single direction** (fact → dimension)
- [ ] No circular relationship warnings

**Verification (Open Model View):**
- Count relationship lines in diagram
- Check relationship properties (double-click each)

### DAX Measures
- [ ] 13 measures created across tables
- [ ] Vehicle analytics: Total Vehicles, Avg CO2, CO2 Z-Score, Outlier Count
- [ ] Statistical: P50, P90, P99
- [ ] Fuel: Total Fuel Distribution, Fuel Market Share %
- [ ] Parking: Total Capacity, Paid %, Disabled %

**Verification (Measure Test):**
1. Open model → Report view
2. Add a card visual
3. Test each measure:
   - `Total Vehicles` → Should show a large number (e.g., 10M+)
   - `CO2 Outliers (>2 SD)` → Should show a reasonable count (e.g., thousands)
   - `Fuel Market Share %` → Should sum to 100% when all types selected

- [ ] All measures return valid numbers (no errors, no blanks on simple queries)

---

## ✅ Report Validation

### Report Structure
- [ ] Report `RDW Dashboard` (or similar name) exists in RDWAgents workspace
- [ ] Connected to `RDW Analytics` semantic model
- [ ] 5 pages created: Fleet Composition, Emissions Outliers, Geographic Distribution, Parking Infrastructure, Trends

### Visual Functionality
- [ ] All visuals load without errors
- [ ] Slicers filter correctly within page
- [ ] Cross-highlighting works between visuals on same page
- [ ] No (Blank) or "No data" errors (except when filtered to no results)

### Interactivity
- [ ] Click a bar/slice in one visual → other visuals highlight correctly
- [ ] Use slicer → all visuals update immediately
- [ ] Direct Lake performance: pages load in < 5 seconds

### Data Accuracy Spot Checks

**Fleet Composition Page:**
```sql
-- Verify top brand counts match report
SELECT TOP 5 brand_name, COUNT(*) AS vehicle_count
FROM gold.dim_vehicle v
JOIN gold.fact_vehicle_registration f ON v.vehicle_key = f.vehicle_key
GROUP BY brand_name
ORDER BY vehicle_count DESC;
```

- [ ] Top 5 brands in report match SQL query results

**Emissions Outliers Page:**
- [ ] Scatter plot shows reasonable CO2 range (e.g., 0-500 g/km)
- [ ] Outlier table shows vehicles with Z-Score > 2 or < -2
- [ ] KPI cards show non-zero outlier counts

**Geographic Page:**
- [ ] Map shows density variation across regions
- [ ] Province slicer filters correctly
- [ ] Top cities table shows realistic city names

**Parking Page:**
- [ ] Parking capacity numbers seem reasonable (not millions per area)
- [ ] Percentages are between 0-100%
- [ ] Cities with known-large parking appear at top

**Trends Page:**
- [ ] Timeline shows expected date range (based on your data)
- [ ] Fuel adoption shows plausible trends (e.g., EV growth)
- [ ] No abrupt gaps or anomalies (unless real data issues)

---

## ✅ End-to-End Data Flow Test

Run this complete test to verify the entire pipeline:

### Test 1: New Data Update Simulation

1. **Modify source data** (if you have write access to RDW - Open Data):
   - Add a test record to `dbo.gekentekende_voertuigen`

2. **Re-run Bronze-to-Silver**:
   ```powershell
   # Trigger notebook run
   fab api -X post "/workspaces/<workspace-id>/items/<notebook-id>/jobs/instances?jobType=RunNotebook"
   ```

3. **Re-run Silver-to-Gold**:
   - Same command for second notebook

4. **Check report**:
   - Refresh report in Fabric portal OR Power BI Desktop
   - Direct Lake models auto-refresh, so new data should appear immediately
   - Verify your test record appears in Fleet Composition visual

- [ ] Test record flows from Bronze → Silver → Gold → Report

### Test 2: Outlier Detection Accuracy

1. Find a vehicle with known high CO2 (e.g., large SUV or truck)
2. Verify it appears in **Emissions Outliers** page
3. Check Z-Score calculation is reasonable (>2 for high emissions)

- [ ] Outlier detection logic works correctly

### Test 3: Geographic Filtering

1. Go to **Geographic Distribution** page
2. Select a specific province (e.g., "Utrecht")
3. Verify all visuals filter to that province only
4. Check that vehicle counts match SQL query:
   ```sql
   SELECT COUNT(*) FROM gold.fact_vehicle_registration f
   JOIN gold.dim_location l ON f.location_key = l.location_key
   WHERE l.province = 'Utrecht';
   ```

- [ ] Geographic filters work end-to-end

---

## ✅ Documentation Validation

- [ ] `semantic-model/README.md` exists with model creation guide
- [ ] `semantic-model/RELATIONSHIPS.md` documents all 11 relationships
- [ ] `semantic-model/add-dax-measures.ps1` script is runnable
- [ ] `semantic-model/configure-relationships.ps1` script is runnable
- [ ] `reports/README.md` exists with detailed report page designs
- [ ] `WORKSHOP.md` updated with Part 10 (semantic model & reports)
- [ ] `tasks.md` has all tasks 1.1-5.7 checked off

---

## ✅ Performance Validation

### Direct Lake Benefits

1. Open semantic model → **Settings** → **Server settings**
2. Verify mode is **Direct Lake**
3. Check storage mode for tables (should say "Direct Lake" not "Import" or "DirectQuery")

- [ ] All tables are in Direct Lake mode

### Query Performance

1. Open report in Fabric portal
2. Use browser dev tools (F12) → Network tab
3. Interact with visuals (click, filter, etc.)
4. Check query response times

- [ ] Most queries complete in < 2 seconds
- [ ] No timeout errors

### Capacity Utilization

1. In Fabric portal → **Monitoring** → **Capacity metrics**
2. Check CPU and memory usage during report interactions

- [ ] Capacity usage stays within reasonable limits (< 80%)

---

## ✅ Security & Permissions Validation

- [ ] Service principal has appropriate roles (if used)
- [ ] Workspace admins/contributors are set correctly
- [ ] Report viewers have read-only access
- [ ] Lakehouse permissions are correctly scoped (bronze/silver/gold schema isolation)

---

## 🎉 Completion Criteria

Your RDW Medallion environment is **fully operational** when:

1. ✅ All 5 Bronze shortcuts are accessible
2. ✅ All 5 Silver tables contain cleansed data
3. ✅ All 9 Gold tables follow star schema design
4. ✅ Semantic model has 11 relationships and 13 DAX measures
5. ✅ Report has 5 functional pages with accurate visuals
6. ✅ End-to-end test succeeds (new data flows through)
7. ✅ Performance is acceptable (queries < 5 seconds)

---

## Common Issues & Fixes

### Issue: "Report shows no data"
**Symptoms:** All visuals empty, no errors
**Check:**
1. Semantic model refresh status → refresh if stale
2. Relationships configured → verify in model view
3. Gold tables have data → run SQL count queries

### Issue: "Semantic model won't refresh"
**Symptoms:** Refresh fails with error
**Check:**
1. Lakehouse exists and is accessible
2. Gold tables have compatible schemas (no unsupported data types)
3. Direct Lake requirements met (capacity SKU, lakehouse format)

### Issue: "Outlier measures return BLANK()"
**Symptoms:** Z-Score and outlier count measures show blank
**Check:**
1. Relationships between facts and dimensions configured
2. `fact_vehicle_emissions` table has data
3. `co2_emission` column is numeric (not string)

### Issue: "Cannot create semantic model"
**Symptoms:** "Create semantic model" button disabled or grayed out
**Check:**
1. Workspace is assigned to a Fabric capacity (trial or paid)
2. You have Contributor or Admin role in workspace
3. SQL endpoint is enabled for the lakehouse

### Issue: "Relationships auto-detect failed"
**Symptoms:** No relationships suggested when creating model
**Check:**
1. Key columns have matching names (_key suffix)
2. Key columns have same data type (INT)
3. Foreign keys actually exist in fact tables

---

## Performance Benchmarks

Expected performance for reference:

| Operation | Expected Duration |
|-----------|-------------------|
| Bronze-to-Silver notebook | 5-10 minutes |
| Silver-to-Gold notebook | 5-10 minutes |
| Semantic model creation | < 1 minute |
| Relationship configuration | 5 minutes (manual) |
| DAX measure creation | 10 minutes (manual) OR < 1 minute (script) |
| Report page creation | 5 minutes per page |
| Report load time (Direct Lake) | < 5 seconds per page |
| Visual interaction (slicer/filter) | < 2 seconds |

---

## Data Volume Expectations

For RDW Open Data (approximate):

| Layer | Tables | Total Rows | Storage |
|-------|--------|------------|---------|
| Bronze | 5 shortcuts | ~10-20M | 0 bytes (shortcut) |
| Silver | 5 tables | ~10-20M | 2-5 GB |
| Gold | 9 tables | ~10-20M | 3-6 GB |

> **Note:** Exact numbers depend on the source data refresh date and coverage

---

## Automated Validation Script

For CI/CD or automated validation, use this PowerShell script:

```powershell
# validate-environment.ps1

$workspaceId = "97b7e768-c5d2-4501-9af2-29b37be6c83c"
$lakehouseId = "ac035351-73d1-4297-bfbd-6ea91e63eeba"

# Test 1: List Bronze shortcuts
Write-Host "Testing Bronze shortcuts..." -ForegroundColor Cyan
$bronzeResult = fab ls "/RDWAgents/RDWAgentsLake/Tables/bronze" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Bronze layer accessible" -ForegroundColor Green
} else {
    Write-Error "✗ Bronze layer failed"
}

# Test 2: List Silver tables
Write-Host "Testing Silver tables..." -ForegroundColor Cyan
$silverResult = fab ls "/RDWAgents/RDWAgentsLake/Tables/silver" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Silver layer accessible" -ForegroundColor Green
} else {
    Write-Error "✗ Silver layer failed"
}

# Test 3: List Gold tables
Write-Host "Testing Gold tables..." -ForegroundColor Cyan
$goldResult = fab ls "/RDWAgents/RDWAgentsLake/Tables/gold" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Gold layer accessible" -ForegroundColor Green
} else {
    Write-Error "✗ Gold layer failed"
}

# Test 4: Check semantic model exists
Write-Host "Testing semantic model..." -ForegroundColor Cyan
$items = fab api -X get "workspaces/$workspaceId/items?type=SemanticModel" | ConvertFrom-Json
$model = $items.value | Where-Object { $_.displayName -eq "RDW Analytics" }
if ($model) {
    Write-Host "✓ Semantic model found: $($model.id)" -ForegroundColor Green
} else {
    Write-Error "✗ Semantic model not found"
}

# Test 5: Check reports exist
Write-Host "Testing reports..." -ForegroundColor Cyan
$reports = fab api -X get "workspaces/$workspaceId/items?type=Report" | ConvertFrom-Json
if ($reports.value.Count -gt 0) {
    Write-Host "✓ Found $($reports.value.Count) report(s)" -ForegroundColor Green
} else {
    Write-Warning "⚠ No reports found"
}

Write-Host "`n🎉 Validation complete!" -ForegroundColor Green
```

Save as `validation\validate-environment.ps1`

---

## Next Steps After Validation

Once all checks pass:

1. **Celebrate!** 🎉 You've built a complete medallion architecture
2. **Create snapshots** of your workspace for workshop reuse
3. **Document any customizations** you made beyond the base spec
4. **Test workshop delivery** with a colleague or friend
5. **Gather feedback** and iterate on the instructions

---

## Getting Help

If validation fails at any step:

1. Check relevant section in `WORKSHOP.md`
2. Review notebook outputs for errors
3. Check Fabric portal monitoring for failures
4. Search Microsoft Learn docs for specific error messages
5. Use Fabric Copilot in VS Code for debugging

**Resources:**
- Fabric docs: https://learn.microsoft.com/fabric/
- Direct Lake guide: https://learn.microsoft.com/power-bi/enterprise/directlake-overview
- Star schema design: https://learn.microsoft.com/power-bi/guidance/star-schema
