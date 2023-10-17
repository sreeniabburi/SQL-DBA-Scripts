CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_256 ENCRYPTION BY SERVER CERTIFICATE TDE_Certificate 

ALTER DATABASE DB_Prod SET ENCRYPTION ON
 
Go
 
Select DB_NAME(database_id),* from sys.dm_database_encryption_keys
 
Go 

BACKUP CERTIFICATE TDE_Certificate TO FILE='C:\TDE_Certificate.Cer' WITH PRIVATE KEY 
 
(FILE = 'C:\TDE_Certificate_MasterKey.pvt' , ENCRYPTION BY PASSWORD = 'password')
 
Go 

CREATE CERTIFICATE TDE_Certificate From FILE='C:\TDE_Certificate.Cer' WITH PRIVATE KEY (FILE = 'C:\TDE_MasterKey.pvt' , DeCRYPTION BY PASSWORD = 'password')
 
Go 
