param($workingDirectory, $containerDirectory, $sourceDatabaseName, $targetDatabaseName, $password, $forceDrop, $dropVolume)

# Set to true to run docker compose down
if ($forceDrop)
{
    Write-Host "Force docker compose down" -ForegroundColor DarkYellow
    docker compose down
}
# Set the volume name to drop
if ($dropVolume)
{
    Write-Host "WARNING! Delete volume ${dropVolume}" -ForegroundColor DarkYellow
    $Consent = Read-Host "Enter y to validate, default is N"
    if ($consent -eq "y")
    {
        $result = docker volume rm $dropVolume
        if ($result -ne "")
        {
            Write-Host "Volume ${dropVolume} has been deleted" -ForegroundColor Red
        }
    }
}

# Run docker compose as background services
Write-Host "Run docker compose up -d (-d is for background service)" -ForegroundColor blue
docker compose -f docker-compose.yml up -d
echo ""

# Resolve absolute path for working directory to avoid ambiguity
$workingDirectory = Resolve-Path ${workingDirectory}

# Build files paths
$localBakFilePath = Join-Path -Path $workingDirectory -ChildPath "${sourceDatabaseName}.bak"
$remoteBakFilePath = Join-Path -Path $containerDirectory -ChildPath "${sourceDatabaseName}.bak"
$localbackupScriptPath = Join-Path -Path $workingDirectory -ChildPath "BackupScript.sql"
$remotebackupScriptPath = Join-Path -Path $containerDirectory -ChildPath "BackupScript.sql"

# Transform remote path into unix style path
$remoteBakFilePath = $remoteBakFilePath.Replace('\', '/')
$remotebackupScriptPath = $remotebackupScriptPath.Replace('\', '/')

Write-Host "Display files path" -ForegroundColor blue
echo "-----------------------------------------------------------------------"
echo "Host machine path to ""BackupScript.sql"":    ${localbackupScriptPath}"
echo "Container path to ""BackupScript.sql"":       ${remotebackupScriptPath}"
echo "Host machine path to ""bak"" file:            ${localBakFilePath}"
echo "Container path to ""bak"" file:               ${remoteBakFilePath}"
echo "-----------------------------------------------------------------------"

Write-Host "Copy ${localBakFilePath} to container" -ForegroundColor blue
docker cp "${localBakFilePath}" SqlServer:$containerDirectory
echo "-----------------------------------------------------------------------"
echo ""
Write-Host "Copy ${localbackupScriptPath} to container" -ForegroundColor blue
echo "-----------------------------------------------------------------------"
docker cp "${localbackupScriptPath}" SqlServer:$containerDirectory

if ($dropVolume)
{
    echo "Waiting 5 seconds to ensure the Sql Server is ready"
    Start-Sleep -Seconds 5
}

Write-Host "Run backup script" -ForegroundColor blue
echo "-----------------------------------------------------------------------"
docker exec -u root -it SqlServer /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $password -i "${remotebackupScriptPath}" -v varSourceDbName=$sourceDatabaseName varTargetDbName=$targetDatabaseName varBakFilePath="${remoteBakFilePath}"
echo "-----------------------------------------------------------------------"
Write-Host "Database migration completed" -ForegroundColor green