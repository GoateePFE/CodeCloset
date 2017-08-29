
$p = @{
    Name = 'svchost'
}

Get-Process @p

Get-Process -Name svchost


##############################
# Calculate parameters for a cmdlet

$x = @{
    Recurse = $true
    Path    = 'C:\Temp'
}

$choice = Read-host "(D)irectories or (F)iles?"

switch ($choice) {
    'F' {$x['File']=$true}
    'D' {$x['Directory']=$true}
}

$x

Get-ChildItem @x | Format-Table -AutoSize
