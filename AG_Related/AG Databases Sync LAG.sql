SELECT 
    ar.replica_server_name, 
    adc.database_name, 
    ag.name AS ag_name, 
    dhdrs.synchronization_state_desc, 
    dhdrs.is_commit_participant, 
    dhdrs.last_sent_lsn, 
    dhdrs.last_sent_time, 
    dhdrs.last_received_lsn, 
    dhdrs.last_hardened_lsn, 
    dhdrs.last_redone_time
FROM sys.dm_hadr_database_replica_states AS dhdrs
INNER JOIN sys.availability_databases_cluster AS adc 
    ON dhdrs.group_id = adc.group_id AND 
    dhdrs.group_database_id = adc.group_database_id
INNER JOIN sys.availability_groups AS ag
    ON ag.group_id = dhdrs.group_id
INNER JOIN sys.availability_replicas AS ar 
    ON dhdrs.group_id = ar.group_id AND 
    dhdrs.replica_id = ar.replica_id
--where database_name='DB Nme'
--where ar.replica_server_name in ('Server B','Server A')
