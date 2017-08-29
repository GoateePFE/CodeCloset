
# Pick your server list technique
$Servers = Get-Content .\servers.txt
$Servers = (Get-ADComputer -SearchBase 'OU=MyServers,DC=Contoso,DC=com').DNSHostName
$Servers = '2012r2-MS','2012r2-dc','win8-ws'

# Collect data, use hash table for custom object
$Output = ForEach ($Server in $Servers) {
    [PSCustomObject]@{
        Name         = $Server
        SerialNumber = (Get-WmiObject win32_bios -Property SerialNumber -ComputerName $Server).SerialNumber
        OSVersion    = (Get-WmiObject win32_operatingsystem -ComputerName $Server).Version
        CDriveFree   = (Get-WmiObject win32_volume -Filter "DriveLetter='C:'" -ComputerName $Server).FreeSpace / 1GB
    }
}

# Create report file
$Output | Export-CSV -Path C:\Temp\Inventory.csv -NoTypeInformation

# Attach file to email, use hash table to splat cmdlet
$Mail = @{
    Attachments = 'C:\Temp\Inventory.csv'
    To          = 'boss@contoso.com'
    From        = 'lackey@contoso.com'
    Subject     = "Here's your report"
    Body        = "Hope you like it. I'm going golfing."
    SMTPServer  = 'wideopenspamserver.contoso.com'
}
Send-MailMessage @Mail

# Schedule this as a task so you look productive while out golfing.

