SELECT DB_NAME(f.database_id) AS [DBName],

f.name as [FileName],

f.physical_name as [FilePath],

a.volume_mount_point as [MountPoint MPt],

Cast(a.total_bytes/(1024*1024) as decimal(10,0)) [MPt Size(MB)],

Cast(a.available_bytes/(1024*1024) as decimal(10,0)) [MPt FreeSpace in MB],

CAST(f.size/128.0 AS DECIMAL(10,2)) AS [FileSize in MB],

CAST(FILEPROPERTY(f.name, 'SpaceUsed')/128.0 AS DECIMAL(10,2)) AS [File SpaceUsed(MB)],

CAST(f.size/128.0-(FILEPROPERTY(f.name, 'SpaceUsed')/128.0) AS DECIMAL(10,2)) AS [File FreeSpace(MB)],

CAST((CAST(FILEPROPERTY(f.name, 'SpaceUsed')/128.0 AS DECIMAL(10,2))/CAST(size/128.0 AS DECIMAL(10,2)))*100 AS DECIMAL(10,2)) AS [File Used(%)]

FROM sys.master_files AS f

CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id) a

WHERE f.database_id = DB_ID();
