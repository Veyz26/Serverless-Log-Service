param($Request, $TriggerMetadata)

# Get storage account connection string and table name from environment
$connectionString = $env:AzureWebJobsStorage
$tableName = $env:LogTableName

# Parse request body
try {
    $body = $Request.Body | ConvertFrom-Json
} catch {
    return @{ status = 400; body = 'Invalid JSON in request body.' }
}

# Validate required fields and severity
$allowedSeverities = @('info', 'warning', 'error')
if (-not $body.Severity -or -not $body.Message) {
    return @{ status = 400; body = 'Missing required fields: Severity, Message' }
}
if ($allowedSeverities -notcontains $body.Severity.ToLower()) {
    return @{ status = 400; body = 'Severity must be one of: info, warning, error.' }
}

# Generate log entry
$logEntry = @{
    PartitionKey = 'log'
    RowKey = [guid]::NewGuid().ToString()
    DateTime = (Get-Date).ToString('o')
    Severity = $body.Severity.ToLower()
    Message = $body.Message
}

# Insert log entry into Azure Table Storage
try {
    $context = New-AzStorageContext -ConnectionString $connectionString
    $null = Add-AzTableRow -Table $tableName -PartitionKey $logEntry.PartitionKey -RowKey $logEntry.RowKey -Property $logEntry -Context $context
    return @{ status = 201; body = 'Log entry created.' }
} catch {
    return @{ status = 500; body = 'Failed to write log entry: ' + $_.Exception.Message }
}
