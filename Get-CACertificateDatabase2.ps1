
# WORK IN PROGRESS


<#
ORIGINAL SCRIPT
By Anders Wahlqvist
http://dollarunderscore.azurewebsites.net/?p=4791
http://poshcode.org/5793

So, the process itself is pretty straight forward, specify your CA instance and what
certificates you are interested in and the function will return them for you. You
could for example do this:

PS> Get-CACertificateDatabase -CertificationAuthority "contoso.com\Issuing CA" -IncludeBinaryCertificate

All issued certificates valid today and up to two years ahead will be returned,
including their public key. To save them all to disk you could do this:

PS> Get-CACertificateDatabase -CertificationAuthority "contoso.com\Issuing CA" -IncludeBinaryCertificate |
       ForEach-Object { $_.BinaryCertificate | Out-File "$($_.IssuedCommonName).cer" -Encoding default }

REFERENCES
https://msdn.microsoft.com/en-us/library/cc226763.aspx
https://technet.microsoft.com/en-us/library/cc783853(v=ws.10).aspx
https://sysengblog.wordpress.com/tag/certutil/

UPDATED SCRIPT BELOW
By Ashley McGlone, Microsoft PFE
Updated to expose the EKU for Document Encryption so that certs for DSC can be filtered.
Simplified code for field selection from CA
#>
function Get-CACertificateDatabase
{
    <#
    .SYNOPSIS
    Retrieves information about certificates from the Certificate Authority Database
 
    .DESCRIPTION
    This function will fetch items from a Certificate Authority Database. It can also 
    fetch the public key of the certificates and the thumbprint which could be really
    useful when you want to use the certificates to for example encrypt something
    (like a credential in a DSC resource).
 
    Another useful scenario is to create monitoring of certificate expiration dates.
 
    .EXAMPLE
    Get-CACertificateDatabase -CA "myca.contoso.com\Issuing CA Contoso" -IncludeBinaryCertificate
 
    Fetch certificates from the CA instance and include the public key.
 
    .EXAMPLE
    Get-CACertificateDatabase -CA "myca.contoso.com\Issuing CA Contoso" -ValidTo (Get-Date)
 
    Fetch certificates that expires today.
 
    .PARAMETER CertificationAuthority
    The Certificate Authority instance you want to connect to. For example:
    'myca.contoso.com\Issuing CA Contoso'
 
    .PARAMETER ValidFrom
    Filter what certificates should be returned based on if they are valid at this date.
 
    .PARAMETER ValidTo
    Filter what certificates should be returned based on if they expire before this date.
 
    .PARAMETER Disposition
    Specifies which category to get the certificates from.
 
    Brief disposition code explanation:
    * 9 - pending for approval
    * 15 - CA certificate renewal
    * 16 - CA certificate chain
    * 20 - issued certificates
    * 21 - revoked certificates
    * all other - failed requests
 #>
 
    [cmdletbinding()]
    param ([parameter(Mandatory = $true)]
           [string] $CertificationAuthority,
           [parameter(Mandatory = $false)]
           [datetime] $ValidFrom = (Get-Date),
           [parameter(Mandatory = $false)]
           [datetime] $ValidTo = (Get-Date).AddYears(2),
           [parameter(Mandatory = $false)]
           [int] $Disposition = 20
    )

    BEGIN { }
 
    PROCESS {
 
        Write-Verbose 'Initiating com object'
 
        $CaView = New-Object -Com CertificateAuthority.View
 
        try {
            Write-Verbose "Connecting to $CertificationAuthority..."
            [void] $CaView.OpenConnection($CertificationAuthority)
        }
        catch {
            Write-Error "Failed to connect to the Certificate Authority instance $CA. The error was: $($_.toString())"
            break
        }
 


$IndexList = "Archived Key
Attestation Challenge
Binary Certificate
Binary Public Key
Binary Request
Caller Name
Certificate Effective Date
Certificate Expiration Date
Certificate Hash
Certificate Template
Effective Revocation Date
Endorsement Certificate Hash
Endorsement Key Hash
Issued Binary Name
Issued City
Issued Common Name
Issued Country/Region
Issued Device Serial Number
Issued Distinguished Name
Issued Domain Component
Issued Email address
Issued First Name
Issued Initials
Issued Last Name
Issued Organization Unit
Issued Organization
Issued Request ID
Issued State
Issued Street Address
Issued Subject Key Identifier
Issued Title
Issued Unstructured Address
Issued Unstructured Name
Issuer Name ID
Key Recovery Agent Hashes
Officer
Old Certificate
Public Key Algorithm Parameters
Public Key Algorithm
Public Key Length
Publish Expired Certificate in CRL
Request Attributes
Request Binary Name
Request City
Request Common Name
Request Country/Region
Request Device Serial Number
Request Disposition Message
Request Disposition
Request Distinguished Name
Request Domain Component
Request Email Address
Request First Name
Request Flags
Request ID
Request Initials
Request Last Name
Request Organization Unit
Request Organization
Request Resolution Date
Request State
Request Status Code
Request Street Address
Request Submission Date
Request Title
Request Type
Request Unstructured Address
Request Unstructured Name
Requester Name
Revocation Date
Revocation Reason
Serial Number
Signer Application Policies
Signer Policies
Template Enrollment Flags
Template General Flags
User Principal Name" -split "`r`n"

$IndexList = "Issued Common Name
Issued Distinguished Name
Caller Name
User Principal Name
Certificate Expiration Date
Certificate Template
Public Key Algorithm
Request Disposition
Binary Certificate
Certificate Hash
Requester Name" -split "`r`n"

        $CaView.SetResultColumnCount($IndexList.Count)
        $IndexHash = @{}
        ForEach ($Index in $IndexList) {
            write-verbose $Index
            $IndexHash[$Index] = $CaView.GetColumnIndex($false, $Index)
        }
        $IndexHash.Values | ForEach-Object { $CAView.SetResultColumn($_) }

        # CVR_SORT_NONE 0
        # CVR_SEEK_EQ  1
        # CVR_SEEK_LT  2
        # CVR_SEEK_GT  16
 
        $CAView.SetRestriction($IndexHash["Certificate Expiration Date"],16,0,$ValidFrom)
        $CAView.SetRestriction($IndexHash["Certificate Expiration Date"],2,0,$ValidTo)
 
        # brief disposition code explanation:
        # 9 - pending for approval
        # 15 - CA certificate renewal
        # 16 - CA certificate chain
        # 20 - issued certificates
        # 21 - revoked certificates
        # all other - failed requests
 
        $CAView.SetRestriction($IndexHash["Request Disposition"],1,0,$Disposition)
 
        $RowObj = $CAView.OpenView()
 
        try {
            Write-Verbose 'Fetching certificates...'
 
            while ($Rowobj.Next() -ne -1) {
                $Cert = New-Object PsObject
                $ColObj = $RowObj.EnumCertViewColumn()
                [void]$ColObj.Next()
 
                do {
                    $current = $ColObj.GetName()
                    if ($ColObj.GetDisplayName() -eq 'Certificate Hash') {
                        $Cert | Add-Member -MemberType NoteProperty 'Thumbprint' -Value $($ColObj.GetValue(1).ToUpper() -replace "\s") -Force
                    }
                    elseif ($ColObj.GetDisplayName() -eq 'Binary Certificate') {
                        $Cert | Add-Member -MemberType NoteProperty 'BinaryCertificate' -Value "-----BEGIN CERTIFICATE-----`n$($ColObj.GetValue(1))-----END CERTIFICATE-----" -Force
                        $CertObj = [System.Security.Cryptography.X509Certificates.X509Certificate2]([System.Convert]::FromBase64String($ColObj.GetValue(1)))
                        $Cert | Add-Member -MemberType NoteProperty 'CertificateObject' -Value $CertObj -Force
                        # Assuming singletons for EnhancedKeyUsageList and DNSNameList
                        $Cert | Add-Member -MemberType NoteProperty 'EKUName' -Value $CertObj.EnhancedKeyUsageList.FriendlyName -Force
                        $Cert | Add-Member -MemberType NoteProperty 'EKUOid' -Value $CertObj.EnhancedKeyUsageList.ObjectId -Force
                        $Cert | Add-Member -MemberType NoteProperty 'DNSName' -Value $CertObj.DnsNameList.Unicode -Force
                    }
                    else {
                        $Cert | Add-Member -MemberType NoteProperty $($ColObj.GetDisplayName() -replace '\s') -Value $($ColObj.GetValue(1)) -Force
                    }
 
                } until ($ColObj.Next() -eq -1)

                Clear-Variable ColObj
                Clear-Variable CertObj
 
                Write-Output $Cert
            }
        }
        catch {
            if ($_.toString() -like '*CEnumCERTVIEWROW::Next: The parameter is incorrect. 0x80070057*') {
                Write-Verbose "No certificates matched the criteria in the database of $CertificationAuthority"
            }
            else {
                Write-Error $_.toString()
            }
        }
    }
 
    END {
 
        Write-Verbose 'Cleaning up...'
 
        $RowObj.Reset()
        $CaView = $null
        [GC]::Collect()
 
        Write-Verbose 'Function finished.'
    }
}


# Change CA path here
$CertAuth = 'contoso.com\ContosoRootCA'

$PublicKeyDirectory = 'C:\PublicKeys'
New-Item -ItemType Directory -Path $PublicKeyDirectory -Force -ErrorAction SilentlyContinue | Out-Null

# Many-to-Many relationship: Nodes in DB -to- Public Key Certs on CA
# Find the common set, export the files, and update the DB
# Join on HostName/DNSName
### PROBLEM RIGHT NOW IS TO EXTRACT A MATCHING HOSTNAME FROM THE CERTIFICATE DATA CONTAINING UPN,COMPUTER OBJECT NAME,DNSNAME

# Get list of Nodes from DB
$DBInstance = "dscdb"
$Query = "
    SELECT HostName, CertificatePath, CertificateThumbprint
    FROM dscdatabase.dbo.Nodes
"
$Nodes = Invoke-Sqlcmd -ServerInstance "(localdb)\$DBInstance" -Query $Query | Select-Object -ExpandProperty HostName

# $Nodes = "PULL","MS1","MS2"

# Get certs from CA
### Don't want to dump all Document Encryption certs to the folder, only the ones for nodes in scope
$DocEncrCerts = Get-CACertificateDatabase -CertificationAuthority $CertAuth |
    Where-Object {$_.CertificateObject.EnhancedKeyUsageList.FriendlyName -contains 'Document Encryption'} |
    ForEach-Object { $_.BinaryCertificate | Out-File (Join-Path -Path $PublicKeyDirectory -ChildPath "$($_.DNSName).cer") -Encoding default -Verbose -Force}

# Match the nodes to certs
### tbd

# Update the Node DB record to show path to cert and thumbprint
### tbd
