-- =======================================================================
-- Create Database Role template for Azure Synapse SQL Analytics on-demand
-- =======================================================================
-- Create the database role
CREATE ROLE <role_name, sysname, Production_Owner> AUTHORIZATION [dbo]
GO

-- Grant access rights to a specific schema in the database
GRANT 
	ALTER, 
	CONTROL, 
	DELETE, 
	EXECUTE, 
	INSERT, 
	REFERENCES, 
	SELECT, 
	TAKE OWNERSHIP, 
	UPDATE, 
	VIEW DEFINITION 
ON SCHEMA::<schema_name, sysname, Production>
	TO <role_name, sysname, Production_Owner>
GO
 
