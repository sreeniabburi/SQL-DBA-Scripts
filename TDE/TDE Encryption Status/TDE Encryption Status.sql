SELECT session_id, encrypt_option
FROM sys.dm_exec_connections

Select Distinct Net_transport,encrypt_option from sys.dm_exec_connections 
--select * from master.sys.certificates