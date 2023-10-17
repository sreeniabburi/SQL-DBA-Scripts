USE MASTER
GO

SET NOCOUNT ON;

/* SQL Server Configuration Report  

Created by Sreeni Abburi on 15th OCT 2020 

15th OCT 2020 Version 1.0 - Initial build
27th OCT 2020 Version 1.1 - Audit data enhanced

----------------------- Version Control -------------------------------*/
DECLARE @ScriptVersion CHAR(4)
SET @ScriptVersion = 1.1 -- Version number of this script

/*-------------------------------------------------------------------------*/

DECLARE 
	  @CurrentDate NVARCHAR(50) -- Current data/time
	, @SQLServerName NVARCHAR(50) --Set SQL Server Name
	, @NodeName1 NVARCHAR(50) -- Name of node 1 if clustered
	, @NodeName2 NVARCHAR(50) -- Name of node 2 if clustered
	--, @NodeName3 NVARCHAR(50) /* -- remove remarks if more than 2 node cluster */
	--, @NodeName4 NVARCHAR(50) /*-- remove remarks if more than 2 node cluster */
	, @AccountName NVARCHAR(50) -- Account name used
	, @StaticPortNumber NVARCHAR(50) -- Static port number
	, @INSTANCENAME NVARCHAR(30) -- SQL Server Instance Name
	, @VALUENAME NVARCHAR(20) -- Detect account used in SQL 2005, see notes below
	, @KERB NVARCHAR(50) -- Is Kerberos used or not
	, @DomainName NVARCHAR(50) -- Name of Domain
	, @IP NVARCHAR(20)  -- IP address used by SQL Server
	, @InstallDate NVARCHAR(20) -- Installation date of SQL Server
	, @ProductVersion NVARCHAR(30) -- Production version
	, @ProductName NVARCHAR(50) -- Product Name
	, @MachineName NVARCHAR(30) -- Server name
	, @ServerName NVARCHAR(30) -- SQL Server name
	, @Instance NVARCHAR(30) --  Instance name
	, @EDITION NVARCHAR(30) --SQL Server Edition
	, @ProductLevel NVARCHAR(20) -- Product level
	, @ISClustered NVARCHAR(20) -- System clustered
	, @Standalone NVARCHAR(100) -- Standalone Server
	, @ISIntegratedSecurityOnly NVARCHAR(50) -- Security level
	, @ISSingleUser NVARCHAR(20) -- System in Single User mode
	, @COLLATION NVARCHAR(30)  -- Collation type
	, @physical_CPU_Count VARCHAR(4) -- CPU count
	, @EnvironmentType VARCHAR(15) -- Physical or Virtual
	, @MaxMemory NVARCHAR(10) -- Max memory
	, @MinMemory NVARCHAR(10) -- Min memory
	, @TotalMEMORYinBytes NVARCHAR(10) -- Total memory
	, @ErrorLogLocation VARCHAR(500) -- location of error logs
	, @traceFileLocation VARCHAR(100) -- location of trace files
	, @LinkServers VARCHAR(2) -- Number of linked servers found
	, @optimizeworkload varchar(10) -- Optimize Adhoc Workload
	, @remoteadmin varchar(10) -- Remote Admin Connections
	, @fillfactor varchar(50) -- Fill factor (%)
	, @OSVersion VARCHAR(100) -- OS Version
	, @Memory VARCHAR(MAX)
	, @NVARCHARTable1 NVARCHAR(MAX) -- This stores first table information
	, @NVARCHARTable2 NVARCHAR(MAX) -- This stores second table information
	, @NVARCHARTable3 NVARCHAR(MAX) -- This stores thrid table information
	, @Subject VARCHAR(MAX) -- Subject line of the e-Mail
	, @TO VARCHAR(100) -- Receiptent list


SET @CurrentDate = (SELECT GETDATE())
SET @ServerName = (SELECT @@SERVERNAME)
SET @Subject = 'SQL Server Build/Audit || '+ @ServerName +'||'+@CurrentDate
SET @TO='abc@email.com' -- add e-mail address
PRINT '		SQL Server Configuration Report - Version '+@ScriptVersion
PRINT '	----------------------------------------------------'
PRINT '	Report executed on '+@ServerName+' SQL Server at '+@CurrentDate
PRINT ' '

--> SQL Server Settings <--
PRINT '		** Loading sp_configure details **'
PRINT ' '
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
SELECT 
         [name]
		,[description]
		,[value] 
		,[minimum] 
		,[maximum] 
		,[value_in_use]
INTO #SQL_Server_Settings
FROM master.sys.configurations;		

EXEC sp_configure 'show advanced options', 0;
RECONFIGURE;
PRINT ' '
PRINT '		**	sp_configure details loaded **'
PRINT ' ';

-- Detecting setting
----------------------------------------------------------------
PRINT '		******** SQL Server Summary ********'
PRINT ' '
SET @SQLServerName = (SELECT @@ServerName) -- SQL Server name
PRINT '	Detection of SQL Server name\Instance name --> '+@SQLServerName
------------------------------------------------------------------------
SET @InstallDate = (SELECT  createdate FROM sys.syslogins where sid = 0x010100000000000512000000)
PRINT '	Detection of Installation Date --> '+@InstallDate
------------------------------------------------------------------------
SET @MachineName = (SELECT CONVERT(char(100), SERVERPROPERTY('MachineName'))) 
SET @OSVersion = (SELECT SUBStrING(@@VERSION,CHARINDEX('Windows',@@VERSION,0),100))
PRINT '	Detection of Machine Name --> '+@MachineName
Print '	Detection of OS Version --> ' +@OSVersion
------------------------------------------------------------------------
SET @physical_CPU_Count = (SELECT cpu_count FROM sys.dm_os_sys_info)
PRINT '	Detection of Logical CPU Count --> '+@physical_CPU_Count
------------------------------------------------------------------------
SET @Memory=(select (total_physical_memory_kb/1024) from  sys.dm_os_sys_memory)
PRINT ' Detection of Physical Memory --> '+@Memory
------------------------------------------------------------------------
--SELECT DEC.local_net_address INTO #IP FROM sys.dm_exec_connections AS DEC WHERE DEC.session_id = @@SPID;
----SET @IP = (SELECT DEC.Local_Net_Address FROM sys.dm_exec_connections AS DEC WHERE DEC.session_id = @@SPID)
--SET @IP=(SELECT TOP(1) local_net_address FROM sys.dm_exec_connections WHERE sys.dm_exec_connections.local_net_address IS NOT NULL)
--PRINT '	Detection of IP Address --> '+@IP;
------------------------------------------------------------------------
-- Formatting and loading data into @NVARCHARTable1

SET @NVARCHARTable1='<HTML><header>
<style type="text/css">
table.gridtable {
	font-family: verdana,arial,sans-serif;
	color:#333333;
	border-width: 1px;
	border-color: #0101DF;
	border-collapse: collapse;
}
table.gridtable th {
	border-width: 1px;
	padding: 8px;
	border-style: solid;
	border-color: #0101DF;
	background-color: #C2E0FF;
	color: #0101DF;
	text-align: center;
	font-size:12px;
}
table.gridtable tr:nth-child(odd)	{ background-color:#BDBDBD; }
table.gridtable tr:nth-child(even)  { background-color:#FFFFFF; }
table.gridtable td {
	border-width: 1px;
	padding: 8px;
	border-style: solid;
	border-color: #0101DF;
	background-color: #FFFFFF;
	color: #0101DF;
	font-size:11px;
	text-align:center;
}
</style>
</header>
<body><H4 align=center>SQL Server Build/Audit Sheet</H4></br>
<table border="1" width="1300" ><tr><td style="text-align:center" colspan="7">Server Information</td></tr><tr><td align="center">SQL Instance name</td><td align="center">SQL Installed Date</td><td align="center">Machine Name</td><td align="center">OS Version</td><td align="center">CPU Count</td><td align="center">Memory MB</td></tr>
'
SET @NVARCHARTable1+='<tr><td align="center">'+@SQLServerName+'</td><td align="center">'+@InstallDate+'</td><td align="center">'+@MachineName+'</td><td align="center">'+@OSVersion+'</td><td align="center">'+@physical_CPU_Count+'</td><td align="center">'+@Memory+'</td></tr></table>'
--print @NVARCHARTable1
------------------------------------------------------------------------

IF (SELECT CONVERT(char(130), SERVERPROPERTY('InstanceName'))) IS NULL
	SET @InstanceName = 'MSSQLSERVER (Default)'
ELSE	
	SET @InstanceName = (select @@SERVERNAME)
PRINT '	Detection of Instance Name --> '+@InstanceName
SET @EDITION = (SELECT CONVERT(char(130), SERVERPROPERTY('EDITION')))
PRINT '	Detection of Edition and BIT Level --> '+@EDITION 
------------------------------------------------------------------------
SET @ProductLevel = (SELECT CONVERT(char(30), SERVERPROPERTY('ProductLevel')))
PRINT '	Detection of Production Service Pack Level --> '+@ProductLevel 
SET @ProductVersion = (SELECT CONVERT(char(30), SERVERPROPERTY('ProductVersion')))
PRINT '	Detection of Production Version --> '+@ProductVersion
------------------------------------------------------------------------
IF @ProductVersion LIKE '9.0%' SET @ProductName =  'SQL Server 2005'  
IF @ProductVersion LIKE '10.0%'  SET @ProductName = 'SQL Server 2008' 
IF @ProductVersion LIKE '10.50%' SET @ProductName = 'SQL Server 2008R2' 
IF @ProductVersion LIKE '11.0%' SET @ProductName =  'SQL Server 2012' 
IF @ProductVersion LIKE '12.0%' SET @ProductName =  'SQL Server 2014' 
IF @ProductVersion LIKE '13.0%' SET @ProductName =  'SQL Server 2016'  
IF @ProductVersion LIKE '14.0%' SET @ProductName =  'SQL Server 2017'
IF @ProductVersion LIKE '15.0%' SET @ProductName =  'SQL Server 2019'  
------------------------------------------------------------------------
PRINT '	Detection of Production Version --> '+@ProductName 
PRINT ' '
------------------------------------------------------------------------

--if @ProductVersion not like '10.0%' and @ProductVersion not like '10.5%'
--begin
--IF(SELECT virtual_machine_type FROM sys.dm_os_sys_info) = 1
--SET @EnvironmentType = 'Virtual'
--ELSE
--SET @EnvironmentType = 'Physical'
--PRINT '	Detection of Environment Type --> '+@EnvironmentType
--end
------------------------------------------------------------------------
IF (SELECT CONVERT(char(30), SERVERPROPERTY('ISClustered'))) = 1
	SET @ISClustered = 'Clustered'
ELSE
	SET @ISClustered = 'Standalone'
PRINT '	Detection of Clustered Status --> '+@ISClustered 

------------------------------------------------------------------------
-- SQL Instance Information Table

SET @NVARCHARTable1+='<table border="1" width="1300" ><th style="text-align:center" colspan="8">SQL Instance Details</th><tr><td align="center">SQL Instance Type</td><td align="center">SQL Instance name</td><td align="center">SQL Edition (x64/x32)</td><td align="center">Product Name</td><td align="center">Product Level</td><td align="center">Product Version</td></tr>'
SET @NVARCHARTable1+='<tr><td align="center">'+@ISClustered+'</td><td align="center">'+@InstanceName+'</td><td align="center">'+@EDITION+'</td><td align="center">'+@ProductName+'</td><td align="center">'+@ProductLevel+'</td><td align="center">'+@ProductVersion+'</td></tr></table>'

--Print @NVARCHARTable1
------------------------------------------------------------------------
SET @MaxMemory = (select CONVERT(char(10), [value_in_use]) from  #SQL_Server_Settings where name = 'max server memory (MB)')
SET @MinMemory = (select CONVERT(char(10), [value_in_use]) from  #SQL_Server_Settings where name = 'min server memory (MB)')
PRINT '	Detection of Maximum Memory (Megabytes) --> '+@MaxMemory
PRINT '	Detection of Minimum Memory (Megabytes) --> '+@MinMemory
------------------------------------------------------------------------
PRINT ' '
SET @optimizeworkload=(select CONVERT(char(10), [value_in_use]) from  #SQL_Server_Settings where name = 'optimize for ad hoc workloads')
SET @remoteadmin=(select CONVERT(char(10), [value_in_use]) from  #SQL_Server_Settings where name = 'remote admin connections')
SET @fillfactor=(select CONVERT(char(10), [value_in_use]) from  #SQL_Server_Settings where name = 'fill factor (%)')
PRINT '	optimize for ad hoc workloads is enabled. Run value --> '+@optimizeworkload
PRINT '	remote admin connections is enabled. Run value --> '+@remoteadmin
PRINT '	Fill factor(%) value in use --> '+@fillfactor
------------------------------------------------------------------------

SET @StaticPortNumber = (SELECT local_tcp_port FROM sys.dm_exec_connections WHERE session_id = @@SPID)
PRINT '	Detection of Port Number --> '+@StaticPortNumber
PRINT ' '
------------------------------------------------------------------------
SET @DomainName = (SELECT DEFAULT_DOMAIN())
PRINT '	Detection of Default Domain Name --> '+@DomainName
------------------------------------------------------------------------
--For Service Account Name - This line will work on SQL 2008R2 and higher only
--SET @AccountName = (SELECT top 1 service_account FROM sys.dm_server_services)
--So the lines below are being used until SQL 2005 is removed/upgraded
EXECUTE  master.dbo.xp_instance_regread
		@rootkey      = N'HKEY_LOCAL_MACHINE',
		@key          = N'SYSTEM\CurrentControlSet\Services\MSSQLServer',
		@value_name   = N'ObjectName',
		@value        = @AccountName OUTPUT
PRINT '	Detection of Service Account name --> '+@AccountName

------------------------------------------------------------------------
IF (SELECT CONVERT(char(30), SERVERPROPERTY('ISIntegratedSecurityOnly'))) = 1
	SET @ISIntegratedSecurityOnly = 'Windows Authentication Security Mode'
ELSE
	SET @ISIntegratedSecurityOnly = 'SQL Server And Windows Authentication Mode'
PRINT '	Detection of Security Mode --> '+@ISIntegratedSecurityOnly 
------------------------------------------------------------------------
DECLARE @AuditLevel int,
				@AuditLvltxt VARCHAR(50)
EXEC MASTER.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 
					N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel', @AuditLevel OUTPUT

SELECT @AuditLvltxt = CASE 
		WHEN @AuditLevel = 0	THEN 'None'
		WHEN @AuditLevel = 1	THEN 'Successful logins only'
		WHEN @AuditLevel = 2	THEN 'Failed logins only'
		WHEN @AuditLevel = 3	THEN 'Both successful and failed logins'
		ELSE 'Unknown'
		END
PRINT '	Detection of Audit Level --> ' + @AuditLvltxt
PRINT  ' '
------------------------------------------------------------------------
IF (SELECT CONVERT(char(30), SERVERPROPERTY('ISSingleUser'))) = 1
	SET @ISSingleUser = 'Single User'
ELSE
	SET @ISSingleUser = 'Multi User'
PRINT '	Detection of User Mode --> '+@ISSingleUser 
------------------------------------------------------------------------
SET @COLLATION = (SELECT CONVERT(char(30), SERVERPROPERTY('COLLATION')))
PRINT '	Detection of Collation Type --> '+@COLLATION 
------------------------------------------------------------------------
declare @staticport nvarchar(max),
@dynamicport nvarchar(max); 
SELECT 'TCP Port' as tcpPort, value_name, value_data into #TcpPorts
FROM sys.dm_server_registry 
WHERE registry_key LIKE '%IPALL' AND value_name in ('TcpPort','TcpDynamicPorts')
--select * from #TcpPorts

------------------------------------------------------------------------
declare @cmdexec nvarchar(max),
@IndMain nvarchar(max);
select name into #SPInfo
from sys.objects where name like 'CommandExecute' or name like 'IndexMaint'
--select * from #SPInfo
------------------------------------------------------------------------
-- Formatting the 3rd Table
--Print 'starting table 3'
SET @NVARCHARTable1+='<table border="1" width="1300" >
<tr><td style="text-align:center" colspan="2" >SQL Server Configuration Values</td></tr>
<tr><td align="center">Parameter Name</td><td align="center">Configured Value</td></tr>
<tr><td align="center">MIN Memory(MB)</td><td align="center">'+@MinMemory+'</td></tr>
<tr><td align="center">MAX Memory(MB)</td><td align="center">'+@MaxMemory+'</td></tr>
<tr><td align="center">Optimize For Adhoc Workloads</td><td align="center">'+@optimizeworkload+'</td></tr>
<tr><td align="center">Remote Admin Connections</td><td align="center">'+@remoteadmin+'</td></tr>
<tr><td align="center">Fill Factor(%) </td><td align="center">'+@fillfactor+'</td></tr>
<tr><td align="center">SQL Service Account</td><td align="center">'+@AccountName+'</td></tr>
<tr><td align="center">SQL Instance Authentication Mode</td><td align="center">'+@ISIntegratedSecurityOnly+'</td></tr>
<tr><td align="center">SQL Server Login Audit</td><td align="center">'+@AuditLvltxt+'</td></tr>
<tr><td align="center">SQL Server Instance Mode</td><td align="center">'+@ISSingleUser+'</td></tr>'

if ((select count(value_data) from #TcpPorts where value_name like 'TcpPort')>0) 
begin
  select @staticport=convert(nvarchar(max),value_data) from #TcpPorts where value_name like 'TcpPort'
  SET @NVARCHARTable1+='<tr><td align="center">SQL Server Static Port</td><td align="center">'+@staticport+'</td></tr>'
print 'static port' +@staticport
end
else
begin
select @dynamicport=convert(nvarchar(max),value_data) from #TcpPorts where value_name like 'TcpDynamicPorts'
SET @NVARCHARTable1+='<tr><td align="center">SQL Server Dynamic Port</td><td align="center">'+@dynamicport+'</td></tr>'
print 'dynamic port' +@dynamicport
end

if((select count(*) from #SPInfo where name like 'CommandExecute')>0)
begin
select @cmdexec=name from #SPInfo where name like 'CommandExecute';
 SET @NVARCHARTable1+='<tr><td align="center">Stored Procedure 1</td><td align="center">'+@cmdexec+'</td></tr>'
end
else
begin
set @cmdexec='Not Created'
SET @NVARCHARTable1+='<tr><td align="center">Stored Procedure (CommandExecute)</td><td align="center">'+@cmdexec+'</td></tr>'
end
if((select count(*) from #SPInfo where name like 'IndexMaint')>0)
begin
select @IndMain=name from #SPInfo where name like 'IndexMaint';
 SET @NVARCHARTable1+='<tr><td align="center">Stored Procedure 2</td><td align="center">'+@IndMain+'</td></tr>'
end
else
begin
set @IndMain='Not Created'
SET @NVARCHARTable1+='<tr><td align="center">Stored Procedure (IndexMaint)</td><td align="center">'+@IndMain+'</td></tr>'
end
Declare @denytrigger nvarchar(max);
if((select count(*) from sys.server_triggers where name like 'deny_user_db_drop')>0)
begin
set @denytrigger=(select name from sys.server_triggers where name like 'deny_user_db_drop')
 SET @NVARCHARTable1+='<tr><td align="center">Trigger Created</td><td align="center">'+@denytrigger+'</td></tr>'
end
else
begin
set @denytrigger='Not Created'
SET @NVARCHARTable1+='<tr><td align="center">Trigger (deny_user_db_drop)</td><td align="center">'+@denytrigger+'</td></tr>'
end
SET @NVARCHARTable1+='<tr><td align="center">SQL Server Collation</td><td align="center">'+@COLLATION+'</td></tr></table>'
print 'formating table for server configuration'
--Print @NVARCHARTable1
------------------------------------------------------------------------

--cluster node names. Modify if there are more than 2 nodes in cluster
SELECT NodeName INTO #nodes FROM sys.dm_os_cluster_nodes 
	IF @@rowcount = 0 
	BEGIN 
		SET @NodeName1 = 'NONE' -- NONE for no cluster
	END
	ELSE
	BEGIN
		SET @NodeName1 = (SELECT top 1 NodeName from #nodes)
		SET @NodeName2 = (SELECT NodeName from #nodes where NodeName <> @NodeName1)
		-- Add code here if more that 2 node cluster
    END

IF @NodeName1 = 'NONE'
BEGIN
	SET @Standalone='Standalone Server'
	PRINT '	Detection of Clustered --> SQL Server is not clustered'
END
ELSE
BEGIN
	PRINT '	Detection of cluster node 1 --> '+@NodeName1
	PRINT '	Detection of cluster node 2 --> '+@NodeName2
END
PRINT ' '
------------------------------------------------------------------------


SET @ErrorLogLocation = (SELECT REPLACE(CAST(SERVERPROPERTY('ErrorLogFileName') AS VARCHAR(500)), 'ERRORLOG',''))
PRINT '	Detection of SQL Server Errorlog Location --> ' +@ErrorLogLocation
------------------------------------------------------------------------
PRINT ' '
PRINT '	Detection of SysAdmin Members'
PRINT ' '
CREATE TABLE #SysadminInfo
(
   ServerRole Nvarchar(100),
   MemberName nvarchar(500),
   MemberSID nvarchar(100)
)
insert into #SysadminInfo
EXEC sp_helpsrvrolemember 'sysadmin'

select MemberName,ServerRole from #SysadminInfo;
SET @NVARCHARTable2=''
IF (SELECT COUNT(*) FROM #SysadminInfo) = 0
BEGIN
SET @NVARCHARTable2+='<H4>** No	Sysadmin Users Detection of **</H4>'
		PRINT '	** No	Sysadmin Users Detection of ** '
END
ELSE
BEGIN
SET @NVARCHARTable2+='<table border="1" width="1300"><th align="center" colspan="2">SysAdmin Account Information</th><tr><td align="center">Login Name</td><td align="center">Role</td></tr>
'+CAST((
	select 
	'center' AS 'td/@align' ,
	td=MemberName,
	'',
	'center' AS 'td/@align' ,
	td=ServerRole,
	'' 
	from #SysadminInfo
	  FOR
             XML PATH('tr') ,
                 TYPE
           ) AS NVARCHAR(MAX)) + N'</table>';

END
--PRINT @NVARCHARTable2

------------------------------------------------------------------------
PRINT '	Detection of SQL Service Status' 
PRINT ' '
--> SQL Server Services Status <--
CREATE TABLE #RegResult
(ResultValue NVARCHAR(4))

CREATE TABLE #ServicesServiceStatus			
( 
	 RowID INT IDENTITY(1,1)
	,ServerName NVARCHAR(30) 
	,ServiceName NVARCHAR(45)
	,ServiceStatus varchar(15)
	,StatusDateTime DATETIME DEFAULT (GETDATE())
	,PhysicalSrverName NVARCHAR(50)
)

DECLARE 
		 @ChkInstanceName nvarchar(128)				
		,@ChkSrvName nvarchar(128)					
		,@trueSrvName nvarchar(128)					
		,@SQLSrv NVARCHAR(128)						
		,@PhysicalSrvName NVARCHAR(128)			
		,@FTS nvarchar(128)						
		,@RS nvarchar(128)							
		,@SQLAgent NVARCHAR(128)				
		,@OLAP nvarchar(128)					
		,@REGKEY NVARCHAR(128)					

SET @PhysicalSrvName = CAST(SERVERPROPERTY('MachineName') AS VARCHAR(128)) 
SET @ChkSrvName = CAST(SERVERPROPERTY('INSTANCENAME') AS VARCHAR(128)) 
SET @ChkInstanceName = @@serverName

IF @ChkSrvName IS NULL							
	BEGIN 
		SET @trueSrvName = 'MSQLSERVER'
		SELECT @OLAP = 'MSSQLServerOLAPService' 	
		SELECT @FTS = 'MSFTESQL' 
		SELECT @RS = 'ReportServer' 
		SELECT @SQLAgent = 'SQLSERVERAGENT'
		SELECT @SQLSrv = 'MSSQLSERVER'
	END 
ELSE
	BEGIN
		SET @trueSrvName =  CAST(SERVERPROPERTY('INSTANCENAME') AS VARCHAR(128)) 
		SET @SQLSrv = '$'+@ChkSrvName
	 	SELECT @OLAP = 'MSOLAP' + @SQLSrv	/*Setting up proper service name*/
		SELECT @FTS = 'MSFTESQL' + @SQLSrv 
		SELECT @RS = 'ReportServer' + @SQLSrv
		SELECT @SQLAgent = 'SQLAgent' + @SQLSrv
		SELECT @SQLSrv = 'MSSQL' + @SQLSrv
	END 
;
/* ---------------------------------- SQL Server Service Section ----------------------------------------------*/
SET @REGKEY = 'System\CurrentControlSet\Services\'+@SQLSrv

INSERT #RegResult ( ResultValue ) EXEC master.sys.xp_regread @rootkey='HKEY_LOCAL_MACHINE', @key=@REGKEY

IF (SELECT ResultValue FROM #RegResult) = 1 
BEGIN
	INSERT #ServicesServiceStatus (ServiceStatus)		
	EXEC xp_servicecontrol N'QUERYSTATE',@SQLSrv
	UPDATE #ServicesServiceStatus set ServiceName = 'MS SQL Server Service' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @trueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	trUNCATE TABLE #RegResult
END
ELSE 
BEGIN
	INSERT INTO #ServicesServiceStatus (ServiceStatus) VALUES ('NOT INSTALLED')
	UPDATE #ServicesServiceStatus set ServiceName = 'MS SQL Server Service' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @trueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	trUNCATE TABLE #RegResult
END

/* ---------------------------------- SQL Server Agent Service Section -----------------------------------------*/
SET @REGKEY = 'System\CurrentControlSet\Services\'+@SQLAgent

INSERT #RegResult ( ResultValue ) EXEC master.sys.xp_regread @rootkey='HKEY_LOCAL_MACHINE', @key=@REGKEY

IF (SELECT ResultValue FROM #RegResult) = 1 
BEGIN
	INSERT #ServicesServiceStatus (ServiceStatus)		
	EXEC xp_servicecontrol N'QUERYSTATE',@SQLAgent
	UPDATE #ServicesServiceStatus set ServiceName = 'SQL Server Agent Service' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @trueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	trUNCATE TABLE #RegResult
END
ELSE 
BEGIN
	INSERT INTO #ServicesServiceStatus (ServiceStatus) VALUES ('NOT INSTALLED')
	UPDATE #ServicesServiceStatus set ServiceName = 'SQL Server Agent Service' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @trueSrvName where RowID = @@identity	
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	trUNCATE TABLE #RegResult
END

/* ---------------------------------- SQL Browser Service Section ----------------------------------------------*/
SET @REGKEY = 'System\CurrentControlSet\Services\SQLBrowser'

INSERT #RegResult ( ResultValue ) EXEC master.sys.xp_regread @rootkey='HKEY_LOCAL_MACHINE', @key=@REGKEY

IF (SELECT ResultValue FROM #RegResult) = 1 
BEGIN
	INSERT #ServicesServiceStatus (ServiceStatus)		
	EXEC master.dbo.xp_servicecontrol N'QUERYSTATE',N'sqlbrowser'
	UPDATE #ServicesServiceStatus set ServiceName = 'SQL Browser Service - Instance Independent' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @trueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	trUNCATE TABLE #RegResult
END
ELSE 
BEGIN
	INSERT INTO #ServicesServiceStatus (ServiceStatus) VALUES ('NOT INSTALLED')
	UPDATE #ServicesServiceStatus set ServiceName = 'SQL Browser Service - Instance Independent' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @trueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	trUNCATE TABLE #RegResult
END

/* ---------------------------------- Integration Service Section ----------------------------------------------*/
SET @REGKEY = 'System\CurrentControlSet\Services\MsDtsServer'

INSERT #RegResult ( ResultValue ) EXEC master.sys.xp_regread @rootkey='HKEY_LOCAL_MACHINE', @key=@REGKEY

IF (SELECT ResultValue FROM #RegResult) = 1 
BEGIN
	INSERT #ServicesServiceStatus (ServiceStatus)		
	EXEC master.dbo.xp_servicecontrol N'QUERYSTATE',N'MsDtsServer'
	UPDATE #ServicesServiceStatus set ServiceName = 'Integration Service - Instance Independent' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @trueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	trUNCATE TABLE #RegResult
END
ELSE 
BEGIN
	INSERT INTO #ServicesServiceStatus (ServiceStatus) VALUES ('NOT INSTALLED')
	UPDATE #ServicesServiceStatus set ServiceName = 'Intergration Service - Instance Independent' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @trueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	trUNCATE TABLE #RegResult
END

/* ---------------------------------- Reporting Service Section ------------------------------------------------*/
SET @REGKEY = 'System\CurrentControlSet\Services\'+@RS

INSERT #RegResult ( ResultValue ) EXEC master.sys.xp_regread @rootkey='HKEY_LOCAL_MACHINE', @key=@REGKEY

IF (SELECT ResultValue FROM #RegResult) = 1 
BEGIN
	INSERT #ServicesServiceStatus (ServiceStatus)		
	EXEC master.dbo.xp_servicecontrol N'QUERYSTATE',@RS
	UPDATE #ServicesServiceStatus set ServiceName = 'Reporting Service' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @trueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	trUNCATE TABLE #RegResult
END
ELSE 
BEGIN
	INSERT INTO #ServicesServiceStatus (ServiceStatus) VALUES ('NOT INSTALLED')
	UPDATE #ServicesServiceStatus set ServiceName = 'Reporting Service' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @trueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	trUNCATE TABLE #RegResult
END

/* ---------------------------------- Analysis Service Section -------------------------------------------------*/
IF @ChkSrvName IS NULL								
	BEGIN 
	SET @OLAP = 'MSSQLServerOLAPService'
	END
ELSE	
	BEGIN
	SET @OLAP = 'MSOLAP'+'$'+@ChkSrvName
	SET @REGKEY = 'System\CurrentControlSet\Services\'+@OLAP
END

INSERT #RegResult ( ResultValue ) EXEC master.sys.xp_regread @rootkey='HKEY_LOCAL_MACHINE', @key=@REGKEY

IF (SELECT ResultValue FROM #RegResult) = 1 
BEGIN
	INSERT #ServicesServiceStatus (ServiceStatus)		
	EXEC master.dbo.xp_servicecontrol N'QUERYSTATE',@OLAP
	UPDATE #ServicesServiceStatus set ServiceName = 'Analysis Services' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @trueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	trUNCATE TABLE #RegResult
END
ELSE 
BEGIN
	INSERT INTO #ServicesServiceStatus (ServiceStatus) VALUES ('NOT INSTALLED')
	UPDATE #ServicesServiceStatus set ServiceName = 'Analysis Services' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @trueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	trUNCATE TABLE #RegResult
END

/* ---------------------------------- Full Text Search Service Section -----------------------------------------*/
SET @REGKEY = 'System\CurrentControlSet\Services\'+@FTS

INSERT #RegResult ( ResultValue ) EXEC master.sys.xp_regread @rootkey='HKEY_LOCAL_MACHINE', @key=@REGKEY

IF (SELECT ResultValue FROM #RegResult) = 1 
BEGIN
	INSERT #ServicesServiceStatus (ServiceStatus)		
	EXEC master.dbo.xp_servicecontrol N'QUERYSTATE',@FTS
	UPDATE #ServicesServiceStatus set ServiceName = 'Full Text Search Service' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @trueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	trUNCATE TABLE #RegResult
END
ELSE 
BEGIN
	INSERT INTO #ServicesServiceStatus (ServiceStatus) VALUES ('NOT INSTALLED')
	UPDATE #ServicesServiceStatus set ServiceName = 'Full Text Search Service' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @trueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	trUNCATE TABLE #RegResult
END
SET @NVARCHARTable2+='<Table border="1" width="1300"><th align="center" colspan="4">SQL Server Services Status</th>
<tr><td align="center">SQL Server\Instance Name</td><td align="right">Service Name</td><td align="left">Service Status</td><td align="center">Status Date\Time</td></tr>' 
	+ CAST((
		SELECT 
			'center' AS 'td/@align' ,
			td=ServerName,
			'',
			 'right' AS 'td/@align' ,
			td=ServiceName,
			'',
			'left' AS 'td/@align' ,
			CASE WHEN [ServiceStatus] not like '%Running%' THEN '#FF0000'
                    END AS 'td/@BGCOLOR' , 
			td=ServiceStatus,
			'',
			'center' AS 'td/@align' , 
			td=StatusDateTime,
			''
			FROM  #ServicesServiceStatus	
	FOR
             XML PATH('tr') ,
                 TYPE
           ) AS NVARCHAR(MAX)) + N'</table>'	
------------------------------------------------------------------------

-- Create table to house database file information
CREATE TABLE #info (
     databasename VARCHAR(128)
     ,name VARCHAR(128)
    ,fileid INT
    ,filename VARCHAR(1000)
    ,filegroup VARCHAR(128)
    ,size VARCHAR(25)
    ,maxsize VARCHAR(25)
    ,growth VARCHAR(25)
    ,usage VARCHAR(25));
    
-- Get database file information for each database   
SET NOCOUNT ON; 
INSERT INTO #info
EXEC sp_MSforeachdb 'use [?] 
select ''?'',name,  fileid, filename,
filegroup = filegroup_name(groupid),
''size'' = convert(nvarchar(15), convert (bigint, size) * 8) + N'' KB'',
''maxsize'' = (case maxsize when -1 then N''Unlimited''
else
convert(nvarchar(15), convert (bigint, maxsize) * 8) + N'' KB'' end),
''growth'' = (case status & 0x100000 when 0x100000 then
convert(nvarchar(15), growth) + N''%''
else
convert(nvarchar(15), convert (bigint, growth) * 8) + N'' KB'' end),
''usage'' = (case status & 0x40 when 0x40 then ''log only'' else ''data only'' end)
from sysfiles
';
 
-- Identify database files that use default auto-grow properties
SET @NVARCHARTable3=''
SET @NVARCHARTable3+='<table border="1" width="1300"><th align="center" colspan="7">Basic Database Information</th>
<tr><td align="center">Database Name</td><td align="center">File Name</td><td align="center">Physical Location</td><td align="center">File Size</td><td align="center">Max File Size</td><td align="center">Auto Growth</td><td align="center">File Type</td></tr>' 
	+ CAST((	  

SELECT	
		'center' AS 'td/@align' ,
		td=CONVERT(NVARCHAR(50), databasename),
		'',
		'center' AS 'td/@align' ,
		td=CONVERT(NVARCHAR(50), name),
		'',
		'center' AS 'td/@align' ,
		td=CONVERT(NVARCHAR(MAX), filename),
		'',
		'center' AS 'td/@align' ,
		td=CONVERT(NVARCHAR(100), size),
		'',
		'center' AS 'td/@align' ,
		td=CONVERT(NVARCHAR(100), maxsize),
		'',
		'center' AS 'td/@align' ,
		td=CONVERT(NVARCHAR(100), growth),
		'',
		'center' AS 'td/@align' ,
		td=CONVERT(NVARCHAR(100), usage),
		'' 
FROM #info 
FOR
             XML PATH('tr') ,
                 TYPE
           ) AS NVARCHAR(MAX)) + N'</table>'
Print ''
--Print @NVARCHARTable3

------------------------------------------------------------------------

------------------------------------------------------------------------
PRINT '	Detection of Database Hard Drive Space Available'   
PRINT ' '
declare @NVARCHARTable4 NVARCHAR(MAX)
SET @NVARCHARTable4=''
CREATE TABLE #HD_space
	(Drive varchar(2) NOT NULL,
	[MB free] int NOT NULL)

INSERT INTO #HD_space(Drive, [MB free])
EXEC master.sys.xp_fixeddrives;

SET @NVARCHARTable4+='<Table border="1" width="1300"><th align="center" colspan="2">Disk Free Space Information</th>
<tr><td align="right">Drive Letter</td><td align="left">Free Disk Space (Megabytes)</td></tr>' 
	+ CAST((
			SELECT 
			'right' AS 'td/@align' , 
			td=Drive,
			'',
			'left' AS 'td/@align' , 
		   td=[MB free],
		   ''  
		   FROM #HD_space
		   FOR
             XML PATH('tr') ,
                 TYPE
           ) AS NVARCHAR(MAX)) + N'</table>'
	IF @@rowcount = 0 
	BEGIN 
		PRINT '** No Hard Drive Information ** '
	END
PRINT ' '
select * from #HD_space;
--Print @NVARCHARTable4
------------------------------------------------------------------------

PRINT '	Detection of SQL Job Status'
PRINT ' '

SET @NVARCHARTable4+='<Table border="1" width="1300"><th align="center" colspan="4">SQL Agent Jobs</th><tr><td align="right">Job Name</td><td align="left">Enabled</td><td align="left">Job Owner</td><td align="left">Job Notification Operator</td></tr>' 
+ CAST((
	SELECT 
	'center' AS 'td/@align' ,
	j.[name],
	'',
	'center' AS 'td/@align' ,
	j.enabled,
	'',
	'center' AS 'td/@align' ,
	SUSER_NAME(owner_sid),
	'',
	'center' AS 'td/@align' ,
	o.name,
	''
FROM msdb..[sysjobs] j
LEFT JOIN msdb..[sysoperators] o ON (j.[notify_email_operator_id] = o.[id])

FOR
             XML PATH('tr') ,
                 TYPE
           ) AS NVARCHAR(MAX)) + N'</table>'
	IF @@rowcount = 0 
	BEGIN 
	SET @NVARCHARTable4+='<Table border="1" width="1300"><th align="center">SQL Agent Jobs</th>
	<tr><td colspan="2" align="center">No SQL Agent Jobs Configured </td></tr></table>' 

		PRINT '** No Disabled Job Information ** '
	END;
PRINT ' '
--Print @NVARCHARTable4

------------------------------------------------------------------------
PRINT '	Detection of SQL Mail Information'
PRINT ' '
CREATE TABLE #Database_Mail_Details
(Status NVARCHAR(7))

IF EXISTS(SELECT * FROM master.sys.configurations WHERE configuration_id = 16386 AND value_in_use =1)
BEGIN
INSERT INTO #Database_Mail_Details (Status)
Exec msdb.dbo.sysmail_help_status_sp
END

CREATE TABLE #Database_Mail_Details2
	(principal_id VARCHAR(4)
	,principal_name VARCHAR(35)
	,profile_id VARCHAR(4)
	,profile_name VARCHAR(35)
	,is_default VARCHAR(4))

INSERT INTO #Database_Mail_Details2
	(principal_id
	,principal_name
	,profile_id
	,profile_name
	,is_default)
EXEC msdb.dbo.sysmail_help_principalprofile_sp ;

IF (SELECT COUNT (*) FROM #Database_Mail_Details) = 0
BEGIN
	SET @NVARCHARTable4+='<Table border="1" width="1300"><th align="center">Database Mail Service Status</th><tr><td align="center">Database mail Service is in Stopped/Not Configured</td></tr></Table>' 
		PRINT '** No Database Mail Service Status Information ** '
END
ELSE
BEGIN
	SET @NVARCHARTable4+='<Table border="1" width="1300"><th align="center">Database Mail Service Status</th>' 
	+ CAST((
	SELECT
	'center' AS 'td/@align'
	,td = [Status]
	 
	FROM #Database_Mail_Details
	FOR
             XML PATH('tr') ,
                 TYPE
           ) AS NVARCHAR(MAX)) + N'</table>'
END;
PRINT ' '

--print @NVARCHARTable4
SET @NVARCHARTable4+='<Table border="1" width="1300"><th align="center" colspan="5">Database Mail Profile Information</th>
<tr><td align="center">principal_id</td><td align="center">principal_name</td><td align="center">profile_id</td><td align="center">profile_name</td><td align="center">is_default</td></tr>' 
	+ CAST((
SELECT 
		'center' AS 'td/@align',
		td=principal_id,
		'',
		'center' AS 'td/@align'  
		,td=principal_name,
		'',
		'center' AS 'td/@align'
		,td=profile_id,
		''
		,
		'center' AS 'td/@align'
		,td=profile_name,
		'',
		'center' AS 'td/@align'
		,td=is_default,
		''
 FROM #Database_Mail_Details2
 FOR
             XML PATH('tr') ,
                 TYPE
           ) AS NVARCHAR(MAX)) + N'</table></body></html>'
	IF @@rowcount = 0 
	BEGIN 
		PRINT ' ** No SQL Mail Service Details Information **'

	END;
PRINT ' '
--print @NVARCHARTable4
------------------------------------------------------------------------
SELECT sys.server_audits.name as audit_name, 

 	sys.server_audit_specifications.name as server_specification_name,

 	sys.server_audit_specification_details.audit_action_name,

 	sys.server_audit_specifications.is_state_enabled
	
	into #Server_Audit_Status
 	
 	FROM sys.server_audits

 	JOIN sys.server_audit_specifications 

 	ON sys.server_audits.audit_guid = sys.server_audit_specifications.audit_guid

 	JOIN sys.server_audit_specification_details 

 	ON sys.server_audit_specifications.server_specification_id = sys.server_audit_specification_details.server_specification_id
if((select count(audit_name) from #Server_Audit_Status)>0)
begin
set @NVARCHARTable3+='<Table border="1" width="1300"><th align="center" colspan="4">SQL Server Specific Audit Information</th>
<tr><td align="center">principal_id</td><td align="center">principal_name</td><td align="center">profile_id</td><td align="center">profile_name</td><td align="center">is_default</td></tr>' 
	+ CAST((
select
	'center' AS 'td/@align', 
	td=audit_name,
	'',
	'center' AS 'td/@align',
	td=server_specification_name,
	'',
	'center' AS 'td/@align',
	td=audit_action_name,
	'',
	'center' AS 'td/@align',
	td=is_state_enabled,
	''
	from #Server_Audit_Status
	FOR
             XML PATH('tr') ,
                 TYPE
           ) AS NVARCHAR(MAX)) + N'</table>'
end
else 
begin
set @NVARCHARTable3+='<Table border="1" width="1300"><th align="center" colspan="4">Server Specific Audit Information</th>
<tr><td align="center">Server Specific Audit Not Configured</td></tr></table>'
end
------------------------------------------------------------------------
declare @body_text NVARCHAR(MAX)
SET @body_text=@NVARCHARTable1+@NVARCHARTable2+@NVARCHARTable3+@NVARCHARTable4
------------------------------------------------------------------------
declare @profilename VARCHAR(100)
SET @profilename=(select top 1 name from msdb.dbo.sysmail_profile)
--Sending e-mail as a report
EXEC msdb.dbo.sp_send_dbmail @profile_name =@profilename,
    @recipients = @to, @body =@body_text,
    @subject = @Subject, @body_format = 'HTML'
    
------------------------------------------------------------------------
-- Performing clean up

DROP TABLE #nodes;
DROP TABLE #SPInfo;
DROP TABLE #SQL_Server_Settings;
DROP TABLE #ServicesServiceStatus;	
DROP TABLE #RegResult;
DROP TABLE #HD_space;
DROP TABLE #Server_Audit_Status;
--DROP TABLE #Disabled_Jobs;
DROP TABLE #Database_Mail_Details;
DROP TABLE #Database_Mail_Details2;
DROP TABLE #info;
DROP TABLE #SysadminInfo;
drop table #TcpPorts;

GO

------------------------------------------------------------------------
PRINT ' '
PRINT '		End of SQL Server Configuration Report'
GO
