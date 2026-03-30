## Context

The `RDW - Open Data` workspace (ID: `e19bbf3f-5e95-41c0-bf2f-41be9e54f78c`) contains a schema-enabled lakehouse `RDWLake` (ID: `af7b7520-da32-400b-b7c3-ea9c7b82a47f`) with 5 raw tables in the `dbo` schema, ingested from the Dutch Vehicle Authority's open data APIs:

| Table | Description | Key columns |
|-------|-------------|-------------|
| `gekentekende_voertuigen` | ~90 columns: vehicle registrations (license plate, brand, model, type, mass, dimensions, dates, colors, APK status) | Kenteken (PK) |
| `gekentekende_voertuigen_brandstof` | ~42 columns: fuel/emission data per vehicle-fuel combo (CO2, consumption, WLTP, electric range) | Kenteken + Brandstof_volgnummer |
| `brandstoffen_op_pc4` | 5 columns: vehicle count by postal code × vehicle type × fuel type | Postcode + Voertuigsoort + Brandstof |
| `parkeeradres` | 12 columns: parking facility addresses | ParkingAddressReference |
| `specificaties_parkeergebied` | 9 columns: parking area specs (capacity, EV charging, accessibility) | AreaManagerId + AreaId + StartDateSpecifications |

The lakehouse uses the schema-enabled feature, so all tables live under `dbo`. The SQL analytics endpoint is available at `i3okznlkvxhe3fmmjrbk74yk3i-h67zxymvl3aedpzpig7j4vhxrq.datawarehouse.fabric.microsoft.com`.

## Goals / Non-Goals

**Goals:**
- Stand up `RDWAgents` workspace on trial capacity with a lakehouse
- Reference Bronze data via OneLake shortcut (zero-copy)
- Build Silver layer with cleansed, properly typed tables in `silver` schema
- Build Gold layer with a dimensional star model in `gold` schema optimized for outlier detection and aggregated counts
- Create a semantic model with DAX measures for outlier analysis (z-scores, percentiles, standard deviations)
- Deliver Power BI reports for fleet analysis, emissions, geographic distribution, and parking

**Non-Goals:**
- Incremental/streaming ingestion — this is a batch-first design; CDC can be added later
- Data quality monitoring or alerting framework
- Row-level security or workspace-level access control beyond default
- Historization / SCD Type 2 for dimensions — current-state snapshot is sufficient for initial delivery
- Integration with external systems beyond the RDW source lakehouse

## Decisions

### 1. Single lakehouse with multiple schemas (not multiple lakehouses)

**Decision**: Use one lakehouse in `RDWAgents` with `bronze` (shortcut), `silver`, and `gold` schemas.

**Rationale**: Schema-enabled lakehouses support schema separation. A single lakehouse simplifies governance, OneLake paths, and semantic model connectivity. Multiple lakehouses would add unnecessary complexity for this dataset size.

**Alternative considered**: Separate lakehouses per layer — rejected because the data volume doesn't warrant it and shortcuts across lakehouses in the same workspace add no benefit over schemas.

### 2. OneLake shortcut for Bronze (not data copy)

**Decision**: Create a OneLake shortcut from `RDWAgents` lakehouse pointing to `RDW - Open Data/RDWLake/Tables/dbo/*` tables. Reference these as the Bronze layer.

**Rationale**: Zero-copy, real-time access to source data. No storage duplication. Shortcut supports Delta table reads through Spark and SQL endpoint.

**Alternative considered**: Copy job in Data Factory — rejected because it duplicates data unnecessarily; the source is already in OneLake.

### 3. Spark notebooks for transformations (not dataflows or SQL stored procedures)

**Decision**: Use PySpark notebooks for both Bronze→Silver and Silver→Gold transformations.

**Rationale**: Full control over complex transformations (date parsing from Dutch formats, outlier calculations, dimensional modeling logic). Notebooks are versionable, testable, and align with the team's Fabric skills.

**Alternative considered**: Dataflows Gen2 — rejected for Gold layer due to limited support for complex join patterns and calculated columns needed for the star schema. SQL stored procedures — rejected because they can't easily handle Delta table writes across schemas in a lakehouse.

### 4. Star schema design for Gold layer

**Decision**: Classic star schema with 5 dimensions and 4 fact tables.

**Rationale**: Star schema is optimal for the analytical queries requested (outlier detection, counts by various dimensions). Direct Lake mode in Power BI works best with star schemas. Separate fact tables per subject area (registrations, emissions, fuel distribution, parking) keep fact tables focused and performant.

**Alternative considered**: Wide denormalized table — rejected because it would create massive row duplication (vehicle × fuel type × location) and make outlier detection queries slower.

### 5. Gold `dim_date` as generated dimension

**Decision**: Generate `dim_date` covering the full range of dates found across all date columns, rather than referencing an external calendar table.

**Rationale**: Self-contained solution. Date range can be derived from min/max of `Datum_eerste_toelating`, `Vervaldatum_APK`, `Datum_tenaamstelling`, etc.

### 6. Direct Lake semantic model

**Decision**: Use Direct Lake mode for the semantic model, pointing directly at Gold schema Delta tables.

**Rationale**: No data import or duplication. Sub-second query performance on Delta tables. Automatic refresh when Gold tables are updated.

**Alternative considered**: Import mode — rejected because it doubles storage and requires scheduled refresh. DirectQuery — rejected because it's slower for aggregation-heavy dashboards.

## Risks / Trade-offs

- **[Trial capacity limitations]** → Trial capacity has compute and storage limits. Mitigation: Monitor capacity usage; the dataset is manageable (RDW open data is ~15M vehicles but delta storage is efficient).
- **[Shortcut breaks if source workspace is deleted/renamed]** → Mitigation: Document the dependency; source workspace is a stable open data workspace.
- **[Schema-enabled lakehouse is relatively new feature]** → Some tooling may not fully support schemas. Mitigation: Use `fab` CLI and Spark for all DDL; avoid relying on UI-only features.
- **[Date columns stored as strings in source]** → Multiple date formats exist (YYYYMMDD integers, ISO strings). Mitigation: Silver layer normalizes all dates to proper `date` type with explicit parsing logic.
- **[Type inconsistencies in source]** → Many numeric columns stored as strings (e.g., `Bruto_BPM`, `Catalogusprijs`, `Lengte`, `Breedte`). Mitigation: Silver layer casts all columns to correct types with try/except handling for malformed values.

## Migration Plan

1. Create `RDWAgents` workspace via Fabric REST API (`fab api`)
2. Create lakehouse with schemas enabled
3. Create OneLake shortcuts to source Bronze tables
4. Deploy and run Silver notebook
5. Deploy and run Gold notebook
6. Create and configure semantic model
7. Create and publish reports
8. Rollback: Delete `RDWAgents` workspace — no impact on source data

## Open Questions

- Should the Gold layer include a `dim_vehicle_category` (Europese_voertuigcategorie, Inrichting, Voertuigsoort) as a separate dimension or keep it as attributes on `dim_vehicle`? Current design: attributes on `dim_vehicle` for simplicity.
- What specific outlier thresholds should reports use? Current approach: dynamic z-scores (>2σ, >3σ) calculated via DAX.
- Should parking data (parkeeradres + specificaties_parkeergebied) be joined in Silver or kept separate until Gold? Current design: separate Silver tables, joined in Gold `fact_parking_capacity`.
