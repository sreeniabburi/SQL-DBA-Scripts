-- ======================================================================
-- Create User as DBO template for Azure Synapse SQL Analytics on-demand
-- ======================================================================
-- For login <login_name, sysname, login_name>, create a user in the database
CREATE USER <user_name, sysname, user_name>
	FOR LOGIN <login_name, sysname, login_name>
	WITH DEFAULT_SCHEMA = <default_schema, sysname, dbo>
GO

-- Add user to the database owner role
ALTER ROLE role_name
	ADD MEMBER <user_name, sysname, user_name>