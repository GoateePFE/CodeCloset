

# Get list of Nodes from DB
$DBInstance = "dscdb"
$Query = "
    SELECT Hostname, Role, CertificatePath, CertificateThumbprint
    FROM dscdatabase.dbo.vAllNodesWithData
"
$Nodes = Invoke-Sqlcmd -ServerInstance "(localdb)\$DBInstance" -Query $Query

$ConfigData = @{ AllNodes = @() }

ForEach ($Node in $Nodes)
{ 
    $ConfigData.AllNodes += @{
        NodeName        = $Node.Hostname
        Role            = $Node.Role
        Store_Id        = $Node.Store_Id
        CertificateFile = $Node.CertificatePath
        Thumbprint      = $Node.CertificateThumbprint
    }
}

$ConfigData

$ConfigData.AllNodes
