BACKUP DATABASE [OperationalDb] TO  DISK = N'/var/opt/mssql/data/OperationalDb.bak' WITH NOFORMAT, INIT, NOSKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 10
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'OperationalDb' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'OperationalDb' )
if @backupSetId is null begin raiserror(N'Verify failed. Backup information for database ''OperationalDb'' not found.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'/var/opt/mssql/data/OperationalDb.bak' WITH  FILE = @backupSetId,  NOUNLOAD
