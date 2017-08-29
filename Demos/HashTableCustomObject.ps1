###############################################################################

@{
    Name   = 'Benny'
    Role   = 'Construction'
    ID     = 123
    Groups = 'Users','Admins','Network'
}

New-Object -TypeName PSObject -Property @{
    Name   = 'Benny'
    Role   = 'Construction'
    ID     = 123
    Groups = 'Users','Admins','Network'
}

[PSCustomObject]@{
    Name   = 'Benny'
    Role   = 'Construction'
    ID     = 123
    Groups = 'Users','Admins','Network'
}

###############################################################################

# Output an array of custom objects
# Use the hash table to specific properties of the custom object

$output = ForEach ($PC in @('2012r2-ms','2012r2-dc','win8-ws')) {

    $cim = New-CimSession -ComputerName $PC

    $b = Get-CimInstance -CimSession $cim -ClassName win32_bios
    $c = Get-CimInstance -CimSession $cim -ClassName win32_computersystem
    $o = Get-CimInstance -CimSession $cim -ClassName win32_operatingsystem

    Remove-CimSession $cim

    # version 2 vs Version 3+ syntax
    #New-Object -TypeName PSObject -Property @{
    [PSCustomObject]@{
        ComputerName = $PC
        BiosSerial   = $b.SerialNumber
        RAMinGB      = [math]::Round($c.TotalPhysicalMemory / 1GB,2)
        OSVersion    = $o.Version
        CPUArch      = $o.OSArchitecture
    }

}

$output
$output | Get-Member
$output | ft -AutoSize
$output | Out-GridView
$output | Export-Csv
