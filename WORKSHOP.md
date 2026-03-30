# Workshop: From Zero to Medallion — Building a Fabric Data Platform with AI Agents

> **Duration**: ~4 hours  
> **Level**: Intermediate  
> **Prerequisites**: A Microsoft Fabric tenant with trial capacity, a GitHub account, an Azure subscription with Entra ID access  
> **What you'll build**: A complete medallion architecture (Bronze → Silver → Gold) on RDW Dutch Vehicle Authority open data, with dimensional modeling, a semantic model, and Power BI reports — using AI agents to go from idea to implementation.

---

## Part 1: Environment Setup — Developer Tools

### 1.1 Install VS Code

1. Download VS Code from https://code.visualstudio.com/
2. Run the installer, accept defaults
3. Launch VS Code

### 1.2 Install Git

1. Download Git for Windows from https://git-scm.com/download/win
2. Run the installer — accept defaults (make sure "Git from the command line" is selected)
3. Open a terminal in VS Code (`Ctrl+``) and verify:
   ```powershell
   git --version
   ```

### 1.3 Install GitHub CLI

1. Download from https://cli.github.com/
2. Run the installer
3. Authenticate:
   ```powershell
   gh auth login -h github.com -p https -w
   ```
   Follow the browser flow — enter the one-time code shown in the terminal.

### 1.4 Install Node.js

1. Download LTS from https://nodejs.org/
2. Run the installer
3. Verify:
   ```powershell
   node --version
   npm --version
   ```

### 1.5 Install Python

Python is required for the Fabric CLI (`fab`). The fastest way to install it is with **uv** — a modern Python package manager and installer.

1. Install uv:
   ```powershell
   irm https://astral.sh/uv/install.ps1 | iex
   ```
2. Restart your terminal, then verify:
   ```powershell
   uv --version
   ```
3. Install Python (if not already installed):
   ```powershell
   uv python install
   python --version
   ```

> **Alternative**: You can also install Python directly from https://www.python.org/downloads/ — make sure to check "Add Python to PATH" during installation.

### 1.6 Install the Fabric CLI (fab)

The Fabric CLI (`fab`) is a command-line tool for managing Microsoft Fabric resources. Install it with uv:

```powershell
uv tool install ms-fabric-cli
fab --version
```

> **Note**: If you already have Python and pip installed, you can also use: `pip install ms-fabric-cli`

### 1.7 Install VS Code Extensions

Open VS Code and install these extensions:
- **GitHub Copilot** (`GitHub.copilot`)
- **GitHub Copilot Chat** (`GitHub.copilot-chat`)
- **Synapse VS Code (Fabric Notebooks)** (`synapsevscode.synapse-1.22.0` or latest)

You can install from the command line:
```powershell
code --install-extension GitHub.copilot
code --install-extension GitHub.copilot-chat
```

---

## Part 2: Environment Setup — Service Principal & Fabric Admin

To automate Fabric operations from the CLI, you need a **Service Principal** (SPN) with the right permissions.

### 2.1 Create a Service Principal in Entra ID

1. Go to the [Azure Portal](https://portal.azure.com/) → **Microsoft Entra ID** → **App registrations**
2. Click **+ New registration**
   - **Name**: e.g. `spn_FabricWorkshop`
   - **Supported account types**: "Accounts in this organizational directory only"
   - Click **Register**
3. On the overview page, copy:
   - **Application (client) ID** → e.g. `116aa69b-1bff-45d5-95b5-6cd276b1dea0`
   - **Directory (tenant) ID** → e.g. `b5acdc46-ad6a-4dce-958c-4c42aff30ada`
4. Go to **Certificates & secrets** → **+ New client secret**
   - **Description**: e.g. `fab-cli-secret`
   - **Expires**: choose your preferred expiry
   - Click **Add**
   - **Copy the Value immediately** — you won't be able to see it again!

> **Security**: Store the secret securely. Never commit it to source control. For this workshop, you'll use it once to authenticate and it stays in your local token cache.

### 2.2 Create a Security Group for the SPN

1. In the Azure Portal → **Microsoft Entra ID** → **Groups**
2. Click **+ New group**
   - **Group type**: Security
   - **Group name**: e.g. `sg_FabricAPIAdmins`
   - **Members**: Add your service principal (`spn_FabricWorkshop`)
   - Click **Create**

### 2.3 Add the Security Group to Fabric Admin Settings

1. Go to the [Fabric Admin Portal](https://app.fabric.microsoft.com/admin-portal/)
   - Or: Fabric portal → ⚙️ Settings → Admin portal
2. Navigate to **Tenant settings** → search for **"Service principals can use Fabric APIs"**
3. Enable the setting
4. Under **Apply to**, select **Specific security groups**
5. Add your security group (`sg_FabricAPIAdmins`)
6. Click **Apply**

> **Important**: It can take up to **15 minutes** for tenant settings changes to take effect.

### 2.4 Authenticate the Fabric CLI with the Service Principal

Now authenticate `fab` using your SPN credentials:

```powershell
fab auth login `
  -u <your-application-client-id> `
  -p <your-client-secret-value> `
  --tenant <your-tenant-id>
```

Example:
```powershell
fab auth login `
  -u <YOUR_CLIENT_ID> `
  -p "<YOUR_CLIENT_SECRET>" `
  --tenant <YOUR_TENANT_ID>
```

Verify:
```powershell
fab auth status
```

You should see your SPN name and tenant ID in the output.

> **Alternative (interactive login)**: If you prefer to use your personal account instead of an SPN, simply run `fab auth login` — this opens a browser for Entra ID authentication.

---

## Part 3: Install the AI Agent Tooling

### 3.1 Install Squad (AI Team Framework)

Squad gives you a team of AI agents that collaborate on your project.

**Repository**: https://github.com/bradygaster/squad

```powershell
npm install -g @bradygaster/squad-cli
squad --version
```

### 3.2 Install OpenSpec (Spec-Driven Development)

OpenSpec is a CLI for managing structured change proposals — from idea → proposal → design → specs → tasks → implementation.

**Repository**: https://github.com/Fission-AI/OpenSpec

```powershell
npm install -g @fission-ai/openspec@latest
openspec --version
```

### 3.3 Install Fabric Skills for Copilot

These skills teach GitHub Copilot about Microsoft Fabric capabilities — things like how shortcuts work, how to create notebooks, how to use the Fabric API, etc.

**Repository**: https://github.com/microsoft/skills-for-fabric

```powershell
cd C:\Projects
git clone https://github.com/microsoft/skills-for-fabric.git
cd skills-for-fabric
.\install.ps1
```

This installs ~10 skills to `~/.copilot/skills/fabric`. After installation, restart VS Code for the skills to take effect.

---

## Part 4: Create Your Project

### 4.1 Create the Project Directory

```powershell
mkdir C:\Projects\FabricSquad
cd C:\Projects\FabricSquad
```

### 4.2 Initialize Git

```powershell
git init
git config user.name "Your Name"
git config user.email "you@example.com"
```

### 4.3 Initialize Squad

Run the `squad` command first to see the available commands:

```powershell
squad
```

Then initialize your team with a detailed team description. This is where you define what your agents know and how they should work:

```powershell
squad init
```

When prompted for a team description, enter the full description. Be specific about your data engineering philosophy:

> My team of agents has all the fabric skills that are needed in a project. Don't forget the functional analytics, the report developer. For ingestion, I always want to check if shortcuts are possible, if that is not possible, then use mirroring, if that is not possible, then create copy jobs in fabric data factory. I want that all code is documented and it should not be too hard to interpret, also I need to have an agent for openspec to define what is needed, so he is responsible for collecting the requirements, and make them sharp so all other agents know what to do.

This creates the `.squad/` directory with agent configurations. Each agent gets its own role (data engineer, report developer, analyst, etc.) based on the description you provided.

> **Tip**: After running `squad init`, inspect the `.squad/` folder to see the generated agents. You can edit their configurations later if needed.

### 4.4 Initialize OpenSpec

```powershell
openspec init
```

This creates the `openspec/` directory with `config.yaml`.

### 4.5 Open VS Code in the Project

```powershell
code .
```

Wait for VS Code to load. Open a new chat window (`Ctrl+Shift+I`). The GitHub Copilot agent will now have access to your squad agents, OpenSpec skills, and Fabric skills — all via slash commands.

### 4.6 Create `.gitignore`

Create a `.gitignore` file with:
```
# Squad runtime state
.squad/orchestration-log/
.squad/log/
.squad/decisions/inbox/
.squad/sessions/
.squad-workstream

# Temp files
*.txt
*.json
!openspec/**/*.json
!.squad/**/*.json
!.github/**/*.json
!.copilot/**/*.json
!package.json

# Python
__pycache__/
*.pyc

# Cloned repos
skills-for-fabric/
```

### 4.7 Push to GitHub

```powershell
git add .
git commit -m "Initial commit: FabricSquad project"
gh repo create FabricSquad --public --source=. --remote=origin --push
```

---

## Part 5: Discover Your Source Data

Before proposing any changes, you need to understand what data exists.

### 5.1 Find Your Workspace

```powershell
fab api -X get "workspaces"
```

Look for your source workspace in the JSON output. In our case:
- **Workspace**: `RDW - Open Data`  
- **ID**: `e19bbf3f-5e95-41c0-bf2f-41be9e54f78c`

### 5.2 List Workspace Items

```powershell
fab api -X get "workspaces/<workspace-id>/items"
```

This reveals lakehouses, warehouses, notebooks, and other items.  
Our lakehouse: `RDWLake` (ID: `af7b7520-da32-400b-b7c3-ea9c7b82a47f`)

### 5.3 List Lakehouse Tables

For schema-enabled lakehouses, use `fab ls` to navigate:

```powershell
fab ls "RDW - Open Data.Workspace/RDWLake.Lakehouse/Tables"
```

This shows the schemas (e.g., `dbo`). Then drill in:

```powershell
fab ls "RDW - Open Data.Workspace/RDWLake.Lakehouse/Tables/dbo" -l
```

Our tables:
| Table | Description |
|-------|-------------|
| `gekentekende_voertuigen` | Vehicle registrations (~90 columns) |
| `gekentekende_voertuigen_brandstof` | Fuel/emission data (~42 columns) |
| `brandstoffen_op_pc4` | Fuel type counts by postal code (5 columns) |
| `parkeeradres` | Parking facility addresses (12 columns) |
| `specificaties_parkeergebied` | Parking area specs (9 columns) |

### 5.4 Get Table Schemas

```powershell
fab table schema "RDW - Open Data.Workspace/RDWLake.Lakehouse/Tables/dbo/gekentekende_voertuigen"
fab table schema "RDW - Open Data.Workspace/RDWLake.Lakehouse/Tables/dbo/gekentekende_voertuigen_brandstof"
fab table schema "RDW - Open Data.Workspace/RDWLake.Lakehouse/Tables/dbo/brandstoffen_op_pc4"
fab table schema "RDW - Open Data.Workspace/RDWLake.Lakehouse/Tables/dbo/parkeeradres"
fab table schema "RDW - Open Data.Workspace/RDWLake.Lakehouse/Tables/dbo/specificaties_parkeergebied"
```

> **Tip**: The `fab api` command outputs JSON that can be piped to files. The `fab ls` command uses ANSI terminal rendering — use `fab api` for programmatic queries and `fab ls` / `fab table schema` for interactive exploration.

---

## Part 6: Propose the Change (AI-Driven)

This is where the AI agent takes your natural language description and creates a full specification.

### 6.1 Create the OpenSpec Change

In VS Code Chat (`Ctrl+Shift+I`), use the `/propose` slash command with a detailed description of what you want to build. The more context you give, the better the result:

> `/propose` in the fabric workspace RDW - Open Data I have some data in the lakehouse in the tables section. create a shortcut to a new workspace, called RDWAgents, running on the trial capacity. And create an end 2 end medallion environment. All in the same lakehouse, with different schema's. For the gold layer. See how you get a nice dimensional model. The model should be optimized for analysing outliers and all kind of counts. Also create some nice reports on top of it. Use my squad to build all of this and let me know if things are not clear.

The AI agent will:
1. **Create the change**: `openspec change create "rdw-medallion-environment"`
2. **Get build order**: `openspec artifact buildOrder --change "rdw-medallion-environment" --json`
3. **Query your Fabric environment** using `fab` CLI to discover tables and schemas
4. **Generate all artifacts**:
   - `proposal.md` — WHY: motivation, what changes, capabilities, impact
   - `design.md` — HOW: technical decisions, architecture, risks
   - `specs/<capability>/spec.md` — WHAT: testable requirements (WHEN/THEN scenarios)
   - `tasks.md` — Implementation checklist with checkboxes

> **What happens behind the scenes**: The agent reads the OpenSpec skill instructions, runs `fab api` commands to discover your workspace, lakehouse, and table schemas, then generates all four artifact types based on what it finds. This typically takes 2-5 minutes.

### 6.2 What Gets Generated

The agent creates these files in `openspec/changes/rdw-medallion-environment/`:

```
proposal.md           ← Business case and scope
design.md             ← Architecture decisions
specs/
  workspace-setup/spec.md       ← Workspace & shortcut requirements
  bronze-to-silver/spec.md      ← Data cleansing requirements
  silver-to-gold/spec.md        ← Dimensional model requirements
  semantic-model/spec.md        ← Power BI model requirements
  reports/spec.md               ← Dashboard requirements
tasks.md              ← 43 implementation tasks
```

### 6.3 Verify

```powershell
openspec status --change "rdw-medallion-environment"
```

Expected output:
```
Change: rdw-medallion-environment
Schema: spec-driven
Progress: 4/4 artifacts complete

[x] proposal
[x] design
[x] specs
[x] tasks

All artifacts complete!
```

---

## Part 7: Implement — Infrastructure Setup

Now tell the AI agent to start implementing, or do it manually step by step.

### 7.1 Create the RDWAgents Workspace

Create a JSON body file (`ws_body.json`):
```json
{
  "displayName": "RDWAgents",
  "capacityId": "<your-trial-capacity-id>"
}
```

```powershell
fab api -X post "workspaces" -i "ws_body.json"
```

Note the workspace ID from the response.

### 7.2 Create the Schema-Enabled Lakehouse

Create `lh_body.json`:
```json
{
  "displayName": "RDWAgentsLake",
  "type": "Lakehouse",
  "creationPayload": {
    "enableSchemas": true
  }
}
```

```powershell
fab api -X post "workspaces/<rdwagents-workspace-id>/items" -i "lh_body.json"
```

### 7.3 Create OneLake Shortcuts

For each source table, create a shortcut body file:
```json
{
  "path": "Tables/bronze",
  "name": "gekentekende_voertuigen",
  "target": {
    "oneLake": {
      "workspaceId": "<source-workspace-id>",
      "itemId": "<source-lakehouse-id>",
      "path": "Tables/dbo/gekentekende_voertuigen"
    }
  }
}
```

```powershell
fab api -X post "workspaces/<rdwagents-ws-id>/items/<lakehouse-id>/shortcuts" -i "shortcut.json"
```

Repeat for all 5 tables: `gekentekende_voertuigen`, `gekentekende_voertuigen_brandstof`, `brandstoffen_op_pc4`, `parkeeradres`, `specificaties_parkeergebied`.

---

## Part 8: Implement — Bronze to Silver Notebook

Create a PySpark notebook `01_bronze_to_silver` in the `RDWAgents` workspace. This notebook reads from the Bronze shortcuts and writes cleansed data to the Silver schema.

### Key transformations:

```python
# Create schemas
spark.sql("CREATE SCHEMA IF NOT EXISTS silver")

# Read bronze (shortcut) table
df = spark.read.table("bronze.gekentekende_voertuigen")

# Column renaming: CamelCase → snake_case
import re
for col in df.columns:
    new_name = re.sub(r'[^a-zA-Z0-9]', '_', col).lower()
    new_name = re.sub(r'_+', '_', new_name).strip('_')
    df = df.withColumnRenamed(col, new_name)

# Date parsing (integer YYYYMMDD → date)
from pyspark.sql.functions import to_date, col, when, lit
df = df.withColumn("vervaldatum_apk",
    to_date(col("vervaldatum_apk").cast("string"), "yyyyMMdd"))

# Numeric casting (string → integer/double)
df = df.withColumn("bruto_bpm", col("bruto_bpm").cast("integer"))
df = df.withColumn("catalogusprijs", col("catalogusprijs").cast("double"))

# Deduplication
df = df.dropDuplicates(["kenteken"])

# Write to Silver
df.write.mode("overwrite").saveAsTable("silver.vehicles")
```

Repeat similar transformations for each table:
- `silver.vehicle_fuels` (from `bronze.gekentekende_voertuigen_brandstof`)
- `silver.fuels_by_postal_code` (from `bronze.brandstoffen_op_pc4`)
- `silver.parking_addresses` (from `bronze.parkeeradres`)
- `silver.parking_area_specs` (from `bronze.specificaties_parkeergebied`)

> **Note for parking specs**: Convert epoch milliseconds to date:
> ```python
> from pyspark.sql.functions import from_unixtime
> df = df.withColumn("start_date", from_unixtime(col("startdatespecifications") / 1000).cast("date"))
> ```

---

## Part 9: Implement — Silver to Gold Notebook

Create `02_silver_to_gold` notebook. This builds the dimensional star model.

### Dimensions:

```python
spark.sql("CREATE SCHEMA IF NOT EXISTS gold")

# dim_vehicle
from pyspark.sql.functions import monotonically_increasing_id

dim_vehicle = spark.read.table("silver.vehicles") \
    .select("kenteken", "voertuigsoort", "merk", "handelsbenaming",
            "inrichting", "eerste_kleur", "tweede_kleur",
            "europese_voertuigcategorie", "subcategorie_nederland",
            "aantal_zitplaatsen", "aantal_deuren", "aantal_wielen",
            "massa_ledig_voertuig", "massa_rijklaar",
            "cilinderinhoud", "aantal_cilinders") \
    .dropDuplicates(["kenteken"]) \
    .withColumn("vehicle_key", monotonically_increasing_id())

dim_vehicle.write.mode("overwrite").saveAsTable("gold.dim_vehicle")
```

Similarly create:
- `gold.dim_fuel_type` — distinct fuel type attributes
- `gold.dim_location` — union postal codes from fuels + parking
- `gold.dim_parking_area` — parking area attributes
- `gold.dim_date` — generated date range

### Fact tables:

```python
# fact_vehicle_registration
vehicles = spark.read.table("silver.vehicles")
dim_v = spark.read.table("gold.dim_vehicle").select("kenteken", "vehicle_key")

fact_reg = vehicles.join(dim_v, "kenteken") \
    .select("vehicle_key", "bruto_bpm", "catalogusprijs",
            "massa_rijklaar", "massa_ledig_voertuig",
            "cilinderinhoud", "aantal_cilinders",
            "maximale_constructiesnelheid", "laadvermogen",
            "datum_eerste_toelating", "datum_tenaamstelling",
            "vervaldatum_apk")

fact_reg.write.mode("overwrite").saveAsTable("gold.fact_vehicle_registration")
```

---

## Part 10: Implement — Semantic Model & Reports

Now that your Gold layer is ready with 5 dimensions and 4 facts, it's time to create a semantic model for analytics and reporting.

### 10.1 Create the Semantic Model via Fabric Portal

**Navigation:**
1. Open Fabric portal: https://app.fabric.microsoft.com
2. Navigate to **RDWAgents** workspace
3. Find **RDWAgentsLake** lakehouse
4. Click the **SQL analytics endpoint** (⚡ icon next to lakehouse name)

**Create Model:**
1. In the SQL endpoint view, click **Reporting** tab
2. Click **New semantic model**
3. Name: `RDW Analytics`
4. Select these tables:
   - ✅ gold.dim_vehicle
   - ✅ gold.dim_fuel_type
   - ✅ gold.dim_location
   - ✅ gold.dim_parking_area
   - ✅ gold.dim_date
   - ✅ gold.fact_vehicle_registration
   - ✅ gold.fact_vehicle_emissions
   - ✅ gold.fact_fuel_distribution
   - ✅ gold.fact_parking_capacity
5. Click **Confirm**

The semantic model is created in **Direct Lake** mode — no data import needed, real-time access to lakehouse!

### 10.2 Configure Star Schema Relationships

Open the semantic model → **Open data model** → Switch to **Model view**

**Create these relationships by dragging from fact to dimension:**

**From fact_vehicle_registration:**
- `vehicle_key` → `dim_vehicle.vehicle_key`
- `fuel_key` → `dim_fuel_type.fuel_key`
- `location_key` → `dim_location.location_key`
- `date_key` → `dim_date.date_key`

**From fact_vehicle_emissions:**
- `vehicle_key` → `dim_vehicle.vehicle_key`
- `fuel_key` → `dim_fuel_type.fuel_key`

**From fact_fuel_distribution:**
- `fuel_key` → `dim_fuel_type.fuel_key`
- `location_key` → `dim_location.location_key`
- `date_key` → `dim_date.date_key`

**From fact_parking_capacity:**
- `parking_area_key` → `dim_parking_area.parking_area_key`
- `location_key` → `dim_location.location_key`

**Total: 11 relationships**

Verify all are **Many-to-One** and **Single direction**. Click **Save**.

**Alternative (Scripted):** Run `.\semantic-model\configure-relationships.ps1` for automation

### 10.3 Add DAX Measures

In the model view, click **New measure** in the ribbon and add these:

**Vehicle Analytics:**
```dax
Total Vehicles = COUNTROWS(fact_vehicle_registration)

Avg CO2 Emissions = AVERAGE(fact_vehicle_emissions[co2_emission])

CO2 Z-Score = 
VAR AvgCO2 = CALCULATE(AVERAGE(fact_vehicle_emissions[co2_emission]), ALL(fact_vehicle_emissions))
VAR StdDevCO2 = CALCULATE(STDEV.P(fact_vehicle_emissions[co2_emission]), ALL(fact_vehicle_emissions))
RETURN DIVIDE([Avg CO2 Emissions] - AvgCO2, StdDevCO2, BLANK())

CO2 Outliers (>2 SD) = 
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
```

**Statistical Measures:**
```dax
P50 Emissions = PERCENTILE.INC(fact_vehicle_emissions[co2_emission], 0.5)
P90 Emissions = PERCENTILE.INC(fact_vehicle_emissions[co2_emission], 0.9)
P99 Emissions = PERCENTILE.INC(fact_vehicle_emissions[co2_emission], 0.99)
```

**Fuel Distribution:**
```dax
Total Fuel Distribution = SUM(fact_fuel_distribution[fuel_count])

Fuel Market Share % = 
DIVIDE(
    [Total Fuel Distribution],
    CALCULATE([Total Fuel Distribution], ALL(dim_fuel_type)),
    0
) * 100
```

**Parking Metrics:**
```dax
Total Parking Capacity = SUM(fact_parking_capacity[total_spots])

Paid Parking % = DIVIDE(SUM(fact_parking_capacity[paid_spots]), [Total Parking Capacity], 0) * 100

Disabled Parking % = DIVIDE(SUM(fact_parking_capacity[disabled_spots]), [Total Parking Capacity], 0) * 100
```

**Total: 13 DAX measures**

**Alternative (Scripted):** Run `.\semantic-model\add-dax-measures.ps1` for automation

### 10.4 Create Power BI Reports

**Option A: Fabric Web Experience**
1. In RDWAgents workspace, click **+ New** → **Report**
2. Select **RDW Analytics** semantic model
3. Create 5 pages as outlined below

**Option B: Power BI Desktop**
1. Get Data → Semantic models → **RDW Analytics**
2. Connect in **DirectQuery** mode
3. Create report pages
4. Publish to RDWAgents workspace

### Report Pages Overview

**Page 1: Fleet Composition**
- Top 20 brands (bar chart: `dim_vehicle.brand_name` × `Total Vehicles`)
- Fuel type distribution (pie chart: `dim_fuel_type.fuel_type`)
- Body type breakdown (donut chart: `dim_vehicle.body_type`)
- KPI cards: Total Vehicles, unique brands, fuel types
- Slicers: brand, fuel type, year

**Page 2: Emissions Outliers**
- Emissions distribution histogram (binned CO2 with P90/P99 lines)
- Outlier KPIs: `CO2 Outliers (>2 SD)`, `P90/P99 Emissions`
- Outlier table: brand, model, CO2, Z-score (filtered >2 or <-2)
- Scatter: CO2 vs fuel efficiency by fuel type
- Slicers: brand, Z-score range

**Page 3: Geographic Distribution**
- Vehicle density map (filled map by postal code)
- Fuel market share by province (100% stacked bar)
- Top 25 cities table (city, province, total vehicles, market share %)
- KPIs: unique postal codes, avg vehicles per code
- Slicers: province, fuel type

**Page 4: Parking Infrastructure**
- Parking capacity by city (top 20 bar chart)
- Parking type breakdown (stacked column: paid/disabled/loading)
- Parking area details table
- KPIs: Total Capacity, Paid %, Disabled %
- Slicers: city, area type

**Page 5: Trends Over Time**
- Registration trend line (date × vehicles)
- Fuel adoption timeline (stacked area by fuel type)
- Emissions trend with forecast (year × avg CO2)
- Year-over-year comparison (column chart)
- Seasonal pattern (month × avg vehicles)
- Date range slicer (affects all pages)

**Detailed instructions:** See `reports/README.md`

---

## Part 11: Key Learnings & Tips

### Service Principal Tips

- **Always use a Security Group**: Don't add SPNs directly to Fabric admin settings — use a security group so you can manage access centrally.
- **Secret expiry**: Set a reasonable expiry for your client secret. For workshops, a short-lived secret (1 day) is fine.
- **Least privilege**: In production, use workspace-scoped permissions rather than tenant-wide Fabric API access.
- **Token caching**: After `fab auth login` with SPN credentials, the token is cached locally. You don't need to re-enter the secret for every command.

### fab CLI Tips

| Command | Purpose |
|---------|---------|
| `fab auth login` | Authenticate with Fabric |
| `fab auth status` | Check auth status |
| `fab api -X get "workspaces"` | List workspaces (JSON output) |
| `fab api -X post "<endpoint>" -i "body.json"` | Create resources |
| `fab ls "<path>"` | Browse workspace contents (interactive) |
| `fab table schema "<path>"` | Show Delta table schema |

> **Important**: `fab api` outputs clean JSON. `fab ls` uses ANSI terminal rendering and can't be reliably piped to files. Use `fab api` for scripts and automation.

### Schema-Enabled Lakehouse Gotchas

- The REST API endpoint `GET .../lakehouses/{id}/tables` returns **400** for schema-enabled lakehouses (`UnsupportedOperationForSchemasEnabledLakehouse`)
- Use `fab ls` or `fab table schema` with the full path including schema: `.../Tables/dbo/tablename`
- Create schemas via `spark.sql("CREATE SCHEMA IF NOT EXISTS ...")` in notebooks

### OpenSpec Workflow

```
openspec change create "<name>"     → Create a new change
openspec instructions <artifact>    → Get template for an artifact
openspec status --change "<name>"   → Check progress
openspec instructions apply         → Get implementation instructions
```

The spec-driven schema produces: **proposal → design + specs → tasks**

### Key Architecture Decisions Made

1. **Single lakehouse, multiple schemas** (not multiple lakehouses) — simpler governance
2. **OneLake shortcuts for Bronze** — zero-copy, no data duplication
3. **PySpark notebooks** — full control over complex transformations
4. **Star schema for Gold** — optimal for Direct Lake and outlier analysis
5. **Direct Lake semantic model** — no import, no refresh needed

---

## Appendix A: Complete Tool Versions Used

| Tool | Version | Install Command |
|------|---------|----------------|
| VS Code | Latest | https://code.visualstudio.com/ |
| Git | Latest | https://git-scm.com/ |
| GitHub CLI | 2.88+ | https://cli.github.com/ |
| Node.js | LTS | https://nodejs.org/ |
| Python | 3.10+ | `uv python install` or https://python.org/ |
| uv | Latest | `irm https://astral.sh/uv/install.ps1 \| iex` |
| Fabric CLI (fab) | Latest | `uv tool install ms-fabric-cli` |
| Squad CLI | Latest | `npm install -g @bradygaster/squad-cli` |
| OpenSpec | Latest | `npm install -g @fission-ai/openspec@latest` |

## Appendix B: GitHub Repositories Used

| Repository | Purpose |
|------------|---------|
| https://github.com/microsoft/skills-for-fabric | Copilot skills for Fabric |
| https://github.com/bradygaster/squad | AI team agent framework |
| https://github.com/Fission-AI/OpenSpec | Spec-driven development CLI |

## Appendix C: Entra ID / Service Principal Setup Checklist

Use this checklist to verify your SPN setup is complete:

- [ ] App registration created in Entra ID
- [ ] Client ID copied
- [ ] Tenant ID copied  
- [ ] Client secret created and value copied
- [ ] Security group created (type: Security)
- [ ] SPN added as member of the security group
- [ ] Fabric tenant setting "Service principals can use Fabric APIs" enabled
- [ ] Security group added to the tenant setting
- [ ] Waited 15 minutes for tenant setting propagation
- [ ] `fab auth login -u <client-id> -p <secret> --tenant <tenant-id>` succeeds
- [ ] `fab auth status` shows the SPN identity

## Appendix D: Fabric Resource IDs (Example)

| Resource | ID |
|----------|-----|
| Source workspace (`RDW - Open Data`) | `e19bbf3f-5e95-41c0-bf2f-41be9e54f78c` |
| Source lakehouse (`RDWLake`) | `af7b7520-da32-400b-b7c3-ea9c7b82a47f` |
| Target workspace (`RDWAgents`) | `97b7e768-c5d2-4501-9af2-29b37be6c83c` |
| Target lakehouse (`RDWAgentsLake`) | `ac035351-73d1-4297-bfbd-6ea91e63eeba` |
| Trial capacity | `638b8321-729d-4c91-b267-33f2dfd12775` |

## Appendix E: Source Table Schemas

### gekentekende_voertuigen (key columns)
| Column | Type | Description |
|--------|------|-------------|
| Kenteken | string | License plate (PK) |
| Voertuigsoort | string | Vehicle type |
| Merk | string | Brand |
| Handelsbenaming | string | Trade name / model |
| Eerste_kleur | string | Primary color |
| Cilinderinhoud | double | Engine displacement (cc) |
| Massa_rijklaar | double | Kerb weight (kg) |
| Datum_eerste_toelating | string | First registration date |
| Vervaldatum_APK | integer | APK expiry date |
| CO2_uitstoot_gecombineerd (via brandstof) | integer | Combined CO2 (g/km) |

### gekentekende_voertuigen_brandstof (key columns)
| Column | Type | Description |
|--------|------|-------------|
| Kenteken | string | License plate (FK) |
| Brandstof_volgnummer | integer | Fuel sequence number |
| Brandstof_omschrijving | string | Fuel type description |
| CO2_uitstoot_gecombineerd | integer | Combined CO2 (g/km) |
| Brandstofverbruik_gecombineerd | double | Combined fuel consumption |
| Nettomaximumvermogen | double | Net max power (kW) |
| Actieradius | integer | Electric range (km) |

### brandstoffen_op_pc4
| Column | Type | Description |
|--------|------|-------------|
| Postcode | integer | 4-digit postal code |
| Voertuigsoort | string | Vehicle type |
| Brandstof | string | Fuel type |
| Extern_oplaadbaar | string | Externally chargeable |
| Aantal | integer | Vehicle count |

### parkeeradres
| Column | Type | Description |
|--------|------|-------------|
| ParkingAddressReference | integer | Reference ID |
| StreetName | string | Street |
| ZipCode | string | Postal code |
| Place | string | City |
| Province | string | Province |

### specificaties_parkeergebied
| Column | Type | Description |
|--------|------|-------------|
| AreaManagerId | integer | Area manager ID |
| AreaId | string | Area identifier |
| StartDateSpecifications | long | Start date (epoch ms) |
| Capacity | integer | Parking capacity |
| ChargingPointCapacity | integer | EV charging spots |
| DisabledAccess | integer | Accessible spots |
