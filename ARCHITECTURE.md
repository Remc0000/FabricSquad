# RDW Medallion Architecture — Complete Solution Summary

This document provides a high-level overview of the complete RDW Medallion environment.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                     RDW - Open Data (Source)                        │
│                    Workspace: e19bbf3f-5e95-41c0-bf2f               │
├─────────────────────────────────────────────────────────────────────┤
│  RDWLake Lakehouse                                                  │
│  dbo schema:                                                        │
│    - gekentekende_voertuigen                                        │
│    - gekentekende_voertuigen_brandstof                              │
│    - brandstoffen_op_pc4                                            │
│    - parkeeradres                                                   │
│    - specificaties_parkeergebied                                    │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ OneLake Shortcuts (Zero-Copy)
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                       RDWAgents (Target)                            │
│                   Workspace: 97b7e768-c5d2-4501-9af2                │
│                   Trial Capacity: 638b8321-729d-4c91                │
├─────────────────────────────────────────────────────────────────────┤
│  RDWAgentsLake Lakehouse                                            │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ BRONZE SCHEMA (Raw Data - OneLake Shortcuts)                 │ │
│  ├───────────────────────────────────────────────────────────────┤ │
│  │  1. gekentekende_voertuigen          → 10M+ rows             │ │
│  │  2. gekentekende_voertuigen_brandstof → 15M+ rows            │ │
│  │  3. brandstoffen_op_pc4              → 70K+ rows             │ │
│  │  4. parkeeradres                     → 300K+ rows            │ │
│  │  5. specificaties_parkeergebied      → 50K+ rows             │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              │                                       │
│                              │ Notebook: 01_bronze_to_silver.ipynb   │
│                              │ - Column renaming                     │
│                              │ - Date parsing                        │
│                              │ - Numeric casting                     │
│                              │ - Deduplication                       │
│                              ↓                                       │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ SILVER SCHEMA (Cleansed Data)                                │ │
│  ├───────────────────────────────────────────────────────────────┤ │
│  │  1. vehicles                  → Cleansed vehicle records     │ │
│  │  2. vehicle_fuels             → Cleansed fuel data           │ │
│  │  3. fuels_by_postal_code      → Cleansed postal fuel data    │ │
│  │  4. parking_addresses         → Cleansed parking addresses   │ │
│  │  5. parking_area_specs        → Cleansed parking specs       │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              │                                       │
│                              │ Notebook: 02_silver_to_gold.ipynb     │
│                              │ - Star schema modeling                │
│                              │ - Surrogate key generation            │
│                              │ - Dimension/fact separation           │
│                              ↓                                       │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ GOLD SCHEMA (Analytics-Ready Star Schema)                    │ │
│  ├───────────────────────────────────────────────────────────────┤ │
│  │ DIMENSIONS (5):                                              │ │
│  │  1. dim_vehicle      → Vehicle attributes & surrogate key    │ │
│  │  2. dim_fuel_type    → Fuel type lookup                      │ │
│  │  3. dim_location     → Postal/city/province hierarchy        │ │
│  │  4. dim_parking_area → Parking area attributes               │ │
│  │  5. dim_date         → Date dimension (year/month/week)      │ │
│  │                                                              │ │
│  │ FACTS (4):                                                   │ │
│  │  1. fact_vehicle_registration → Registration events          │ │
│  │  2. fact_vehicle_emissions    → Emission & consumption data  │ │
│  │  3. fact_fuel_distribution    → Fuel by postal code          │ │
│  │  4. fact_parking_capacity     → Parking infrastructure       │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  SQL Analytics Endpoint:                                            │
│  i3okznlkvxhe3fmmjrbk74yk3i-ndt3pf6syuaulgxsfgzxxzwihq...          │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ Direct Lake Connection
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    RDW Analytics Semantic Model                     │
│                    (Direct Lake - No Import Needed)                 │
├─────────────────────────────────────────────────────────────────────┤
│  Tables: All 9 Gold tables                                          │
│  Relationships: 11 Many-to-One star schema relationships            │
│  DAX Measures: 13 calculated measures                               │
│    - Vehicle analytics (4): Total, Avg CO2, Z-Score, Outliers       │
│    - Statistical (3): P50, P90, P99                                 │
│    - Fuel (2): Total Distribution, Market Share %                   │
│    - Parking (4): Total Capacity, Paid %, Disabled %, Loading %     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ Report Connection
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      RDW Dashboard (Power BI Report)                │
├─────────────────────────────────────────────────────────────────────┤
│  Page 1: Fleet Composition       → Brand/type/fuel breakdown        │
│  Page 2: Emissions Outliers      → Z-score analysis & scatter       │
│  Page 3: Geographic Distribution → Maps & postal code heatmaps      │
│  Page 4: Parking Infrastructure  → Capacity & utilization KPIs      │
│  Page 5: Trends Over Time        → Registration & fuel adoption     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Technical Specifications

### Infrastructure

| Component | Value | Notes |
|-----------|-------|-------|
| Source Workspace | RDW - Open Data (e19bbf3f) | Read-only source |
| Target Workspace | RDWAgents (97b7e768) | Workshop workspace |
| Capacity | Trial (638b8321) | Free tier, ~2 CU |
| Lakehouse | RDWAgentsLake (ac035351) | Schema-enabled |
| SQL Endpoint | i3okznlkvxhe3fmmjrbk74yk3i... | Auto-provisioned |

### Data Volumes

| Layer | Schema | Tables | Approx Rows | Storage |
|-------|--------|--------|-------------|---------|
| Bronze | bronze | 5 shortcuts | ~25M+ | 0 bytes (shortcut) |
| Silver | silver | 5 tables | ~25M+ | 3-5 GB |
| Gold | gold | 9 tables | ~25M+ | 4-6 GB |

### Notebooks

| Notebook | Purpose | Execution Time | Status |
|----------|---------|----------------|--------|
| 01_bronze_to_silver | Data cleansing | ~7 minutes | ✅ Deployed & Run |
| 02_silver_to_gold | Star schema | ~5 minutes | ✅ Deployed & Run |

**Notebook IDs:**
- 01_bronze_to_silver: `10a6e49c-9363-463e-8d56-31f4cdb7fc24`
- 02_silver_to_gold: `4ecc06dc-e384-4d1d-8c6a-3968a4cfcbcf`

### Semantic Model

| Property | Value |
|----------|-------|
| Name | RDW Analytics |
| Mode | Direct Lake |
| Tables | 9 (5 dims + 4 facts) |
| Relationships | 11 Many-to-One |
| DAX Measures | 13 |
| Performance | < 5 sec page load |

### Reports

| Report | Pages | Visuals per Page | Interactive |
|--------|-------|------------------|-------------|
| RDW Dashboard | 5 | 4-6 | Yes |

---

## Data Flow Diagram

```
Source Data (Dutch Vehicle Registry)
         │
         ↓
    [OneLake Shortcuts] ← Zero-copy reference
         │
         ↓
    Bronze Layer (Raw)
         │
         ↓ [PySpark Notebook 1]
         │   - Rename columns
         │   - Parse dates
         │   - Cast types
         │   - Deduplicate
         ↓
    Silver Layer (Cleansed)
         │
         ↓ [PySpark Notebook 2]
         │   - Generate dimensions
         │   - Create surrogate keys
         │   - Build fact tables
         │   - Star schema joins
         ↓
    Gold Layer (Star Schema)
         │
         ↓ [Direct Lake]
         │   - Real-time query
         │   - No data movement
         │   - Sub-second latency
         ↓
    Semantic Model
         │   - Relationships
         │   - DAX logic
         │   - Business metrics
         ↓
    Power BI Reports
         │   - Interactive visuals
         │   - Slicers & filters
         │   - Drill-through
         ↓
    Business Insights
```

---

## Key Design Decisions

### 1. Single Lakehouse with Multiple Schemas
**Why:** Simpler governance, easier permissions management, less cross-lakehouse networking
**Alternative:** Multiple lakehouses (one per layer) — rejected due to complexity

### 2. OneLake Shortcuts for Bronze
**Why:** Zero-copy ingestion, no data duplication, instant sync with source
**Alternative:** Copy data via pipelines — rejected due to storage cost and latency

### 3. PySpark Notebooks (Not Pipelines)
**Why:** Full control over complex transformations, easier debugging, reusable code
**Alternative:** Data Factory pipelines — considered but notebooks offer more flexibility

### 4. Star Schema for Gold
**Why:** Optimal for OLAP queries, clear grain definition, supports Direct Lake
**Alternative:** Flat denormalized tables — rejected due to data duplication

### 5. Direct Lake Semantic Model
**Why:** No import lag, real-time analysis, minimal storage duplication
**Alternative:** Import mode — rejected due to refresh delays and storage overhead

---

## Performance Characteristics

### Query Latency

| Query Type | Expected Latency | Notes |
|------------|------------------|-------|
| Simple aggregation (COUNT) | < 1 second | Cached in capacity |
| Complex join (3+ tables) | 1-3 seconds | Direct Lake optimized |
| Z-score calculation | 2-5 seconds | Requires full scan |
| Map visual (postcode) | 3-8 seconds | Geographic rendering |

### Scalability

Current design scales to:
- **Data volume:** 100M+ rows per fact table (tested on similar Fabric setups)
- **Dimensions:** Up to 50M unique dimension members
- **Concurrent users:** 10-50 report viewers (trial capacity)
- **Refresh frequency:** Real-time (Direct Lake), or hourly notebook runs

### Bottlenecks & Mitigations

| Bottleneck | Mitigation |
|------------|-----------|
| Large fact table scans | Add date partitioning to Gold facts |
| Complex DAX measures | Pre-aggregate in Gold layer (add summary tables) |
| Trial capacity limits | Upgrade to F2/F4 capacity for production |
| Concurrent notebook runs | Use pipeline orchestration with concurrency limits |

---

## Security Model

### Layer Isolation

- **Bronze:** Read-only shortcuts, no direct write access
- **Silver:** Write access only for ETL notebooks
- **Gold:** Read-only for semantic models, write only for ETL notebooks
- **Semantic Model:** Read-only for report viewers, write for model designers
- **Reports:** View access via workspace roles (Viewer, Contributor, Admin)

### Service Principal Access

If using SPNs:
- **spn_FabricKing:** Full admin (workspace create, notebook deploy)
- **spn_fuam:** Limited to specific lakehouses (for prod separation)

### Row-Level Security (RLS)

Not implemented in this workshop, but can be added:

```dax
-- Example: Filter by province
[Province] = USERNAME()
```

Apply this filter to `dim_location` table in semantic model settings.

---

## Cost Breakdown (Estimated)

For trial capacity (included in Fabric trial):

| Component | Cost | Notes |
|-----------|------|-------|
| Trial capacity | $0 | 2 CU, time-limited |
| OneLake storage | ~$0.02/GB/month | ~10 GB total |
| Compute (notebooks) | $0 | Included in capacity |
| Direct Lake queries | $0 | Included in capacity |

**Total monthly cost:** ~$0.20 (storage only)

For production F2 capacity (~$263/month):
- Supports 10x more users
- 2 capacity units
- Includes all compute and storage within quota

---

## Maintenance & Operations

### Regular Tasks

1. **Weekly:**
   - Review notebook run logs for failures
   - Check semantic model refresh status
   - Monitor report usage analytics

2. **Monthly:**
   - Review capacity utilization metrics
   - Update DAX measures based on user feedback
   - Archive old data (if retention policy defined)

3. **Quarterly:**
   - Review and optimize slow-running queries
   - Update notebook code for new source tables
   - Refresh workshop materials with latest screenshots

### Monitoring Dashboards

Create a separate "Ops Dashboard" with:
- Notebook execution success rate
- Average query latency by report page
- Capacity utilization (CPU, memory, CU seconds)
- User activity (report views, unique users)

### Alerting

Set up alerts for:
- Notebook failures (email notification)
- Semantic model refresh failures
- Capacity oversubscription (>80% utilization)
- Anomalous data volumes (sudden 10x increase)

---

## Extension Ideas

### 1. Add Streaming Layer
**Use Case:** Real-time vehicle registrations
**Implementation:** KQL Database → Eventstream → Real-Time Dashboard

### 2. Machine Learning Integration
**Use Case:** Predict vehicle emissions based on attributes
**Implementation:** Synapse Data Science → ML model → Gold layer table

### 3. Natural Language Queries
**Use Case:** Users ask "What's the average CO2 for Tesla?" in chat
**Implementation:** Fabric Copilot for Power BI → DAX generation

### 4. Data Lineage Tracking
**Use Case:** Show data journey from Bronze → Gold
**Implementation:** Purview integration or custom metadata tables

### 5. Multi-Tenant Environments
**Use Case:** Different workspace per customer
**Implementation:** Deployment pipelines + workspace templates

---

## File Structure in FabricSquad Project

```
FabricSquad/
├── WORKSHOP.md                      → 11-part comprehensive guide
├── README.md                        → Project overview
├── ARCHITECTURE.md                  → This file
├── tasks.md                         → All 43 tasks (all complete ✅)
│
├── openspec/
│   └── changes/rdw-medallion-environment/
│       ├── proposal.md              → Initial proposal
│       ├── design.md                → Technical design
│       ├── spec-*.md (×5)           → Detailed specs per table
│       └── tasks.md                 → Task breakdown
│
├── notebooks/
│   ├── 01_bronze_to_silver.ipynb   → ETL notebook (deployed ✅)
│   └── 02_silver_to_gold.ipynb     → Star schema notebook (deployed ✅)
│
├── infrastructure/
│   ├── create-shortcuts.ps1        → OneLake shortcut creation
│   ├── shortcuts.json               → Shortcut definitions
│   └── README.md                    → Infrastructure guide
│
├── semantic-model/
│   ├── README.md                    → Model creation guide
│   ├── RELATIONSHIPS.md             → 11 relationships documented
│   ├── create-semantic-model.ps1   → XMLA-based model creation
│   ├── configure-relationships.ps1 → Automated relationship setup
│   └── add-dax-measures.ps1        → Bulk DAX measure creation
│
├── reports/
│   └── README.md                    → Power BI report design guide
│
└── validation/
    ├── README.md                    → Validation tools overview
    ├── VALIDATION-CHECKLIST.md      → Step-by-step checklist
    └── validate-environment.ps1    → Automated validation script
```

---

## Workshop Materials Summary

| Artifact | Purpose | Target Audience |
|----------|---------|-----------------|
| WORKSHOP.md | Complete step-by-step guide | Beginners |
| ARCHITECTURE.md | High-level design overview | Intermediate |
| semantic-model/README.md | Semantic model creation | Intermediate |
| reports/README.md | Power BI report design | All levels |
| validation/VALIDATION-CHECKLIST.md | Quality assurance | All levels |
| *.ps1 scripts | Automation & CI/CD | Advanced |

---

## Success Metrics

After completing the workshop, participants should be able to:

1. ✅ Explain medallion architecture (Bronze/Silver/Gold)
2. ✅ Create OneLake shortcuts for zero-copy ingestion
3. ✅ Write PySpark notebooks for data transformations
4. ✅ Deploy notebooks to Fabric workspace via API
5. ✅ Design star schemas for OLAP analytics
6. ✅ Create Direct Lake semantic models
7. ✅ Configure relationships and DAX measures
8. ✅ Build Power BI reports with outlier detection
9. ✅ Use `fab` CLI for workspace automation
10. ✅ Validate end-to-end data flow

---

## Known Limitations

### Data Freshness
- **Bronze:** Real-time (shortcuts mirror source)
- **Silver/Gold:** Updated only when notebooks run (not automatic)
- **Semantic Model:** Real-time via Direct Lake (no refresh needed)

**Solution:** Schedule notebooks to run hourly/daily with Data Factory pipelines

### Trial Capacity Constraints
- 2 capacity units (limited compute)
- Time-limited (60 days)
- May throttle under heavy load

**Solution:** Upgrade to F2 or higher for production

### Schema Changes
- If source schema changes, notebooks must be updated manually
- No automatic schema evolution detection

**Solution:** Add schema validation checks at start of notebooks

### Cross-Workspace Shortcuts
- Shortcuts depend on source workspace remaining accessible
- If source is deleted, shortcuts break

**Solution:** Document dependencies, use lifecycle management policies

---

## References

- **Microsoft Fabric Docs:** https://learn.microsoft.com/fabric/
- **Direct Lake:** https://learn.microsoft.com/power-bi/enterprise/directlake-overview
- **OneLake Shortcuts:** https://learn.microsoft.com/fabric/onelake/onelake-shortcuts
- **Star Schema Design:** https://learn.microsoft.com/power-bi/guidance/star-schema
- **DAX Best Practices:** https://learn.microsoft.com/dax/best-practices/dax-dos-and-donts
- **RDW Open Data Portal:** https://opendata.rdw.nl/

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-01 | Initial implementation - Bronze/Silver/Gold + Semantic Model + Reports |

---

## Contributors

Workshop designed and implemented with:
- **AI Tooling:** OpenSpec (spec generation), Squad (agent framework), Copilot (code generation)
- **Fabric CLI:** `ms-fabric-cli` (fab) for automation
- **Skills:** fabric-notebookContextTool, fabric-skill-creator, fabric-skill-reviewer

---

## Next Steps for Workshop Delivery

1. **Pre-Workshop:**
   - Run `validate-environment.ps1` to confirm all components operational
   - Test all PowerShell scripts on clean environment
   - Prepare demo tenant with sample data

2. **During Workshop:**
   - Follow WORKSHOP.md Part 1-11
   - Use validation checkpoints after each major section
   - Encourage participants to customize (different brands, regions, etc.)

3. **Post-Workshop:**
   - Collect feedback on documentation clarity
   - Update WORKSHOP.md with common issues encountered
   - Create video walkthrough (optional)

---

## Support & Troubleshooting

For issues during workshop:
1. Check [validation/VALIDATION-CHECKLIST.md](validation/VALIDATION-CHECKLIST.md)
2. Review relevant README in each subfolder
3. Check WORKSHOP.md Appendices for common errors
4. Use Fabric Copilot in VS Code for debugging

Happy building! 🚀
