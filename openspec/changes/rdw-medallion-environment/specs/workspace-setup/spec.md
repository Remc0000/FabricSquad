## ADDED Requirements

### Requirement: RDWAgents workspace provisioning
The system SHALL create a new Fabric workspace named `RDWAgents` assigned to the trial capacity.

#### Scenario: Workspace creation
- **WHEN** the workspace setup process is executed
- **THEN** a workspace named `RDWAgents` SHALL exist in the Fabric tenant on trial capacity

### Requirement: Lakehouse creation with schemas enabled
The system SHALL create a schema-enabled lakehouse named `RDWAgentsLake` in the `RDWAgents` workspace.

#### Scenario: Lakehouse creation
- **WHEN** the workspace is provisioned
- **THEN** a lakehouse named `RDWAgentsLake` SHALL be created with the schemas-enabled feature active
- **THEN** the lakehouse SHALL contain schemas `bronze`, `silver`, and `gold`

### Requirement: OneLake shortcut to source data
The system SHALL create OneLake shortcuts in the `bronze` schema of `RDWAgentsLake` pointing to all 5 source tables in `RDW - Open Data/RDWLake/Tables/dbo`.

#### Scenario: Shortcut creation for all source tables
- **WHEN** the lakehouse is created
- **THEN** shortcuts SHALL be created for tables: `gekentekende_voertuigen`, `gekentekende_voertuigen_brandstof`, `brandstoffen_op_pc4`, `parkeeradres`, `specificaties_parkeergebied`
- **THEN** each shortcut SHALL reference the source table via OneLake path in workspace `RDW - Open Data` (ID: `e19bbf3f-5e95-41c0-bf2f-41be9e54f78c`)

#### Scenario: Shortcut data accessibility
- **WHEN** shortcuts are created
- **THEN** querying `bronze.gekentekende_voertuigen` in Spark SHALL return the same data as the source `dbo.gekentekende_voertuigen`
- **THEN** no data duplication SHALL occur — data is read directly from the source lakehouse
