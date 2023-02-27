USE	MASTER
GO

DECLARE @SqlCommand varchar(1000)

DECLARE @BackupFilePath VARCHAR(100)
SET @BackupFilePath = N'$(varBakFilePath)'
DECLARE @DestinationDbName VARCHAR(100)
SET @DestinationDbName = N'$(varTargetDbName)'

-- Kill Connections
PRINT 'KILL ALL CONNECTIONS TO DATABASE ' + @DestinationDbName
DECLARE	@Spid INT
DECLARE	@ExecSQL VARCHAR(255)
 
DECLARE	KillCursor CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
SELECT	DISTINCT SPID
FROM	MASTER..SysProcesses
WHERE	DBID = DB_ID(@DestinationDbName)
 
OPEN	KillCursor
 
-- Grab the first SPID
FETCH	NEXT
FROM	KillCursor
INTO	@Spid
 
WHILE	@@FETCH_STATUS = 0
	BEGIN
		SET		@ExecSQL = 'KILL ' + CAST(@Spid AS VARCHAR(50))
 
		EXEC	(@ExecSQL)
 
		-- Pull the next SPID
        FETCH	NEXT 
		FROM	KillCursor 
		INTO	@Spid  
	END
 
CLOSE	KillCursor
 
DEALLOCATE	KillCursor

-- DROP DATABASE
PRINT 'DROP DATABASE ' + @DestinationDbName
SET @SqlCommand = 'DROP DATABASE IF EXISTS ' + @DestinationDbName
EXEC(@SqlCommand)

-- RESTORE DATABASE
PRINT 'RESTORE DATABASE'
SET @SqlCommand = 'RESTORE DATABASE [' + @DestinationDbName + '] FROM  DISK = N''' + @BackupFilePath + ''' WITH  FILE = 1, REPLACE,  STATS = 5'
EXEC(@SqlCommand)
GO