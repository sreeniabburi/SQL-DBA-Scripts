Select @@servername As Destination_Servername, Destination_database_name, 
       restore_date,
	   [bs].[backup_start_date] ,
       [bs].[backup_finish_date] ,
       database_name as Source_database,
       bs.machine_name As Source_Servername
from msdb.dbo.restorehistory rh 
  inner join msdb.dbo.backupset bs 
    on rh.backup_set_id=bs.backup_set_id
  inner join msdb.dbo.backupmediafamily bmf 
    on bs.media_set_id =bmf.media_set_id
ORDER BY [rh].[restore_date] DESC