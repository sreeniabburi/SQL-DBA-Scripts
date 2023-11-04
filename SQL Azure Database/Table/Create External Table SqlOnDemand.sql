-- ========================================================================================================
-- Create external data source template for Azure Synapse SQL Analytics on-demand
-- SQL on-demand supports only LOCATION, DATA_SOURCE and FILE_FORMAT arguments within CREATE EXTERNAL TABLE
-- ========================================================================================================

USE <database_name, sysname, AdventureWorks>
GO

IF OBJECT_ID('<schema_name, sysname, dbo>.<table_name, sysname, sample_external_table>', 'U') IS NOT NULL
    DROP EXTERNAL TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_external_table>
GO

CREATE EXTERNAL TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_external_table>
(
    <column1_name, sysname, c1> <column1_datatype, , int> <column1_nullability, >,
    <column2_name, sysname, c2> <column2_datatype, , char(10)> <column2_nullability, >,
    <column3_name, sysname, c3> <column3_datatype, , datetime> <column3_nullability, >
)
WITH
(
    LOCATION = N'<location, nvarchar(3000), sample_location>',
    DATA_SOURCE = <data_source_name, sysname, sample_data_source>,
    FILE_FORMAT = <file_format_name, sysname, sample_file_format>,
)
GO