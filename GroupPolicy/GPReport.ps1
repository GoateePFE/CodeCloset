<##############################################################################
Ashley McGlone
Microsoft Premier Field Engineer
http://aka.ms/GoateePFE

August 2017

This script creates a report of all group policy objects and their status.
Change the last line to send output to a CSV file.

For more information on gPLink, gPOptions, and gPLinkOptions see:
 [MS-GPOL]: Group Policy: Core Protocol
  http://msdn.microsoft.com/en-us/library/cc232478.aspx
 2.2.2 Domain SOM Search
  http://msdn.microsoft.com/en-us/library/cc232505.aspx
 2.3 Directory Service Schema Elements
  http://msdn.microsoft.com/en-us/library/cc422909.aspx
 3.2.5.1.5 GPO Search
  http://msdn.microsoft.com/en-us/library/cc232537.aspx

Requires:
-PowerShell v3 or above
-RSAT 2012 or above
-AD PowerShell module
-Group Policy module
-Appropriate permissions

LEGAL DISCLAIMER
This Sample Code is provided for the purpose of illustration only and is not
intended to be used in a production environment.  THIS SAMPLE CODE AND ANY
RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a
nonexclusive, royalty-free right to use and modify the Sample Code and to
reproduce and distribute the object code form of the Sample Code, provided
that You agree: (i) to not use Our name, logo, or trademarks to market Your
software product in which the Sample Code is embedded; (ii) to include a valid
copyright notice on Your software product in which the Sample Code is embedded;
and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and
against any claims or lawsuits, including attorneys’ fees, that arise or result
from the use or distribution of the Sample Code.
##############################################################################>

$Server = Get-ADDomainController -Discover | Select-Object -ExpandProperty HostName

# GPOs linked to the root of the domain, OUs, sites
$gPLinks  = @()
$gPLinks += Get-ADObject -Server $Server -Identity (Get-ADDomain).distinguishedName `
    -Properties gPLink | Select-Object distinguishedName, gPLink
$gPLinks += Get-ADOrganizationalUnit -Server $Server -Filter * `
    -Properties gPLink | Select-Object distinguishedName, gPLink
$gPLinks += Get-ADObject -Server $Server -LDAPFilter '(objectClass=site)' `
    -SearchBase "CN=Sites,$((Get-ADRootDSE).configurationNamingContext)" `
    -SearchScope OneLevel `
    -Properties gPLink | Select-Object distinguishedName, gPLink

# Hash table for fast lookups on link status
$gPLinksHash = @{}
$gPLinks.gPLink | Select-Object -Unique |
     ForEach-Object {$gPLinksHash.Add([GUID]($_ -split '{|}')[1],$null)}

Get-GPO -All | Select-Object Path, `
    @{Name='GUID';Expression={$_.ID}}, `
    DisplayName, GPOStatus, `
    @{Name='WMIFilter';Expression={$_.WMIFilter.Name}}, `
    CreationTime, ModificationTime,`
    @{Name='UserVersionDS';Expression={$_.User.DSVersion}}, `
    @{Name='UserVersionSysvol';Expression={$_.User.SysvolVersion}}, `
    @{Name='UserMatch';Expression={$_.User.DSVersion -eq $_.User.SysvolVersion}}, `
    @{Name='ComputerVersionDS';Expression={$_.Computer.DSVersion}}, `
    @{Name='ComputerVersionSysvol';Expression={$_.Computer.SysvolVersion}}, `
    @{Name='ComputerMatch';Expression={$_.Computer.DSVersion -eq $_.Computer.SysvolVersion}},
    @{Name='IsLinked';Expression={$gPLinksHash.ContainsKey($_.Id)}} |
    Out-GridView
    #Export-CSv -Path .\GPOReport.csv -NoTypeInformation
