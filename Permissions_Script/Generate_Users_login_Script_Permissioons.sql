IF OBJECT_ID ('sp_hexadecimal') IS NOT NULL

  DROP PROCEDURE sp_hexadecimal

GO

CREATE PROCEDURE sp_hexadecimal

    @binvalue varbinary(256),

    @hexvalue varchar(256) OUTPUT

AS

DECLARE @charvalue varchar(256)

DECLARE @i int

DECLARE @length int

DECLARE @hexstring char(16)

SELECT @charvalue = '0x'

SELECT @i = 1

SELECT @length = DATALENGTH (@binvalue)

SELECT @hexstring = '0123456789ABCDEF' 

WHILE (@i <= @length) 

BEGIN

  DECLARE @tempint int

  DECLARE @firstint int

  DECLARE @secondint int

  SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))

  SELECT @firstint = FLOOR(@tempint/16)

  SELECT @secondint = @tempint - (@firstint*16)

  SELECT @charvalue = @charvalue +

    SUBSTRING(@hexstring, @firstint+1, 1) +

    SUBSTRING(@hexstring, @secondint+1, 1)

  SELECT @i = @i + 1

END

SELECT @hexvalue = @charvalue

GO

 

 

print 'sp_help_revlogin stored procedure created'

go

 

/*

**    Create stored procedure 'sp_help_revlogin'

*/

 

IF OBJECT_ID ('sp_help_revlogin') IS NOT NULL

      DROP PROCEDURE sp_help_revlogin

GO

 

--USE [ADMIN]

GO

/****** Object:  StoredProcedure [dbo].[sp_help_revlogin]    Script Date: 10/30/2007 10:52:05 ******/

SET ANSI_NULLS ON

GO

SET QUOTED_IDENTIFIER OFF

GO

CREATE PROCEDURE [dbo].[sp_help_revlogin] @login_name sysname = NULL AS

DECLARE @name sysname

DECLARE @type varchar (1)

DECLARE @hasaccess int

DECLARE @denylogin int

DECLARE @is_disabled int

DECLARE @PWD_varbinary  varbinary (256)

DECLARE @PWD_string  varchar (514)

DECLARE @SID_varbinary varbinary (85)

DECLARE @SID_string varchar (514)

DECLARE @tmpstr  varchar (1024)

DECLARE @is_policy_checked varchar (3)

DECLARE @is_expiration_checked varchar (3)

 

DECLARE @defaultdb sysname

 

IF (@login_name IS NULL)

  DECLARE login_curs CURSOR FOR

 

      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 

sys.server_principals p LEFT JOIN sys.syslogins l

      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name <> 'sa'

ELSE

  DECLARE login_curs CURSOR FOR

 

 

      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 

sys.server_principals p LEFT JOIN sys.syslogins l

      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name = @login_name

OPEN login_curs

 

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin

IF (@@fetch_status = -1)

BEGIN

  PRINT 'No login(s) found.'

  CLOSE login_curs

  DEALLOCATE login_curs

  RETURN -1

END

SET @tmpstr = '/* sp_help_revlogin script '

PRINT @tmpstr

SET @tmpstr = '** Generated ' + CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'

PRINT @tmpstr

PRINT ''

WHILE (@@fetch_status <> -1)

BEGIN

  IF (@@fetch_status <> -2)

  BEGIN

    PRINT ''

    SET @tmpstr = '-- Login: ' + @name

    PRINT @tmpstr

    IF (@type IN ( 'G', 'U'))

    BEGIN -- NT authenticated account/group

 

      SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']'

    END

    ELSE BEGIN -- SQL Server authentication

        -- obtain password and sid

            SET @PWD_varbinary = CAST( LOGINPROPERTY( @name, 'PasswordHash' ) AS varbinary (256) )

        EXEC sp_hexadecimal @PWD_varbinary, @PWD_string OUT

        EXEC sp_hexadecimal @SID_varbinary,@SID_string OUT

 

        -- obtain password policy state

        SELECT @is_policy_checked = CASE is_policy_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name

        SELECT @is_expiration_checked = CASE is_expiration_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name

 

            SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' + @SID_string + ', DEFAULT_DATABASE = [' + @defaultdb + ']'

 

        IF ( @is_policy_checked IS NOT NULL )

        BEGIN

          SET @tmpstr = @tmpstr + ', CHECK_POLICY = ' + @is_policy_checked

        END

        IF ( @is_expiration_checked IS NOT NULL )

        BEGIN

          SET @tmpstr = @tmpstr + ', CHECK_EXPIRATION = ' + @is_expiration_checked

        END

    END

    IF (@denylogin = 1)

    BEGIN -- login is denied access

      SET @tmpstr = @tmpstr + '; DENY CONNECT SQL TO ' + QUOTENAME( @name )

    END

    ELSE IF (@hasaccess = 0)

    BEGIN -- login exists but does not have access

      SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ' + QUOTENAME( @name )

    END

    IF (@is_disabled = 1)

    BEGIN -- login is disabled

      SET @tmpstr = @tmpstr + '; ALTER LOGIN ' + QUOTENAME( @name ) + ' DISABLE'

    END

    PRINT @tmpstr

  END

 

  FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin

   END

CLOSE login_curs

DEALLOCATE login_curs

RETURN 0

 

go

 

print 'logins-----------------------------------------------'

exec sp_help_revlogin

 

print '--ServerRoles'

set nocount on

declare @srvroles varchar(255)

declare @vnum varchar(255)

 

create table #srvroles

( srvrolename varchar(255))

 

create table #rolemember

 (rolename varchar(255), 

 rolemember varchar(255),

rolememberid varbinary(255))

 

--create table #version(vnum varchar(255))

--insert into #version

--select @@version

 

--select @vnum = vnum from #version

--if substring(@vnum,1,30) ='Microsoft SQL Server  7.00 - 7'

--begin

--    insert into #srvroles values ('sysadmin')

--    insert into #srvroles values ('securityadmin')

--    insert into #srvroles values ('serveradmin')

--    insert into #srvroles values ('setupadmin')

--    insert into #srvroles values ('processadmin')

--    insert into #srvroles values ('diskadmin')

--    insert into #srvroles values ('dbcreator')

--end

--else

--if substring(@vnum,1,30) ='Microsoft SQL Server  2000 - 8'

--begin

      insert into #srvroles values ('sysadmin')

      insert into #srvroles values ('securityadmin')

      insert into #srvroles values ('serveradmin')

      insert into #srvroles values ('setupadmin')

      insert into #srvroles values ('processadmin')

      insert into #srvroles values ('diskadmin')

      insert into #srvroles values ('dbcreator')

      insert into #srvroles values ('bulkadmin')

--end

 

declare srvroles cursor for 

select srvrolename from #srvroles

 

open srvroles

fetch next from srvroles into @srvroles

while @@fetch_status = 0

begin

      insert into #rolemember(rolename,rolemember,rolememberid)

      exec sp_helpsrvrolemember @srvroles

      fetch next from srvroles into @srvroles

 

end

select 'exec master..sp_addsrvrolemember '+''''+rolemember+''''+', '+rolename from #rolemember

where rolemember not in ('sa')

drop table #srvroles

drop table #rolemember

--drop table #version

close srvroles

deallocate srvroles

set nocount off

GO

 

--Role Memberships'

 

SELECT --rm.role_principal_id,

'EXEC sp_addrolemember @rolename =' 

+ SPACE(1) + QUOTENAME(USER_NAME(rm.role_principal_id), '''') 

+ ', @membername =' + SPACE(1) + QUOTENAME(USER_NAME(rm.member_principal_id), '''') AS '--Role Memberships'

FROM sys.database_role_members AS rm

ORDER BY rm.role_principal_id 

 

--Object Level Permissions'

SELECT 

CASE WHEN perm.state != 'W' THEN perm.state_desc ELSE 'GRANT' END + SPACE(1) + 

perm.permission_name + SPACE(1) + 'ON '+ QUOTENAME(Schema_NAME(obj.schema_id)) + '.' 

+ QUOTENAME(obj.name) collate Latin1_General_CI_AS_KS_WS 

+ CASE WHEN cl.column_id IS NULL THEN SPACE(0) ELSE '(' + QUOTENAME(cl.name) + ')' END

+ SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(usr.name)

+ CASE WHEN perm.state <> 'W' THEN SPACE(0) ELSE SPACE(1) + 'WITH GRANT OPTION' END AS '--Object Level Permissions'

FROM sys.database_permissions AS perm

INNER JOIN

sys.objects AS obj

ON perm.major_id = obj.[object_id]

INNER JOIN

sys.database_principals AS usr

ON perm.grantee_principal_id = usr.principal_id

LEFT JOIN

sys.columns AS cl

ON cl.column_id = perm.minor_id AND cl.[object_id] = perm.major_id

ORDER BY usr.name

 

--Database Level Permissions'

SELECT CASE WHEN perm.state <> 'W' THEN perm.state_desc ELSE 'GRANT' END

+ SPACE(1) + perm.permission_name + SPACE(1)

+ SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(usr.name) COLLATE database_default

+ CASE WHEN perm.state <> 'W' THEN SPACE(0) ELSE SPACE(1) + 'WITH GRANT OPTION' END AS '--Database Level Permissions'

FROM sys.database_permissions AS perm

INNER JOIN

sys.database_principals AS usr

ON perm.grantee_principal_id = usr.principal_id

WHERE 

--usr.name = @OldUser

--AND 

perm.major_id = 0

ORDER BY perm.permission_name ASC, perm.state_desc ASC

 DROP PROCEDURE sp_hexadecimal

 DROP PROCEDURE sp_help_revlogin

