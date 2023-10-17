Set nocount on


Declare 
	@vchrInstanceName varchar(255),
	@vchrDBName varchar(100),
	@tintBKStatus tinyint,
	@fSysMemoryUtil decimal(10,2),
	@vchrSysMemory varchar(10),
	@intSysMemory bigint,
	@vchrAvbMemory varchar(15),
	@fAvalMemory decimal(10,2),
	@sintTotalProc smallint,
	@sintblocking smallint,
	@sintDeadlock smallint,
	@dtStartDate datetime,
	@dtCurrentDate datetime,
	@bintTimeNow bigint,
	@tintCPU tinyint,
	@chrDrive Char(1),
	@fltFreeSpace Decimal(10,2),
	@nvchrtableHTML nvarchar(MAX),
	@nvchrEmailOperator nvarchar(100),
	@vchrEmailSubject varchar(256),
	@nvchrEmailBody nvarchar(max),
	@charEmailRecipients varchar(256),
	@charCAdd varchar(30),
	@charHost varchar(25),
	@sintConn smallint,
	@vchrMsg varchar(max),
	@dtLogDate datetime,
	@sintErrors smallint,
	@vchrFileName varchar(100),
	@fAvalSpace decimal(10,2),
	@fFreePerc decimal(5,2),
	@vchrMirrorRole varchar(20),
	@vchrMirrorStatus varchar(30),
	@runvalue bit,
	@cmd varchar(100),
	@vName varchar(256),
	@vLabel varchar(50),
	@vchrSize varchar(20),
	@vchrFree varchar(20),
	@sql nvarchar(max),
	@vchrString varchar(512),
	@debug bit,
	@nvchrprimaryserver VARCHAR(max),
	@nvchrprimarydatabase VARCHAR(max),
	@nvchrsecondaryserver VARCHAR(max),
	@nvchrrestoredelay INT,
	@nvchrtimesincelastrestore INT,
	@nvchrtimesincelastcopied INT,
	@nvchrtimesincelastbackup int,
	@nvchrlastbackupfile varchar(max),
	@sintID smallint,
	@nvchrServer_Name nvarchar(max),
	@nvchrCluster_Node nvarchar(max),
	@nvchrSQL_Instance_Name nvarchar(max),
	@nvchrSQL_Profile_Name nvarchar(max)
	,@nvchrGroupName nvarchar(250),
	@nvchrReplica nvarchar(250),
	@nvchrdatabase_name nvarchar(250),
	@nvchrrole_desc nvarchar(250),
	@nvchrAvailabilityMode nvarchar(250),
	@nvchrFailoverMode nvarchar(250),
	@nvchrListener nvarchar(250),
	@nvchrname nvarchar(128), 
	@nvchrdb_size nvarchar(50),
	@nvchrowner nvarchar(128),
	@nvchrdb_id int,
	@nvchrcreated varchar(128),
	@nvchrstatus nvarchar(2000),
	@nvchrcompatibility_level nvarchar (2000);

SELECT @vchrInstanceName = @@servername;

IF OBJECT_ID (N'tempdb..#DBName', N'U') IS NOT NULL DROP TABLE #DBName;
IF OBJECT_ID (N'tempdb..#ErrorLog', N'U') IS NOT NULL DROP TABLE #ErrorLog;
IF OBJECT_ID (N'tempdb..#FileUsage',N'U') IS NOT NULL DROP TABLE #FileUsage;
IF OBJECT_ID (N'tempdb..#DBConnections',N'U') IS NOT NULL DROP TABLE #DBConnections;
IF OBJECT_ID (N'tempdb..#DBMirrorStatus',N'U') IS NOT NULL DROP TABLE #DBMirrorStatus;
IF OBJECT_ID (N'tempdb..#LogshippingStatus',N'U') IS NOT NULL DROP TABLE #LogshippingStatus;


Set @sql = N'CREATE FUNCTION fn_splitstring
(
    @string VARCHAR(MAX),
    @delimiter CHAR(1)
)
RETURNS @output TABLE(
	id smallint identity(1,1),
    data VARCHAR(256)
)
BEGIN
    DECLARE @start INT, @end INT;
    SELECT @start = 1, @end = CHARINDEX(@delimiter, @string);

    WHILE @start < LEN(@string) + 1 
    BEGIN
        IF @end = 0 
            SET @end = LEN(@string) + 1;

        INSERT INTO @output (data)
			VALUES(SUBSTRING(@string, @start, @end - @start));
        SET @start = @end + 1;
        SET @end = CHARINDEX(@delimiter, @string, @start);
    END;
    RETURN;
END';

Exec SP_executeSQL @sql;


CREATE TABLE #DBName(db varchar(100));
INSERT INTO #DBName (db)
	SELECT sdb.Name
	From sys.databases sdb
	LEFT OUTER JOIN msdb.dbo.backupset bks ON bks.database_name = sdb.name 
	Where DB_ID(sdb.name) > 4 AND bks.type IN ('D','I') AND sdb.is_read_only = 0 
	Group by sdb.Name having Datediff(hour,MAX(bks.backup_finish_date), Getdate()) > 26
SELECT @tintBKStatus = Count(*) From #DBName;

SELECT @intSysMemory = Ceiling(total_physical_memory_kb / (1024.0*1024.0)),
	@fAvalMemory = available_physical_memory_kb /(1024.0 * 1024.0)
	From sys.dm_os_sys_memory;
Set @vchrSysMemory = Cast(@intSysMemory as varchar);
Set @fSysMemoryUtil = Cast(@intSysMemory as decimal(10,2)) - @fAvalMemory; 

SELECT @bintTimeNow = cpu_ticks/(cpu_ticks/ms_ticks) From sys.dm_os_sys_info;
SELECT TOP(1) @tintCPU = (100 - SystemIdle) From ( 
          SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS [SystemIdle] From ( 
                SELECT  convert(xml, record) as [record] From sys.dm_os_ring_buffers Where ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' and record like '%<SystemHealth>%') AS x 
          ) AS y order by record_id desc;

SELECT @sintTotalProc = Count(*) From sys.dm_exec_connections dec INNER JOIN sys.sysprocesses sp ON dec.session_id = sp.spid;

SELECT @sintblocking = Count(*) From sys.sysprocesses Where blocked <> 0;
If (@sintblocking <> 0) 
Begin 
	WaitFor Delay '00:00:30';
	SELECT @sintblocking = Count(*) From sys.sysprocesses Where blocked <> 0;
End

Set @dtStartDate = Dateadd(hour,-6,Getdate());
Set @dtCurrentDate = Getdate();
CREATE TABLE #ErrorLog (logdate datetime, ProcessID varchar(10), message text);
INSERT INTO #ErrorLog Exec xp_readerrorlog 0,1,"Deadlock", NULL,@dtStartDate,@dtCurrentDate;
SELECT @sintDeadlock = Count(*) from #ErrorLog;

-- General Parameters
SET @nvchrtableHTML = N'
<header>
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
}
</style>
</header>
';

	Set @nvchrtableHTML = @nvchrtableHTML 
		  + N'<body>'   
		  + N'<h2><Font color="#0101DF" face="verdana"><B><U><I>Server Health Check  Report at '+ Convert(varchar,@dtCurrentDate,109) +'</I></U></B></Font></h2>'
		  +N'<h5> </h5>'
		  + N'<TABLE class=gridtable>'
		  + N'<tr><th colspan="2"> General Health Information</th>';
	if(@tintBKStatus = 0) Set @nvchrtableHTML = @nvchrtableHTML + N'<tr><td> Backups </td><td> Backups are running fine </td></tr>';
	else Set @nvchrtableHTML = @nvchrtableHTML + N'<tr><td> Backups </td><td> Backups are not completed in last one day </td></tr>';
	Set @nvchrtableHTML = @nvchrtableHTML +	
	  + N'<tr><td> CPU Utilization </td><td> ' + Cast(@tintCPU as varchar) +' % </td></tr>'
	  if(@sintBlocking = 0) Set @nvchrtableHTML = @nvchrtableHTML + N'<tr><td> Blocking </td><td> ' + 'None' +'</td></tr>';
	else Set @nvchrtableHTML = @nvchrtableHTML + N'<tr><td> Blocking </td><td> ' + 'Some Blocking is there' + '</td></tr>';
	if(@sintDeadlock = 0) Set @nvchrtableHTML = @nvchrtableHTML + N'<tr><td> Deadlock </td><td> ' + 'None' +'</td></tr>';
	else Set @nvchrtableHTML = @nvchrtableHTML + N'<tr><td> Deadlock </td><td> ' + 'Deadlock was there' + '</td></tr>';
	Set @nvchrtableHTML = @nvchrtableHTML 
	Set @nvchrtableHTML = @nvchrtableHTML 
	  + N'<tr><td> Memory Utilization </td><td> ' + Cast(@fSysMemoryUtil as varchar) + ' GB </td></tr>'
	  + N'<tr><td> Available Memory </td><td> ' + Cast(@fAvalMemory as varchar)+ ' GB of ' + @vchrSysMemory + ' GB</td></tr>'
	  + N'<tr><td> Total number of connections </td><td> ' + Cast(@sintTotalProc as varchar) +'</td></tr>';

	Set @nvchrtableHTML = @nvchrtableHTML + N'</TABLE>';

-- Disk Space Info


CREATE TABLE #SPConf (name varchar(50), minimun bit, maximum bit, config bit, run bit);
INSERT INTO #SPConf 
	EXEC sp_configure 'xp_cmdshell';


SELECT @runvalue = run FROM #SPConf;
IF @runvalue = 0
BEGIN 
	EXEC sp_configure 'xp_cmdshell',1;
	reconfigure;
END;

CREATE TABLE #results (string varchar(512));
SET @cmd = 'c:\windows\system32\wbem\wmic volume where "DriveType=3" list brief /format:csv';
INSERT INTO #results 	
	EXEC @sintErrors = master..xp_cmdshell @cmd;
	
IF @runvalue = 0
BEGIN 
	EXEC sp_configure 'xp_cmdshell',0;
	reconfigure;
END;

Set @nvchrtableHTML = @nvchrtableHTML 
	  + N'<br>&nbsp; <br/>'
	  + N'<TABLE class=gridtable>'
	  + N'<tr><th colspan="4">Disk Information</th>'
	  + N'<tr>'
			+ N'<th> Name</th>'
			+ N'<th> Label</th>'
			+ N'<th> Free Space (GB)</th>'
			+ N'<th> Size (GB)</th>'
  	  + N'</tr>';
  	  
CREATE TABLE #display (id smallint Identity(1,1), value varchar(512));  			
IF (@sintErrors = 0) 
BEGIN
	DECLARE DiskSpace_Cursor CURSOR FOR SELECT string FROM #results Where string IS NOT NULL OR LTRIM(RTRIM(string)) <> '';
	OPEN DiskSpace_Cursor;
	FETCH NEXT FROM DiskSpace_Cursor INTO @vchrString;
	FETCH NEXT FROM DiskSpace_Cursor INTO @vchrString;
	FETCH NEXT FROM DiskSpace_Cursor INTO @vchrString;
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		Set @nvchrtableHTML = @nvchrtableHTML + N'<tr>';
		DECLARE temp_Cursor CURSOR FOR Select * from fn_splitstring(LTRIM(RTRIM(@vchrString)),',') WHERE ID IN (2,5,6,7) ORDER BY ID DESC;
		OPEN temp_Cursor;
		FETCH NEXT FROM temp_Cursor INTO @sintID,@vName;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF LTRIM(RTRIM(@vName)) NOT IN ('Name','Label','Capacity','FreeSpace','')
			BEGIN
				--print Cast(@sintID AS varchar)
				--print @vName
				IF @sintID IN (6,7)
				BEGIN
					Set @nvchrtableHTML = @nvchrtableHTML + 
						+ N'<td>' + LTRIM(RTRIM(@vName)) + N'</td>';
				END
				IF @sintID IN (2,5)
				BEGIN
					Set @nvchrtableHTML = @nvchrtableHTML + 
						+ N'<td>' + Cast(Cast(Cast(LTRIM(RTRIM(@vName)) AS bigint)/(1024*1024*1024.0) AS Decimal(8,3)) AS varchar) + N'</td>';
				END
				FETCH NEXT FROM temp_Cursor INTO @sintID,@vName;
			END
		END
		Close temp_Cursor;
		Deallocate temp_Cursor;
		Set @nvchrtableHTML = @nvchrtableHTML + N'</tr>';
		FETCH NEXT FROM DiskSpace_Cursor INTO @vchrString;
	END
	Close DiskSpace_Cursor;
	Deallocate DiskSpace_Cursor;
END
ELSE
BEGIN
	Set @nvchrtableHTML = @nvchrtableHTML + N'<tr><td colspan="4"> Not able to get details </td></tr>';
END

Set @nvchrtableHTML = @nvchrtableHTML + N'</TABLE>';



-- Connections per Host

CREATE TABLE #DBConnections(db varchar(100), Conn smallint); 
INSERT INTO #DBConnections (db,Conn)
	SELECT DB_NAME(dbid), count(*) FROM sys.dm_exec_connections dec 
		INNER JOIN sys.sysprocesses sp ON dec.session_id = sp.spid 
		WHERE DB_NAME(dbid) NOT IN ('master','msdb','model','tempdb','sysutility_mdw','DBA_ADMIN')
		GROUP BY DB_NAME(dbid)
		ORDER BY 2 DESC;

Set @nvchrtableHTML = @nvchrtableHTML 
		  + N'<br>&nbsp; <br/>'
		  + N'<TABLE class=gridtable>'	
		  + N'<tr><th colspan="2">Per User Database Connections</th></tr>'
		  + N'<tr><th> DatabaseName</th><th> Total Connections</th></tr>';
				
SET @vchrDBName = NULL;
DECLARE DBConn_Cursor CURSOR FOR SELECT * FROM #DBConnections;
OPEN DBConn_Cursor;
FETCH NEXT FROM DBConn_Cursor INTO @vchrDBName, @sintConn;
WHILE @@FETCH_STATUS = 0
BEGIN 
	Set @nvchrtableHTML = @nvchrtableHTML 
			+ N'<tr><td> '+ @vchrDBName + N'</td>'
			+ N'<td> '+ Cast(@sintConn AS varchar)+ N' </td>'
			+ N'</tr>';
	Fetch Next from DBConn_Cursor INTO @vchrDBName, @sintConn;
END
Close DBConn_Cursor
Deallocate DBConn_Cursor

Set @nvchrtableHTML = @nvchrtableHTML + N'</TABLE>';

-- Cluster Information

CREATE TABLE #ClusterInfo (Server_Name nvarchar(max),Cluster_Node nvarchar(max),SQL_Instance_Name nvarchar(max)); 

INSERT INTO #ClusterInfo (Server_Name,Cluster_Node,SQL_Instance_Name)
	SELECT convert(nvarchar,SERVERPROPERTY('MachineName')),convert(nvarchar,SERVERPROPERTY('ComputerNamePhysicalNetBIOS')),convert(nvarchar,SERVERPROPERTY('ServerName'))

Set @nvchrtableHTML = @nvchrtableHTML 
		  + N'<br>&nbsp; <br/>'
		  + N'<TABLE class=gridtable>'
		  + N'<tr><th colspan="4" text-align:center> Cluster Information</th></tr>'
		  + N'<br><tr><th>Server Name</th>'
				+ N'<th> Cluster Node</th>'
				+ N'<th> SQL Instance Name</th></tr>';

IF ((SELECT SERVERPROPERTY('IsClustered'))= 1) 
BEGIN
	DECLARE Cluster_Cursor CURSOR FOR SELECT * FROM #ClusterInfo;
	
	OPEN Cluster_Cursor;
	FETCH NEXT FROM Cluster_Cursor INTO @nvchrServer_Name,@nvchrCluster_Node,@nvchrSQL_Instance_Name;
	
	
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		Set @nvchrtableHTML = @nvchrtableHTML 
				+ N'<tr><td> '+ CONVERT(VARCHAR(max),@nvchrServer_Name) + N'</td>'
				+ N'<td> '+ CONVERT(VARCHAR(max),@nvchrCluster_Node) + N'</td>'
				+ N'<td> '+ CONVERT(VARCHAR(max),@nvchrSQL_Instance_Name)  + N'</td>'
				+ N'</tr>';
			--Print @nvchrServer_Name;	
			--Print @nvchrCluster_Node;
			--Print @nvchrSQL_Instance_Name;
		FETCH NEXT FROM Cluster_Cursor INTO  @nvchrServer_Name,@nvchrCluster_Node,@nvchrSQL_Instance_Name;
	END
	Close Cluster_Cursor
	Deallocate Cluster_Cursor
	
	
END
ELSE
BEGIN
declare @servname varchar(max);
set @servname = CONVERT(varchar(max),@@SERVERNAME);
	Set @nvchrtableHTML = @nvchrtableHTML + N'<tr><td colspan="4" text-align:center> This is Standalone Server '+@servname+' </td></tr>';
	-- Print @servname
END

Set @nvchrtableHTML = @nvchrtableHTML + N'</TABLE>';


-- Always on Status Display
declare @prodversion varchar(40);
declare @pos int;
declare @version varchar(10);
set @prodversion=(CONVERT(varchar,(select SERVERPROPERTY ('ProductVersion'))));
set @pos=(select CHARINDEX('.',@prodversion));

set @version=(CONVERT(int,(select SUBSTRING(@prodversion,1,@pos-1))));
if(@version>10)
begin

CREATE TABLE #AlwaysOnStatus (GroupName varchar(200),Replica_Name nvarchar(250),databasename varchar(250),role_desc nvarchar(250),AvailabilityMode nvarchar(250),FailoverMode nvarchar(250),Listener nvarchar(250));

INSERT INTO #AlwaysOnStatus (GroupName,Replica_Name,databasename,role_desc,AvailabilityMode,FailoverMode,Listener)
(SELECT
    ag.name 
   ,cs.replica_server_name
   ,drcs.database_name
   ,rs.role_desc
   ,REPLACE(ar.availability_mode_desc,'_',' ')
   ,ar.failover_mode_desc
   ,al.dns_name
FROM sys.availability_groups ag
JOIN sys.dm_hadr_availability_group_states ags ON ag.group_id = ags.group_id
JOIN sys.dm_hadr_availability_replica_cluster_states cs ON ags.group_id = cs.group_id 
JOIN sys.availability_replicas ar ON ar.replica_id = cs.replica_id 
JOIN sys.dm_hadr_availability_replica_states rs  ON rs.replica_id = cs.replica_id 
LEFT JOIN sys.availability_group_listeners al ON ar.group_id = al.group_id
inner join sys.dm_hadr_database_replica_cluster_states drcs
on drcs.replica_id=cs.replica_id)
Set @nvchrtableHTML = @nvchrtableHTML 
		  + N'<br>&nbsp; <br/>'
		  + N'<TABLE class=gridtable>'
		  + N'<tr><th colspan="7" text-align:center> AlwaysON Status </th></tr>'
		  + N'<br><tr><th>GroupName</th>'
				+ N'<th> Replica</th>'
				+ N'<th> DB Name </th>'
				+ N'<th> Role Desc</th>'
				+ N'<th> AvailabilityMode</th>'
				+ N'<th> FailoverMode</th>'
				+ N'<th> Listener</th></tr>';

SET @vchrDBName = NULL;
SELECT  @sintErrors = COUNT(*) From #AlwaysOnStatus;

IF (@sintErrors >= 1) 
BEGIN
	DECLARE AlwaysOnStatus_Cursor CURSOR FOR SELECT * FROM #AlwaysOnStatus;
	
	OPEN AlwaysOnStatus_Cursor;
	FETCH NEXT FROM AlwaysOnStatus_Cursor INTO @nvchrGroupName,@nvchrReplica,@nvchrdatabase_name,@nvchrrole_desc,@nvchrAvailabilityMode,@nvchrFailoverMode,@nvchrListener;
	
	
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		Set @nvchrtableHTML = @nvchrtableHTML 
				+ N'<tr><td> '+ CONVERT(VARCHAR(max),@nvchrGroupName) + N'</td>'
				+ N'<td> '+ CONVERT(VARCHAR(max),@nvchrReplica) + N'</td>'
				+ N'<td> '+ CONVERT(VARCHAR(max),@nvchrdatabase_name)  + N'</td>'
				+ N'<td> '+ CONVERT(VARCHAR(max),@nvchrrole_desc) + N'</td>'
				+ N'<td> '+ CONVERT(VARCHAR(max),@nvchrAvailabilityMode) + N'</td>'
				+ N'<td> '+ CONVERT(VARCHAR(max),@nvchrFailoverMode)  + N'</td>'
				+ N'<td> '+ CONVERT(VARCHAR(max),@nvchrListener) + N'</td>'
				+ N'</tr>';
			--Print @nvchrprimaryserver;	
			--Print @nvchrprimarydatabase;
			--Print @nvchrsecondaryserver;
		FETCH NEXT FROM AlwaysOnStatus_Cursor INTO  @nvchrGroupName,@nvchrReplica,@nvchrdatabase_name,@nvchrrole_desc,@nvchrAvailabilityMode,@nvchrFailoverMode,@nvchrListener;
	END
	Close AlwaysOnStatus_Cursor
	Deallocate AlwaysOnStatus_Cursor
	
	
END
ELSE
BEGIN
--declare @servname varchar(max);
set @servname = CONVERT(varchar(max),@@SERVERNAME);
	Set @nvchrtableHTML = @nvchrtableHTML + N'<tr><td colspan="7" text-align:center> AlwaysON  not configured on this server '+@servname+' </td></tr>';
	-- Print @servname
END

Set @nvchrtableHTML = @nvchrtableHTML + N'</TABLE>';

end

-- Logshipping Status Display
CREATE TABLE #LogshippingStatus (primary_server varchar(200),primary_database varchar(250),time_since_last_backup int,last_backup_file varchar(max)); 

INSERT INTO #LogshippingStatus (primary_server,primary_database,time_since_last_backup,last_backup_file)
	select primary_server,primary_database,DATEDIFF(mi,last_backup_date,getdate()),last_backup_file from msdb..log_shipping_monitor_primary

Set @nvchrtableHTML = @nvchrtableHTML 
		  + N'<br>&nbsp; <br/>'
		  + N'<TABLE class=gridtable>'
		  + N'<tr><th colspan="4" text-align:center> TRANSACTION LOG SHIPPING STATUS</th></tr>'
		  + N'<br><tr><th>Primary Server</th>'
				+ N'<th> Primary Database</th>'
				+ N'<th> Time Since Last Backup</th>'
				+ N'<th> Last BAckup File</th></tr>';

SET @vchrDBName = NULL;
SELECT  @sintErrors = COUNT(*) From #LogshippingStatus;

IF (@sintErrors >= 1) 
BEGIN
	DECLARE LogshippingSt_Cursor CURSOR FOR SELECT * FROM #LogshippingStatus;
	
	OPEN LogshippingSt_Cursor;
	FETCH NEXT FROM LogshippingSt_Cursor INTO @nvchrprimaryserver,@nvchrprimarydatabase,@nvchrtimesincelastbackup,@nvchrlastbackupfile;
	
	
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		Set @nvchrtableHTML = @nvchrtableHTML 
				+ N'<tr><td> '+ CONVERT(VARCHAR(max),@nvchrprimaryserver) + N'</td>'
				+ N'<td> '+ CONVERT(VARCHAR(max),@nvchrprimarydatabase) + N'</td>'
				+ N'<td> '+ CONVERT(VARCHAR(max),@nvchrtimesincelastbackup)  + N'</td>'
				+ N'<td> '+ CONVERT(VARCHAR(max),@nvchrlastbackupfile) + N'</td>'
				+ N'</tr>';
			--Print @nvchrprimaryserver;	
			--Print @nvchrprimarydatabase;
			--Print @nvchrsecondaryserver;
		FETCH NEXT FROM LogshippingSt_Cursor INTO  @nvchrprimaryserver,@nvchrprimarydatabase,@nvchrtimesincelastbackup,@nvchrlastbackupfile;
	END
	Close LogshippingSt_Cursor
	Deallocate LogshippingSt_Cursor
	
	
END
ELSE
BEGIN
--declare @servname varchar(max);
set @servname = CONVERT(varchar(max),@@SERVERNAME);
	Set @nvchrtableHTML = @nvchrtableHTML + N'<tr><td colspan="4" text-align:center> LOG SHIPPING not configured on this server '+@servname+' </td></tr>';
	-- Print @servname
END

Set @nvchrtableHTML = @nvchrtableHTML + N'</TABLE>';

-- Mirroring Status Display

CREATE TABLE #DBMirrorStatus (db varchar(100), dbrole varchar(15), dbstatus varchar(30)); 
INSERT INTO #DBMirrorStatus (db, dbrole, dbstatus)
	SELECT DB_NAME(database_id) DBNAME, mirroring_role_desc, mirroring_state_desc
			FROM sys.database_mirroring WHERE mirroring_guid IS NOT NULL

Set @nvchrtableHTML = @nvchrtableHTML 
		  + N'<br>&nbsp; <br/>'
		  + N'<TABLE class=gridtable>'
		  + N'<tr><th colspan="3"> DATABASE MIRRORING STATUS</th></tr>'
		  + N'<br><tr><th>Database Name</th>'
				+ N'<th> Mirroring Role</th>'
				+ N'<th> Mirroring Status</th></tr>';

SET @vchrDBName = NULL;
SELECT  @sintErrors = COUNT(*) From #DBMirrorStatus;
IF (@sintErrors >= 1) 
BEGIN
	DECLARE MirrorSt_Cursor CURSOR FOR SELECT * FROM #DBMirrorStatus;
	OPEN MirrorSt_Cursor;
	FETCH NEXT FROM MirrorSt_Cursor INTO @vchrDBName, @vchrMirrorRole, @vchrMirrorStatus;
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		Set @nvchrtableHTML = @nvchrtableHTML 
				+ N'<tr><td> '+ @vchrDBName + N'</td>'
				+ N'<td> '+ @vchrMirrorRole + N'</td>'
				+ N'<td> '+ @vchrMirrorStatus  + N'</td>'
				+ N'</tr>';
		FETCH NEXT FROM MirrorSt_Cursor INTO @vchrDBName, @vchrMirrorRole, @vchrMirrorStatus;
	END
	Close MirrorSt_Cursor
	Deallocate MirrorSt_Cursor
END
ELSE
BEGIN
		Set @nvchrtableHTML = @nvchrtableHTML + N'<tr><td colspan="3"> Mirroring not configured on this server'+  @vchrInstanceName+'</td></tr>';
		--print @vchrInstanceName
END

Set @nvchrtableHTML = @nvchrtableHTML + N'</TABLE>';


-- Database file usage 

Set @nvchrtableHTML = @nvchrtableHTML 
		  + N'<br>&nbsp; <br/>'
		  + N'<TABLE class=gridtable>'
		  + N'<tr><th colspan="5">Database File Usage</th></tr>'
		  + N'<br><tr><th> Database Name </th>'
					+ N'<th> FileName</th>'
					+ N'<th> Size (MB)</th>'
					+ N'<th> Space Used (MB)</th>'
					+ N'<th> Percentage Used(%)</th>'
		  			+ N'</tr>';
				

CREATE TABLE #FileUsage (db varchar(100), filename varchar(100), sizeInMB int, spaceUsed decimal(10,2), PercUsed decimal(5,2)) 
INSERT INTO #FileUsage 
			EXEC SP_MSFOREACHDB 'USE [?]; SELECT 
					"?",	
					name,
                    CAST(size/128.0 AS DECIMAL(10,2)) AS [Size in MB],
                    CAST(FILEPROPERTY(name, ''SpaceUsed'')/128.0 AS DECIMAL(10,2)) AS [Space Used],
                    CAST((CAST(FILEPROPERTY(name, ''SpaceUsed'')/128.0 AS DECIMAL(10,2))/CAST(size/128.0 AS DECIMAL(10,2)))*100 AS DECIMAL(10,2)) AS [Percent Used]
                    FROM sysfiles 
                    ORDER BY groupid DESC'
                    
DECLARE FileUsage_Cursor CURSOR FOR SELECT * FROM #FileUsage;
OPEN FileUsage_Cursor;
FETCH NEXT FROM FileUsage_Cursor INTO @vchrDBName, @vchrFileName, @fltFreeSpace, @fAvalSpace, @fFreePerc; 
WHILE @@FETCH_STATUS = 0
BEGIN 
	Set @nvchrtableHTML = @nvchrtableHTML 
			+ N'<td> '+ @vchrDBName  + N' </td>'
			+ N'<td> '+ @vchrFileName  + N' </td>'
			+ N'<td> '+ Cast(@fltFreeSpace AS varchar)  + N' </td>'
			+ N'<td> '+ Cast(@fAvalSpace AS varchar)  + N' </td>'
			+ N'<td> '+ Cast(@fFreePerc AS varchar)  + N' </td>'
			+ N'</tr>';
	FETCH NEXT FROM FileUsage_Cursor INTO @vchrDBName, @vchrFileName, @fltFreeSpace, @fAvalSpace, @fFreePerc;
END
Close FileUsage_Cursor
Deallocate FileUsage_Cursor

Set @nvchrtableHTML = @nvchrtableHTML + N'</TABLE>';


-- Error log Display
Set @nvchrtableHTML = @nvchrtableHTML 
		  + N'<br>&nbsp; <br/>'
		  + N'<TABLE class=gridtable>'
		  + N'<tr><th colspan="3"> Error Log in Last 6 hours</th></tr>'
		  + N'<br><tr><th> Log Date</th>'
				+ N'<th colspan="2"> Message</th></tr>';
				
Truncate TABLE #ErrorLog;
INSERT INTO #ErrorLog Exec xp_readerrorlog 0,1,"Error", NULL,@dtStartDate,@dtCurrentDate;
SELECT  @sintErrors = COUNT(*) From #ErrorLog;

IF (@sintErrors >= 1) 
BEGIN
	DECLARE ErrorLog_Cursor CURSOR FOR SELECT logdate, message FROM #ErrorLog;
	OPEN ErrorLog_Cursor;
	FETCH NEXT FROM ErrorLog_Cursor INTO @dtLogDate, @vchrMsg;
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		Set @nvchrtableHTML = @nvchrtableHTML 
				+ N'<tr><td> '+ Convert(varchar,@dtLogDate,120) + N'</td>'
				+ N'<td colspan="2"> '+ @vchrMsg  + N' </td>'
				+ N'</tr>';
		FETCH NEXT FROM ErrorLog_Cursor INTO @dtLogDate, @vchrMsg;
	END
	Close ErrorLog_Cursor
	Deallocate ErrorLog_Cursor
END
ELSE
BEGIN
	Set @nvchrtableHTML = @nvchrtableHTML + N'<tr><td colspan="3"> No Errors :) </td></tr>';
END
Set @nvchrtableHTML = @nvchrtableHTML + N'</TABLE></BODY>';


--*/
-- DB State Display

CREATE TABLE #db_details (name nvarchar(128), db_size nvarchar(50),owner nvarchar(128),db_id int,created varchar(128),status nvarchar(2000),compatibility_level int);

INSERT INTO #db_details EXEC sp_helpdb
(SELECT *
FROM #db_details)
Set @nvchrtableHTML = @nvchrtableHTML 
		  + N'<br>&nbsp; <br/>'
		  + N'<TABLE class=gridtable>'
		  + N'<tr><th colspan="7" text-align:center> Database Health Check Report </th></tr>'
		  + N'<br><tr><th>name</th>'
				+ N'<th> db_size</th>'
				+ N'<th> owner </th>'
				+ N'<th> db_id</th>'
				+ N'<th> created</th>'
				+ N'<th> Status</th>'
				+ N'<th> compatibility_level</th></tr>';

SET @vchrDBName = NULL;
SELECT  @sintErrors = COUNT(*) From #db_details;

IF (@sintErrors >= 1) 
BEGIN
	DECLARE db_details_Cursor CURSOR FOR SELECT * FROM #db_details;
	
	OPEN db_details_Cursor;
	FETCH NEXT FROM db_details_Cursor INTO @nvchrname,@nvchrdb_size,@nvchrowner,@nvchrdb_id,@nvchrcreated,@nvchrstatus,@nvchrcompatibility_level;
	
	
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		Set @nvchrtableHTML = @nvchrtableHTML 
				+ N'<tr><td> '+ CONVERT(VARCHAR(max),@nvchrname) + N'</td>'
				+ N'<td> '+ CONVERT(VARCHAR(max),@nvchrdb_size) + N'</td>'
				+ N'<td> '+ CONVERT(VARCHAR(max),@nvchrowner)  + N'</td>'
				+ N'<td> '+ CONVERT(VARCHAR(max),@nvchrdb_id) + N'</td>'
				+ N'<td> '+ CONVERT(VARCHAR(max),@nvchrcreated) + N'</td>'
				+ N'<td> '+ CONVERT(VARCHAR(max),@nvchrstatus)  + N'</td>'
				+ N'<td> '+ CONVERT(VARCHAR(max),@nvchrcompatibility_level) + N'</td>'
				+ N'</tr>';
			--Print @nvchrprimaryserver;	
			--Print @nvchrprimarydatabase;
			--Print @nvchrsecondaryserver;
		FETCH NEXT FROM db_details_Cursor INTO  @nvchrname,@nvchrdb_size,@nvchrowner,@nvchrdb_id,@nvchrcreated,@nvchrstatus,@nvchrcompatibility_level;
	END
	Close db_details_Cursor
	Deallocate db_details_Cursor
	
	
END
ELSE
BEGIN
--declare @servname varchar(max);
set @servname = CONVERT(varchar(max),@@SERVERNAME);
	Set @nvchrtableHTML = @nvchrtableHTML + N'<tr><td colspan="7" text-align:center> NO Databases on this server '+@servname+' </td></tr>';
	-- Print @servname
END

Set @nvchrtableHTML = @nvchrtableHTML + N'</TABLE>';




-- Cleanup

Drop Function fn_splitstring;
IF OBJECT_ID (N'tempdb..#SPConf', N'U') IS NOT NULL DROP TABLE #SPConf;
IF OBJECT_ID (N'tempdb..#display',N'U') IS NOT NULL DROP TABLE #display;
IF OBJECT_ID (N'tempdb..#DBName',N'U') IS NOT NULL DROP TABLE #DBName;
IF OBJECT_ID (N'tempdb..#ErrorLog',N'U') IS NOT NULL DROP TABLE #ErrorLog;
IF OBJECT_ID (N'tempdb..#FileUsage',N'U') IS NOT NULL DROP TABLE #FileUsage;
IF OBJECT_ID (N'tempdb..#results',N'U') IS NOT NULL DROP TABLE #results;
IF OBJECT_ID (N'tempdb..#DBConnections',N'U') IS NOT NULL DROP TABLE #DBConnections;
IF OBJECT_ID (N'tempdb..#DBMirrorStatusvg',N'U') IS NOT NULL DROP TABLE #DBMirrorStatus;
IF OBJECT_ID (N'tempdb..#LogshippingStatus',N'U') IS NOT NULL DROP TABLE #LogshippingStatus;
IF OBJECT_ID (N'tempdb..#AlwaysOnStatus',N'U') IS NOT NULL DROP TABLE #AlwaysOnStatus;
IF OBJECT_ID (N'tempdb..#ClusterInfo',N'U') IS NOT NULL DROP TABLE #ClusterInfo;
IF OBJECT_ID (N'tempdb..#db_details',N'U') IS NOT NULL DROP TABLE #db_details;




SET @nvchrSQL_Profile_Name=(select top 1 name  from msdb..sysmail_profile)
SET @vchrEmailSubject = 'SQL Health Check Report For ' + @vchrInstanceName;

EXEC msdb.dbo.sp_send_dbmail                                
 @profile_name = @nvchrSQL_Profile_Name, -- Change Profile name As per your Environment                      
 @recipients=' ',  -- Change email ID 
 @subject = @vchrEmailSubject,
 @body = @nvchrtableHTML,
 @body_format = 'HTML' ;
 
Set nocount off

