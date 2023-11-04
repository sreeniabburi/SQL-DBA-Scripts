-- ====================================================================================
-- Create external data source template for Azure Synapse SQL Analytics on-demand
-- SQL on-demand only supports the LOCATION argument within CREATE EXTERNAL DATA SOURCE
-- ====================================================================================

IF EXISTS (
  SELECT *
    FROM sys.external_data_sources	
    WHERE name = N'<data_source_name, sysname, sample_data_source>'	 
)
DROP EXTERNAL DATA SOURCE <data_source_name, sysname, sample_data_source>
GO

CREATE EXTERNAL DATA SOURCE <data_source_name, sysname, sample_data_source> WITH
(
    LOCATION = N'<location, sysname, sample_location>'
)
GO