# Power BI Reports for RDW Analytics

This guide provides step-by-step instructions for creating the Power BI reports on top of the RDW Analytics semantic model.

## Report Architecture

The report consists of **5 pages**, each focused on a specific analytical domain:

1. **Fleet Composition** - Breakdown of vehicle fleet by brand, fuel type, body type
2. **Emissions Outliers** - Identify high-emission vehicles using statistical analysis
3. **Geographic Distribution** - Map-based analysis of vehicles and fuel distribution by location
4. **Parking Infrastructure** - Parking capacity analysis by area and city
5. **Trends Over Time** - Temporal analysis of registrations and fuel adoption

---

## Prerequisites

- **RDW Analytics** semantic model created with all relationships and DAX measures
- Power BI Desktop installed (for local development) OR use Fabric web experience
- Contributor role in RDWAgents workspace

---

## Creating the Report

### Option A: Fabric Web Experience (Recommended for Workshop)

1. Navigate to **RDWAgents** workspace in Fabric portal
2. Click **+ New** → **Report**
3. Select **RDW Analytics** as the data source
4. Follow the page designs below

### Option B: Power BI Desktop

1. Open Power BI Desktop
2. Get Data → More → **Power Platform** → **Semantic models**
3. Select **RDW Analytics** from RDWAgents workspace
4. Connect in **DirectQuery** mode (NOT Import!)
5. Follow the page designs below
6. Publish to RDWAgents workspace when done

---

## Page 1: Fleet Composition

**Purpose:** High-level overview of the registered vehicle fleet

### Visuals:

#### Visual 1: Vehicles by Brand (Bar Chart)
- **Type:** Clustered bar chart
- **Axis:** `dim_vehicle.brand_name`
- **Values:** `Total Vehicles`
- **Sort by:** Total Vehicles (descending)
- **Top N:** Show top 20 brands
- **Title:** "Top 20 Vehicle Brands"

#### Visual 2: Fuel Type Distribution (Pie Chart)
- **Type:** Pie chart
- **Legend:** `dim_fuel_type.fuel_type`
- **Values:** `Fuel Market Share %`
- **Data labels:** Show percentage and category
- **Title:** "Fleet by Fuel Type"

#### Visual 3: Body Type Breakdown (Donut Chart)
- **Type:** Donut chart
- **Legend:** `dim_vehicle.body_type`
- **Values:** `Total Vehicles`
- **Title:** "Vehicle Body Types"

#### Visual 4: KPI Cards (Card Visuals)
- **Card 1:** `Total Vehicles` - Large formatted number
- **Card 2:** Count of unique brands: `DISTINCTCOUNT(dim_vehicle[brand_name])`
- **Card 3:** Count of fuel types: `DISTINCTCOUNT(dim_fuel_type[fuel_type])`

#### Visual 5: Registration Timeline (Line Chart)
- **Type:** Line chart
- **Axis:** `dim_date.full_date` (or year_month)
- **Values:** `Total Vehicles`
- **Title:** "Vehicle Registrations Over Time"

### Filters (Page Level):
- `dim_vehicle.brand_name` (multi-select slicer)
- `dim_fuel_type.fuel_type` (multi-select slicer)
- `dim_date.year` (slicer)

---

## Page 2: Emissions Outliers

**Purpose:** Identify vehicles with abnormal CO2 emissions using statistical analysis

### Visuals:

#### Visual 1: Emissions Distribution (Histogram)
- **Type:** Column chart (binned)
- **Axis:** `fact_vehicle_emissions[co2_emission]` (bin size: 20 g/km)
- **Values:** Count of vehicles
- **Add reference lines:**
  - Mean: `Avg CO2 Emissions`
  - P90: `P90 Emissions`
  - P99: `P99 Emissions`
- **Title:** "CO2 Emissions Distribution"

#### Visual 2: Outlier KPIs (Card Visuals)
- **Card 1:** `CO2 Outliers (>2 SD)`
- **Card 2:** `P90 Emissions`
- **Card 3:** `P99 Emissions`
- **Card 4:** `Avg CO2 Emissions`

#### Visual 3: Outliers by Brand (Table)
- **Type:** Table
- **Columns:**
  - `dim_vehicle.brand_name`
  - `dim_vehicle.model_name`
  - `fact_vehicle_emissions[co2_emission]`
  - `CO2 Z-Score`
- **Filter:** `CO2 Z-Score` > 2 OR < -2
- **Sort by:** `CO2 Z-Score` (descending)
- **Title:** "High-Emission Outlier Vehicles"

#### Visual 4: Z-Score Scatter Plot
- **Type:** Scatter chart
- **X-axis:** `fact_vehicle_emissions[co2_emission]`
- **Y-axis:** `fact_vehicle_emissions[fuel_efficiency]`
- **Legend:** `dim_fuel_type.fuel_type`
- **Size:** Fixed or by vehicle count
- **Title:** "Emissions vs. Fuel Efficiency"

#### Visual 5: Emissions by Fuel Type (Box Plot or Column Chart)
- **Type:** Clustered column chart with error bars
- **Axis:** `dim_fuel_type.fuel_type`
- **Values:** 
  - `Avg CO2 Emissions`
  - `P50 Emissions` (median)
  - `P90 Emissions`
- **Title:** "CO2 Emissions by Fuel Type"

### Filters (Page Level):
- `dim_vehicle.brand_name` (multi-select slicer)
- `CO2 Z-Score` (range slider: -3 to +3)

---

## Page 3: Geographic Distribution

**Purpose:** Map-based analysis of vehicle and fuel distribution across Dutch postal codes

### Visuals:

#### Visual 1: Vehicle Density Map (Filled Map)
- **Type:** Filled map (Choropleth)
- **Location:** `dim_location.postal_code` or `dim_location.city`
- **Values:** `Total Vehicles`
- **Color saturation:** By total vehicles (darker = more vehicles)
- **Tooltips:** Show postal code, city, total vehicles
- **Title:** "Vehicle Density by Postal Code"

#### Visual 2: Fuel Type by Province (Stacked Bar Chart)
- **Type:** Stacked bar chart (100%)
- **Axis:** `dim_location.province`
- **Values:** `Total Fuel Distribution`
- **Legend:** `dim_fuel_type.fuel_type`
- **Data labels:** Show percentage
- **Title:** "Fuel Type Market Share by Province"

#### Visual 3: Top Cities by Vehicles (Table)
- **Type:** Table
- **Columns:**
  - `dim_location.city`
  - `dim_location.province`
  - `Total Vehicles`
  - `Fuel Market Share %` (for filtered fuel type)
- **Sort by:** Total Vehicles (descending)
- **Top N:** 25 cities
- **Title:** "Top 25 Cities by Vehicle Count"

#### Visual 4: Postal Code KPIs (Cards)
- **Card 1:** Count of unique postal codes
- **Card 2:** Average vehicles per postal code
- **Card 3:** Province with most vehicles

### Filters (Page Level):
- `dim_location.province` (multi-select slicer)
- `dim_fuel_type.fuel_type` (multi-select slicer)

---

## Page 4: Parking Infrastructure

**Purpose:** Analysis of parking capacity, utilization, and infrastructure

### Visuals:

#### Visual 1: Parking Capacity by City (Bar Chart)
- **Type:** Clustered bar chart
- **Axis:** `dim_location.city`
- **Values:** `Total Parking Capacity`
- **Sort by:** Total Parking Capacity (descending)
- **Top N:** 20 cities
- **Title:** "Top 20 Cities by Parking Capacity"

#### Visual 2: Parking Type Breakdown (Stacked Column Chart)
- **Type:** Stacked column chart
- **Axis:** `dim_location.city` (top 10)
- **Values:** 
  - `SUM(fact_parking_capacity[paid_spots])`
  - `SUM(fact_parking_capacity[disabled_spots])`
  - `SUM(fact_parking_capacity[loading_spots])`
- **Legend:** Parking type
- **Title:** "Parking Infrastructure Breakdown"

#### Visual 3: Parking Area Details (Table)
- **Type:** Table
- **Columns:**
  - `dim_parking_area.area_name`
  - `dim_location.city`
  - `Total Parking Capacity`
  - `Paid Parking %`
  - `Disabled Parking %`
- **Sort by:** Total Parking Capacity (descending)
- **Title:** "Parking Area Details"

#### Visual 4: Parking KPIs (Cards)
- **Card 1:** `Total Parking Capacity`
- **Card 2:** `Paid Parking %`
- **Card 3:** `Disabled Parking %`

#### Visual 5: Parking Map (Filled Map - Optional)
- **Type:** Filled map
- **Location:** `dim_location.city`
- **Values:** `Total Parking Capacity`
- **Title:** "Parking Capacity by City"

### Filters (Page Level):
- `dim_location.city` (multi-select slicer)
- `dim_parking_area.area_type` (if available)

---

## Page 5: Trends Over Time

**Purpose:** Temporal analysis of vehicle registrations, fuel adoption, and emission improvements

### Visuals:

#### Visual 1: Registration Trend (Line Chart)
- **Type:** Line chart
- **Axis:** `dim_date.full_date` (continuous axis) or `dim_date.year_month`
- **Values:** `Total Vehicles`
- **Title:** "Vehicle Registrations Over Time"

#### Visual 2: Fuel Type Adoption Timeline (Stacked Area Chart)
- **Type:** Stacked area chart
- **Axis:** `dim_date.year_month`
- **Values:** `Total Fuel Distribution`
- **Legend:** `dim_fuel_type.fuel_type`
- **Title:** "Fuel Type Adoption Over Time"

#### Visual 3: Emissions Trend by Year (Line Chart with Forecast)
- **Type:** Line chart
- **Axis:** `dim_date.year`
- **Values:** `Avg CO2 Emissions`
- **Analytics pane:** Add trend line and forecast
- **Title:** "Average CO2 Emissions Trend"

#### Visual 4: Year-over-Year Comparison (Column Chart)
- **Type:** Clustered column chart
- **Axis:** `dim_date.year`
- **Values:** 
  - `Total Vehicles`
  - Calculate YoY change: 
    ```dax
    YoY Vehicle Change = 
    VAR CurrentYear = [Total Vehicles]
    VAR PreviousYear = CALCULATE([Total Vehicles], DATEADD(dim_date[full_date], -1, YEAR))
    RETURN CurrentYear - PreviousYear
    ```
- **Title:** "Year-over-Year Vehicle Registrations"

#### Visual 5: Seasonal Pattern (Column Chart)
- **Type:** Column chart
- **Axis:** `dim_date.month_name`
- **Values:** Average of `Total Vehicles` per month across all years
- **Title:** "Seasonal Registration Patterns"

### Filters (Report Level):
- `dim_date.year` (slicer - affects ALL pages)
- Date range picker (between slicer)

---

## Report Design Best Practices

### Colors:
- Use consistent color palette across all pages
- Suggested: Blue (#0078D4) for primary, Orange (#FF6B35) for secondary
- Use colorblind-friendly palettes

### Layout:
- Use grid layout (16:9 aspect ratio)
- Leave margin space (20px) around edges
- Align visuals to grid

### Interactivity:
- Enable cross-highlighting between visuals on the same page
- Use bookmarks for "Outliers Only" vs "All Vehicles" views
- Add drill-through from summary visuals to detail tables

### Performance:
- Keep Direct Lake mode (don't switch to Import)
- Use TOP N filters to limit data volume in visuals
- Avoid complex calculated columns (use measures instead)

### Accessibility:
- Add alt text to all visuals
- Use high-contrast colors
- Include data labels for key visuals
- Test with screen reader

---

## Publishing the Report

### From Fabric Web:
- Reports auto-save to the workspace
- Click **Share** to generate sharing link
- Set permissions (Viewer vs Contributor)

### From Power BI Desktop:
1. Click **File** → **Publish** → **Publish to Power BI**
2. Select **RDWAgents** workspace
3. Choose **Replace existing semantic model** if prompted
4. Click **Open report in Power BI** when done

---

## Validation Checklist

After creating all 5 pages, verify:

- [ ] All visuals load without errors
- [ ] Slicers filter correctly across pages
- [ ] Relationships produce correct aggregations
- [ ] No blank or error values in visuals
- [ ] Cross-highlighting works between visuals
- [ ] Report loads within 5 seconds (Direct Lake performance)
- [ ] All pages have meaningful titles
- [ ] Navigation between pages is intuitive

---

## Example Report Interactions

### Use Case 1: Find high-emission diesel vehicles in Utrecht
1. Go to **Emissions Outliers** page
2. Filter `dim_fuel_type.fuel_type` = "Diesel"
3. Filter `dim_location.city` = "Utrecht"
4. Check table for vehicles with Z-Score > 2

### Use Case 2: Compare parking infrastructure across provinces
1. Go to **Parking Infrastructure** page
2. Use province slicer to select multiple provinces
3. Compare `Paid Parking %` and `Disabled Parking %` KPIs
4. Review parking area details table

### Use Case 3: Analyze electric vehicle adoption trend
1. Go to **Trends Over Time** page
2. Filter `dim_fuel_type.fuel_type` = "Elektriciteit" (Electric)
3. Review fuel adoption timeline chart
4. Note growth rate and forecast

---

## Advanced: Report Automation

For programmatic report creation, you can use:

### Python with `semantic-link` library:

```python
import sempy.fabric as fabric

# Create report from semantic model
report = fabric.create_report(
    dataset="RDW Analytics",
    report_name="RDW Fleet Analysis",
    workspace="RDWAgents"
)
```

### PowerShell with Power BI REST API:

```powershell
# Clone an existing report
$body = @{
    name = "RDW Fleet Analysis"
    targetWorkspaceId = "97b7e768-c5d2-4501-9af2-29b37be6c83c"
    targetModelId = "<semantic-model-id>"
} | ConvertTo-Json

Invoke-RestMethod -Method Post `
    -Uri "https://api.powerbi.com/v1.0/myorg/reports/{sourceReportId}/Clone" `
    -Headers $headers `
    -Body $body `
    -ContentType "application/json"
```

---

## Report Templates (Optional)

To speed up workshop delivery, you can provide a `.pbit` template file:

1. Create the full report in Power BI Desktop
2. Save as **Power BI Template** (`.pbit`)
3. Distribute to workshop participants
4. Participants connect template to their own semantic model

---

## Next Steps

Once reports are created and validated:
- **Part 6:** Final validation and documentation updates
- **Optional:** Create scheduled refresh (if using Import mode)
- **Optional:** Set up alerts on outlier measures

---

## Troubleshooting

### Issue: "Visuals show (Blank)"
- **Cause:** Relationships not configured correctly
- **Solution:** Check relationships in semantic model, ensure Many-to-One direction

### Issue: "Performance is slow"
- **Cause:** Direct Lake not enabled or fallback to DirectQuery
- **Solution:** Verify semantic model is in Direct Lake mode, check capacity SKU

### Issue: "Cannot publish from desktop"
- **Cause:** Authentication or workspace permission issue
- **Solution:** Sign in with correct account, verify Contributor role

### Issue: "DAX measures return error"
- **Cause:** Column references invalid or data type mismatch
- **Solution:** Test measure in semantic model first before using in report

---

## Design Mockups

For visual reference during workshop, see:
- `reports/mockups/` folder (if created)
- Or: Open completed report in Fabric portal for inspiration

---

## Workshop Tips

- Start with Page 1 (simplest) to build confidence
- Use pre-created report template to save time
- Demonstrate one page fully, let participants create others
- Emphasize Direct Lake performance benefits
- Show live editing in web experience vs desktop
