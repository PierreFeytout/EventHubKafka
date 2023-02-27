USE	MASTER
GO

DECLARE @SqlCommand varchar(1000)

DECLARE @BakFilePath VARCHAR(255)
SET @BakFilePath = N'$(varBakFilePath)'
DECLARE @SourceDbName VARCHAR(100)
SET @SourceDbName = N'$(varSourceDbName)'
DECLARE @TargetDbName VARCHAR(100)
SET @TargetDbName = N'$(varTargetDbName)'

-- Kill Connections
PRINT 'KILL ALL CONNECTIONS TO DATABASE ' + @SourceDbName
DECLARE	@Spid INT
DECLARE	@ExecSQL VARCHAR(255)
 
DECLARE	KillCursor CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
SELECT	DISTINCT SPID
FROM	MASTER..SysProcesses
WHERE	DBID = DB_ID(@SourceDbName)
 
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

PRINT 'KILL ALL CONNECTIONS TO DATABASE ' + @TargetDbName 
DECLARE	KillCursor CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
SELECT	DISTINCT SPID
FROM	MASTER..SysProcesses
WHERE	DBID = DB_ID(@TargetDbName)
 
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
PRINT 'DROP DATABASE ' + @TargetDbName
SET @SqlCommand = 'DROP DATABASE IF EXISTS ' + @TargetDbName
EXEC(@SqlCommand)

-- RESTORE DATABASE
PRINT 'RESTORE DATABASE'
SET @SqlCommand =	'RESTORE DATABASE [' + @TargetDbName + '] FROM  DISK = N''' + @BakFilePath + ''' WITH  FILE = 1,  MOVE N''' + @SourceDbName + ''' TO N''/var/opt/mssql/data/' + @TargetDbName + 'Database.mdf'',  MOVE N''' + @SourceDbName + '_log'' TO N''/var/opt/mssql/data/' + @TargetDbName + 'Database_log.ldf'',  NOUNLOAD,  REPLACE,  STATS = 5'

EXEC(@SqlCommand)
GO