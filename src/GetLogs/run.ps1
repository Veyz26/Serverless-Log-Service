param($Request, $TriggerMetadata)

# Get storage account connection string and table name from environment
$connectionString = $env:AzureWebJobsStorage
$tableName = $env:LogTableName

try {
    $context = New-AzStorageContext -ConnectionString $connectionString
    $logs = Get-AzTableRow -Table $tableName -Context $context -PartitionKey 'log' | Sort-Object DateTime -Descending | Select-Object -First 100
    $result = $logs | ForEach-Object {
        [PSCustomObject]@{
            ID = $_.RowKey
            DateTime = $_.DateTime
            Severity = $_.Severity
            Message = $_.Message
        }
    }
    return @{ status = 200; body = ($result | ConvertTo-Json -Depth 3) }
} catch {
    return @{ status = 500; body = 'Failed to retrieve logs: ' + $_.Exception.Message }
}
