break

Install-Module -Name xAdcsDeployment -Force

dir (Get-Module -ListAvailable -Name xAdcsDeployment).ModuleBase -Recurse

psedit "$((Get-Module -ListAvailable -Name xAdcsDeployment).ModuleBase)\Examples\Config-SetupActiveDirectory.ps1"

break
$cred = Get-Credential -UserName proseware\administrator -Message Admin
$s = New-PSSession -ComputerName dc -Credential $cred
Copy-Item -ToSession $s -Path (Split-Path (Get-Module -ListAvailable -Name xAdcsDeployment).ModuleBase -Parent) -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Verbose
Invoke-Command -Session $s -ScriptBlock {dir 'C:\Program Files\WindowsPowerShell\Modules'}
Remove-PSSession $s

configuration InstallADCS
{
    Import-DscResource -ModuleName xAdcsDeployment, PSDesiredStateConfiguration

    node $AllNodes.NodeName
    {    
        WindowsFeature ADCS-Cert-Authority
        {
            Ensure = 'Present'
            Name = 'ADCS-Cert-Authority'
        }

        WindowsFeature ADCS-Web-Enrollment
        {
            Ensure = 'Present'
            Name = 'ADCS-Web-Enrollment'
        }

        xADCSCertificationAuthority ADCS
        {
            Ensure = 'Present'
            Credential = $Node.Credential
            CAType = 'EnterpriseRootCA'
            DependsOn = '[WindowsFeature]ADCS-Cert-Authority'              
        }

        xADCSWebEnrollment CertSrv
        {
            IsSingleInstance = 'Yes'
            Ensure = 'Absent'
            Credential = $Node.Credential
            DependsOn = '[xADCSCertificationAuthority]ADCS'
        }
            
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyandAutoCorrect'
            RebootNodeIfNeeded = $True
            ActionAfterReboot = 'ContinueConfiguration'
        }
    }
}

$configData = @{
    AllNodes = @(
        @{
            Nodename = "dc"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
            Credential = $cred
        }
    )
}


InstallADCS -ConfigurationData $configData

Set-DscLocalConfigurationManager -Path .\InstallADCS -Verbose
Start-DscConfiguration -Path .\InstallADCS -Force -Verbose -Wait

break
Add-WindowsFeature -IncludeAllSubFeature -Name RSAT-ADCS -Verbose
Add-WindowsFeature -IncludeAllSubFeature -Name RSAT-AD-PowerShell -Verbose

break

# PERMISSION WEB SERVER TEMPLATE AND REQUEST CERT

<#
Add Domain Computers with Enroll permission on the Web Server CS template.

ActiveDirectoryRights : ExtendedRight
InheritanceType       : None
ObjectType            : 0e10c968-78fb-11d2-90d4-00c04f79dc55
InheritedObjectType   : 00000000-0000-0000-0000-000000000000
ObjectFlags           : ObjectAceTypePresent
AccessControlType     : Allow
IdentityReference     : CONTOSO\Domain Computers
IsInherited           : False
InheritanceFlags      : None
PropagationFlags      : None
#>

$Domain              = Get-ADDomain
$ConfigNC            = $((Get-ADRootDSE -Server $Server).configurationNamingContext)
$TemplatePath        = "AD:\CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$ConfigNC"
$acl                 = Get-ACL $TemplatePath
$account             = New-Object System.Security.Principal.NTAccount("$($Domain.NetBIOSName)\Domain Computers")
$sid                 = $account.Translate([System.Security.Principal.SecurityIdentifier])
$ObjectType          = [GUID]'0e10c968-78fb-11d2-90d4-00c04f79dc55'
$InheritedObjectType = [GUID]'00000000-0000-0000-0000-000000000000'
$ace                 = New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
    $sid, 'ExtendedRight', 'Allow', $ObjectType, 'None', $InheritedObjectType
$acl.AddAccessRule($ace)
Set-ACL $TemplatePath -AclObject $acl

#endregion ####################################################################

#region CERT REQUEST/INSTALL ##################################################

$Req = @{
    Template          = 'WebServer'
    DnsName           = 'sa.proseware.com'
    SubjectName       = 'CN=sa.proseware.com'
    Url               = 'ldap:'
    CertStoreLocation = 'Cert:\LocalMachine\My'
}
$cert = Get-Certificate @Req
$thumbprint = $cert.Certificate.Thumbprint

#endregion ####################################################################


# CREATE ENCRYPTION TEMPLATE

#requires -Version 5.0 -Modules ActiveDirectory

<#
Create Certificate Template for PowerShell CMS Encryption

Take parameters
Generate a unique OID for the template
Create the template
Permission the template with Enroll for a specified group(s)
Optionally add AutoEnroll permission as well
Add the template for issue

Target all operations to the designated DC

Requirements:
-Enterprise AD CS PKI
-Tested on 2012 R2 & 2016
-Enterprise Administrator rights
-ActiveDirectory PowerShell Module

Template generated will have these properties:
-2 year lifetime
-2003 lowest compatibility level
-Private key not exportable
-Not stored in AD
-Document Encryption
#>


Function Get-RandomHex {
param ([int]$Length)
    $Hex = '0123456789ABCDEF'
    [string]$Return = $null
    For ($i=1;$i -le $length;$i++) {
        $Return += $Hex.Substring((Get-Random -Minimum 0 -Maximum 16),1)
    }
    Return $Return
}

Function IsUniqueOID {
param ($cn,$TemplateOID,$Server,$ConfigNC)
    $Search = Get-ADObject -Server $Server `
        -SearchBase "CN=OID,CN=Public Key Services,CN=Services,$ConfigNC" `
        -Filter {cn -eq $cn -and msPKI-Cert-Template-OID -eq $TemplateOID}
    If ($Search) {$False} Else {$True}
}

Function New-TemplateOID {
Param($Server,$ConfigNC)
    <#
    OID CN/Name                    [10000000-99999999].[32 hex characters]
    OID msPKI-Cert-Template-OID    [Forest base OID].[1000000-99999999].[10000000-99999999]  <--- second number same as first number in OID name
    #>
    do {
        $OID_Part_1 = Get-Random -Minimum 1000000  -Maximum 99999999
        $OID_Part_2 = Get-Random -Minimum 10000000 -Maximum 99999999
        $OID_Part_3 = Get-RandomHex -Length 32
        $OID_Forest = Get-ADObject -Server $Server `
            -Identity "CN=OID,CN=Public Key Services,CN=Services,$ConfigNC" `
            -Properties msPKI-Cert-Template-OID |
            Select-Object -ExpandProperty msPKI-Cert-Template-OID
        $msPKICertTemplateOID = "$OID_Forest.$OID_Part_1.$OID_Part_2"
        $Name = "$OID_Part_2.$OID_Part_3"
    } until (IsUniqueOID -cn $Name -TemplateOID $msPKICertTemplateOID -Server $Server -ConfigNC $ConfigNC)
    Return @{
        TemplateOID  = $msPKICertTemplateOID
        TemplateName = $Name
    }
}


<#
.SYNOPSIS
Creates a new Active Directory Certificate Services template for PowerShell CMS encryption.
.DESCRIPTION
The template can be used for CMS cmdlet encryption and/or DSC credential encryption.
.NOTES
The OID generated does not use the correct API. It is a hack, but it works. Please report any issues.
.PARAMETER DisplayName
DisplayName for the certificate template.
.PARAMETER Server
Active Directory Domain Controller to target for the operation.
.PARAMETER GroupName
Global group(s) to assign permissions to enroll the template.
Specify in DOMAIN\GROUP naming convention.
Default is Domain Computers.
.PARAMETER AutoEnroll
Switch to also grant AutoEnroll to the group(s).
Default is only Enroll.
.EXAMPLE
New-ADCSTemplateForPSEncryption -DisplayName PowerShellCMS
.EXAMPLE
New-ADCSTemplateForPSEncryption -DisplayName PowerShellCMS -Server dc1.contoso.com -GroupName G_DSCNodes -AutoEnroll
#>
Function New-ADCSTemplateForPSEncryption {
param(
    [parameter(Mandatory)]
    [string]$DisplayName,
    [string]$Server = (Get-ADDomainController -Discover -ForceDiscover -Writable).HostName[0],
    [string[]]$GroupName = "$((Get-ADDomain).NetBIOSName)\Domain Computers",
    [switch]$AutoEnroll = $false
)
    Import-Module ActiveDirectory
    $ConfigNC = $((Get-ADRootDSE -Server $Server).configurationNamingContext)

    #region CREATE OID
    <#
    CN                              : 14891906.F2AC4390685318BD1D950A66EDB50FF4
    DisplayName                     : TemplateNameHere
    DistinguishedName               : CN=14891906.F2AC4390685318BD1D950A66EDB50FF4,CN=OID,CN=Public Key Services,CN=Services,CN=Configuration,DC=contoso,DC=com
    dSCorePropagationData           : {1/1/1601 12:00:00 AM}
    flags                           : 1
    instanceType                    : 4
    msPKI-Cert-Template-OID         : 1.3.6.1.4.1.311.21.8.11489019.14294623.5588661.594850.12204198.151.6616009.14891906
    Name                            : 14891906.F2AC4390685318BD1D950A66EDB50FF4
    ObjectCategory                  : CN=ms-PKI-Enterprise-Oid,CN=Schema,CN=Configuration,DC=contoso,DC=com
    ObjectClass                     : msPKI-Enterprise-Oid
    #>
    $OID = New-TemplateOID -Server $Server -ConfigNC $ConfigNC
    $TemplateOIDPath = "CN=OID,CN=Public Key Services,CN=Services,$ConfigNC"
    $oa = @{
	    'DisplayName' = $DisplayName
	    'flags' = [System.Int32]'1'
	    'msPKI-Cert-Template-OID' = $OID.TemplateOID
    }
    New-ADObject -Path $TemplateOIDPath -OtherAttributes $oa -Name $OID.TemplateName -Type 'msPKI-Enterprise-Oid' -Server $Server
    #endregion

    #region CREATE TEMPLATE
    $oa = @{
	    'flags' = [System.Int32]'131680'
	    'msPKI-Certificate-Application-Policy' = [Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]@('1.3.6.1.4.1.311.80.1')
	    'msPKI-Certificate-Name-Flag' = [System.Int32]'268435456'
	    'msPKI-Enrollment-Flag' = [System.Int32]'32'
	    'msPKI-Minimal-Key-Size' = [System.Int32]'2048'
	    'msPKI-Private-Key-Flag' = [System.Int32]'16842752'
	    'msPKI-Template-Minor-Revision' = [System.Int32]'1'
	    'msPKI-Template-Schema-Version' = [System.Int32]'2'
        'msPKI-RA-Signature' = [System.Int32]'0'
        'pKIMaxIssuingDepth' = [System.Int32]'0'
	    'ObjectClass' = [System.String]'pKICertificateTemplate'
	    'pKICriticalExtensions' = [Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]@('2.5.29.15')
	    'pKIDefaultCSPs' = [Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]@('1,Microsoft RSA SChannel Cryptographic Provider')
	    'pKIDefaultKeySpec' = [System.Int32]'1'
	    'pKIExpirationPeriod' = [System.Byte[]]@('0','128','114','14','93','194','253','255')
	    'pKIExtendedKeyUsage' = [Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]@('1.3.6.1.4.1.311.80.1')
	    'pKIKeyUsage' = [System.Byte[]]@('32')
	    'pKIOverlapPeriod' = [System.Byte[]]@('0','128','166','10','255','222','255','255')
	    'revision' = [System.Int32]'100'
        'msPKI-Cert-Template-OID' = $OID.TemplateOID
    }
    $TemplatePath = "CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigNC"
    New-ADObject -Path $TemplatePath -OtherAttributes $oa -Name $DisplayName -DisplayName $DisplayName -Type pKICertificateTemplate -Server $Server
    #endregion

    #region ISSUE
    $EnrollmentPath = "CN=Enrollment Services,CN=Public Key Services,CN=Services,$ConfigNC"
    $CAs = Get-ADObject -SearchBase $EnrollmentPath -SearchScope OneLevel -Filter * -Server $Server
    ForEach ($CA in $CAs) {
        Set-ADObject -Identity $CA.DistinguishedName -Add @{certificateTemplates=$DisplayName} -Server $Server
    }
    #endregion

    #region PERMISSIONS
    ## Potential issue here that the AD: drive may not be targetting the selected DC in the -SERVER parameter
    $TemplatePath            = "AD:\CN=$DisplayName,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigNC"
    $acl                     = Get-ACL $TemplatePath
    $InheritedObjectType = [GUID]'00000000-0000-0000-0000-000000000000'
    ForEach ($Group in $GroupName) {
        $ObjectType          = [GUID]'0e10c968-78fb-11d2-90d4-00c04f79dc55'
        $account             = New-Object System.Security.Principal.NTAccount($Group)
        $sid                 = $account.Translate([System.Security.Principal.SecurityIdentifier])
        $ace                 = New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
            $sid, 'ExtendedRight', 'Allow', $ObjectType, 'None', $InheritedObjectType
        $acl.AddAccessRule($ace)

        If ($AutoEnroll) {
            $ObjectType      = [GUID]'a05b8cc2-17bc-4802-a710-e7c15ab866a2'
            $ace             = New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
                $sid, 'ExtendedRight', 'Allow', $ObjectType, 'None', $InheritedObjectType
            $acl.AddAccessRule($ace)
        }
    }
    Set-ACL $TemplatePath -AclObject $acl
    #endregion
}

New-ADCSTemplateForPSEncryption -DisplayName PSCMS -AutoEnroll -Server dc.proseware.com -GroupName 'proseware\Domain Computers','proseware\Domain Controllers'


$Req = @{
    Template          = 'PSCMS'
    Url               = 'ldap:'
    CertStoreLocation = 'Cert:\LocalMachine\My'
}
Get-Certificate @Req

$DocEncrCert = (dir Cert:\LocalMachine\My -DocumentEncryptionCert)[-1]
Protect-CmsMessage -To $DocEncrCert -Content "Encrypted with my new cert from the new template!"

