# Star Schema Relationships for RDW Analytics

This document defines all relationships in the semantic model to create a proper star schema.

## Relationship Principles

- **Many-to-One** cardinality: Facts (many) → Dimensions (one)
- **Single direction** cross-filtering: From facts to dimensions only
- **Active** relationships: All relationships should be active
- **Key matching**: Surrogate keys (vehicle_key, date_key, etc.) link facts to dimensions

---

## Relationship Overview

```
                    ┌──────────────┐
                    │  dim_vehicle │
                    └──────────────┘
                           ↑
                           │ vehicle_key
         ┌─────────────────┼─────────────────┐
         │                 │                 │
┌────────────────────┐     │     ┌──────────────────────┐
│ fact_vehicle_      │─────┘     │ fact_vehicle_        │
│ registration       │           │ emissions            │
└────────────────────┘           └──────────────────────┘
         │                                  │
         │ fuel_key                        │ fuel_key
         │                                  │
         ↓                                  ↓
    ┌──────────────┐                  ┌────────┘
    │ dim_fuel_type│←─────────────────┘
    └──────────────┘       │
              ↑            │ fuel_key
              │            │
              │      ┌─────────────────────┐
              │      │ fact_fuel_          │
              └──────│ distribution        │
                     └─────────────────────┘
                           │
                           │ location_key
                           ↓
                     ┌──────────────┐
           ┌─────────│ dim_location │←────────┐
           │         └──────────────┘         │
           │                                  │
           │ location_key        location_key │
           │                                  │
  ┌────────────────────┐          ┌─────────────────────┐
  │ fact_vehicle_      │          │ fact_parking_       │
  │ registration       │          │ capacity            │
  └────────────────────┘          └─────────────────────┘
           │                                  │
           │ date_key                         │ parking_area_key
           ↓                                  ↓
    ┌──────────────┐                ┌─────────────────┐
    │  dim_date    │                │ dim_parking_area│
    └──────────────┘                └─────────────────┘
           ↑
           │ date_key
           │
  ┌─────────────────────┐
  │ fact_fuel_          │
  │ distribution        │
  └─────────────────────┘
```

---

## Detailed Relationship Definitions

### 1. fact_vehicle_registration Relationships

| Relationship | From (Many) | To (One) | Cardinality | Filter Direction |
|--------------|------------|----------|-------------|------------------|
| Vehicle Registration → Vehicle | fact_vehicle_registration.vehicle_key | dim_vehicle.vehicle_key | Many-to-One | Single |
| Vehicle Registration → Fuel Type | fact_vehicle_registration.fuel_key | dim_fuel_type.fuel_key | Many-to-One | Single |
| Vehicle Registration → Location | fact_vehicle_registration.location_key | dim_location.location_key | Many-to-One | Single |
| Vehicle Registration → Date | fact_vehicle_registration.date_key | dim_date.date_key | Many-to-One | Single |

### 2. fact_vehicle_emissions Relationships

| Relationship | From (Many) | To (One) | Cardinality | Filter Direction |
|--------------|------------|----------|-------------|------------------|
| Vehicle Emissions → Vehicle | fact_vehicle_emissions.vehicle_key | dim_vehicle.vehicle_key | Many-to-One | Single |
| Vehicle Emissions → Fuel Type | fact_vehicle_emissions.fuel_key | dim_fuel_type.fuel_key | Many-to-One | Single |

### 3. fact_fuel_distribution Relationships

| Relationship | From (Many) | To (One) | Cardinality | Filter Direction |
|--------------|------------|----------|-------------|------------------|
| Fuel Distribution → Fuel Type | fact_fuel_distribution.fuel_key | dim_fuel_type.fuel_key | Many-to-One | Single |
| Fuel Distribution → Location | fact_fuel_distribution.location_key | dim_location.location_key | Many-to-One | Single |
| Fuel Distribution → Date | fact_fuel_distribution.date_key | dim_date.date_key | Many-to-One | Single |

### 4. fact_parking_capacity Relationships

| Relationship | From (Many) | To (One) | Cardinality | Filter Direction |
|--------------|------------|----------|-------------|------------------|
| Parking Capacity → Parking Area | fact_parking_capacity.parking_area_key | dim_parking_area.parking_area_key | Many-to-One | Single |
| Parking Capacity → Location | fact_parking_capacity.location_key | dim_location.location_key | Many-to-One | Single |

---

## Manual Configuration Steps (Fabric Portal)

1. Open **RDW Analytics** semantic model in Fabric portal
2. Click **Open data model** at the top
3. Switch to **Model view** (diagram icon on left sidebar)
4. For each relationship above:
   - Drag from the **From Column** (fact table) to the **To Column** (dimension table)
   - Verify cardinality is **Many-to-One**
   - Ensure cross-filtering is **Single direction** (from fact → dimension)
   - Click **Create**
5. Save the model

### Tips for Manual Creation:
- Use **Manage relationships** dialog (top ribbon) to see all relationships
- Use **Layout → Auto-arrange** to organize diagram
- Verify no circular dependencies
- Ensure all key columns have matching data types (INT)

---

## Programmatic Configuration (PowerShell)

Run the provided script:

```powershell
.\configure-relationships.ps1 -WorkspaceName "RDWAgents" -DatasetName "RDW Analytics"
```

**Prerequisites:**
- Microsoft.AnalysisServices.Administration module installed
- Authenticated via `Connect-PowerBIServiceAccount`
- Semantic model already created and refreshed

---

## Validation Checklist

After configuring relationships, verify:

- [ ] All 11 relationships created (4 + 2 + 3 + 2)
- [ ] No circular relationship warnings
- [ ] All relationships are **Active**
- [ ] All relationships are **Many-to-One**
- [ ] Cross-filtering is **Single direction**
- [ ] Key columns match data types (INT for all surrogate keys)

---

## Common Issues

### Issue: "Cannot create relationship - ambiguous path"
- **Cause:** Multiple paths between two tables (role-playing dimensions)
- **Solution:** Make one relationship inactive, or use USERELATIONSHIP() in DAX

### Issue: "Key values don't match"
- **Cause:** Orphaned foreign keys in fact table (referential integrity)
- **Solution:** Add integrity checks in Silver-to-Gold notebook:
  ```python
  # Example: Verify all vehicle keys exist
  orphans = facts.join(dims, on="vehicle_key", how="left_anti")
  assert orphans.count() == 0, "Found orphaned keys!"
  ```

### Issue: "Relationship auto-detect failed"
- **Cause:** Column names don't follow conventions (_key, _id suffix)
- **Solution:** Manually create relationships as documented above

---

## Next Steps

Once relationships are configured, proceed to:
- **Add DAX measures** (see [README.md](README.md) Part 3)
- **Create Power BI reports** (see `../reports/`)
