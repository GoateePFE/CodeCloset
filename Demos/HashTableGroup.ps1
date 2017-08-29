Get-Service | Group-Object -Property Status

Get-Service | Group-Object -Property Status -AsHashTable -AsString

$Services = Get-Service | Group-Object -Property Status -AsHashTable -AsString
$Services.Stopped
$Services['Stopped'][0]

