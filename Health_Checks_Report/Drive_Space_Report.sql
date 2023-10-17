SET NOCOUNT ON
 
CREATE TABLE #Temp
(
[Database] [varchar] (128) NULL,
[File Name] [sys].[sysname] NOT NULL,
[FilePath] [varchar] (260) NULL,
[MountPoint Mpt] [varchar] (300) NULL,
[Mpt Size(MB)] [varchar] (260) NULL,
[Mpt Free Space in MB] [varchar] (260) NULL,
[FileSize in MB] [varchar] (260)NULL,
[File SpaceUsed(MB)] [varchar] (260) NULL,
[File FreeSpace(MB)] [varchar] (260) NULL,
[File Used(%)] [varchar] (260) NULL
)
EXEC sp_MSforeachdb 'USE [?];
INSERT INTO #Temp
SELECT DB_NAME(f.database_id) AS [DBName],

f.name as [FileName],

f.physical_name as [FilePath],

a.volume_mount_point as [MountPoint MPt],

Cast(a.total_bytes/(1024*1024) as decimal(10,0)) [MPt Size(MB)],

Cast(a.available_bytes/(1024*1024) as decimal(10,0)) [MPt FreeSpace in MB],

CAST(f.size/128.0 AS DECIMAL(10,2)) AS [FileSize in MB],

CAST(FILEPROPERTY(f.name, ''SpaceUsed'')/128.0 AS DECIMAL(10,2)) AS [File SpaceUsed(MB)],

CAST(f.size/128.0-(FILEPROPERTY(f.name, ''SpaceUsed'')/128.0) AS DECIMAL(10,2)) AS [File FreeSpace(MB)],

CAST((CAST(FILEPROPERTY(f.name, ''SpaceUsed'')/128.0 AS DECIMAL(10,2))/CAST(size/128.0 AS DECIMAL(10,2)))*100 AS DECIMAL(10,2)) AS [File Used(%)]

FROM sys.master_files AS f

CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id) a

WHERE f.database_id = DB_ID()'

--select * from #Temp
DECLARE @tableHTML NVARCHAR(MAX),
@to varchar(200),
   @subject varchar(100),
   @PercentFree varchar(100);
   set @PercentFree=90

set @to='abc@email.com'
set @subject='Database Files Space Utilization Along with MountPoint Free Space --> '
SET @tableHTML = N'<H2>Database File Space Utilization</H2>' + N'<table border="1">'+
+ N'<tr><th>Database</th><th>File Name</th><th>FilePath</th><th>MountPoint Mpt</th><th>Mpt Size(MB)</th><th>Mpt Free Space in MB</th><th>FileSize in MB</th><th>File SpaceUsed(MB)</th><th>File FreeSpace(MB)</th><th>File Used(%)</th></tr>'
    + CAST(( SELECT CASE WHEN [File Used(%)] >= @PercentFree THEN '#FF0000'
                    END AS 'td/@BGCOLOR' ,
                    td = [Database] ,
                    '' ,
                    'right' AS 'td/@align' ,
                    CASE WHEN [File Used(%)] >= @PercentFree THEN '#FF0000'
                    END AS 'td/@BGCOLOR' ,
                    td = [File Name] ,
                    '' ,
                    'right' AS 'td/@align' ,
                    CASE WHEN [File Used(%)] >= @PercentFree THEN '#FF0000'
                    END AS 'td/@BGCOLOR' ,
                    td = [FilePath],
                    '' ,
					'right' AS 'td/@align' ,
                    CASE WHEN [File Used(%)] >= @PercentFree THEN '#FF0000'
                    END AS 'td/@BGCOLOR' ,
                    td = [MountPoint Mpt],
                    '' ,
                    'right' AS 'td/@align' ,
                    CASE WHEN [File Used(%)] >= @PercentFree THEN '#FF0000'
                    END AS 'td/@BGCOLOR' ,
                    td = [Mpt Size(MB)] ,
                    '' ,
					'right' AS 'td/@align' ,
                    CASE WHEN [File Used(%)] >= @PercentFree THEN '#FF0000'
                    END AS 'td/@BGCOLOR' ,
                    td = [Mpt Free Space in MB] ,
                    '' ,
                    'right' AS 'td/@align' ,
                    CASE WHEN [File Used(%)] >= @PercentFree THEN '#FF0000'
                    END AS 'td/@BGCOLOR' ,
                    td = [FileSize in MB] ,
                    '' ,
					'right' AS 'td/@align' ,
                    CASE WHEN [File Used(%)] >= @PercentFree THEN '#FF0000'
                    END AS 'td/@BGCOLOR' ,
                    td = [File SpaceUsed(MB)] ,
                    '' ,
                    'right' AS 'td/@align' ,
                    CASE WHEN [File Used(%)] >= @PercentFree THEN '#FF0000'
                    END AS 'td/@BGCOLOR' ,
                    td = [File FreeSpace(MB)],
					'',
					'right' AS 'td/@align' ,
                    CASE WHEN [File Used(%)] >= @PercentFree THEN '#FF0000'
                    END AS 'td/@BGCOLOR' ,
                    td = [File Used(%)]

             FROM   #Temp where [Database] in ('tempdb','FCRADWP')
           FOR
             XML PATH('tr') ,
                 TYPE
           ) AS NVARCHAR(MAX)) + N'</table>';
 

SET @Subject = @Subject + @@Servername  
EXEC msdb.dbo.sp_send_dbmail @profile_name ='DBA',
    @recipients = @to, @body = @tableHTML,
    @subject = @Subject, @body_format = 'HTML'

GO
drop table #Temp
