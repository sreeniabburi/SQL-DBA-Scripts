USE master
 
DECLARE @dbid INT
SELECT
    @dbid = dbid 
FROM
    sys.sysdatabases 
WHERE
    name = 'db_name' -- Specify db name on which we want to kill sessions
 
IF EXISTS (SELECT spid FROM sys.sysprocesses WHERE dbid = @dbid)
  BEGIN
    PRINT '-------------------------------------------'
    PRINT 'CREATE WOULD FAIL -DROPPING ALL CONNECTIONS'
    PRINT '-------------------------------------------'
    PRINT 'These processes are blocking the restore from occurring'
 
    SELECT spid, hostname, loginame, status, last_batch
    FROM sys.sysprocesses WHERE dbid = @dbid
 
    --Kill any connections
    DECLARE SysProc CURSOR LOCAL FORWARD_ONLY DYNAMIC READ_ONLY FOR
    SELECT spid FROM master.dbo.sysprocesses WHERE dbid = @dbid
    DECLARE @SysProcId smallint
    OPEN SysProc
    FETCH NEXT FROM SysProc INTO @SysProcId
    DECLARE @KillStatement char(30)
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @KillStatement = 'KILL ' + CAST(@SysProcId AS char(30))
        EXEC (@KillStatement)
        FETCH NEXT FROM SysProc INTO @SysProcId
    END
 
    WAITFOR DELAY '000:00:01'
  END
