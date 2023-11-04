-- ===============================================================
-- Create View template for Azure Synapse SQL Analytics on-demand
-- ===============================================================

IF object_id(N'<schema_name, sysname, dbo>.<view_name, sysname, Top10CovidCases>', 'V') IS NOT NULL
	DROP VIEW <schema_name, sysname, dbo>.<view_name, sysname, Top10CovidCases>
GO

CREATE VIEW <schema_name, sysname, dbo>.<view_name, sysname, Top10CovidCases> AS
<select_statement, ,
SELECT TOP 10 * FROM OPENROWSET(
        BULK     'https://pandemicdatalake.blob.core.windows.net/public/curated/covid-19/ecdc_cases/latest/ecdc_cases.parquet',
        FORMAT = 'parquet'
    ) AS [r] ORDER BY Year DESC
>