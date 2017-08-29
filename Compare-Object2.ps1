<#
.SYNOPSIS
Faster version of Compare-Object for large data sets.
.DESCRIPTION
Uses hash tables to improve comparison performance for large data sets.
This version outputs whole object data in the comparison results when
the Property parameter is used, rather than just the properties compared.
.PARAMETER ReferenceObject
Specifies an array of objects used as a reference for comparison.
.PARAMETER DifferenceObject
Specifies the objects that are compared to the reference objects.
.PARAMETER IncludeEqual
Indicates that this cmdlet displays characteristics of compared objects that
are equal. By default, only characteristics that differ between the reference
and difference objects are displayed.
.PARAMETER ExcludeDifferent
Indicates that this cmdlet displays only the characteristics of compared
objects that are equal.
.PARAMETER Property
Specifies an array of properties of the reference and difference objects to 
compare.
If specified, then whole objects are returned in the comparison output.
When the objects are equal, the data returned is from the ReferenceObject.
This is a design choice. It makes the assumption that the DifferenceObject 
is going to be entirely the same, but it may not be.
.EXAMPLE
Compare-Object2 -ReferenceObject 'a','b','c' -DifferenceObject 'c','d','e' `
    -IncludeEqual -ExcludeDifferent
.EXAMPLE
Compare-Object2 -ReferenceObject (Get-Content .\file1.txt) `
    -DifferenceObject (Get-Content .\file2.txt)
.EXAMPLE
$p1 = Get-Process
notepad
$p2 = Get-Process
Compare-Object2 -ReferenceObject $p1 -DifferenceObject $p2 -Property Id, Name | Out-Gridview
.EXAMPLE
$s1 = Get-Service -Name *in*
$s2 = Get-Service -Name w*
Compare-Object2 -ReferenceObject $s1 -DifferenceObject $s2 -Property Name -IncludeEqual | Out-Gridview
.NOTES
Includes optimization to run even faster when -IncludeEqual is omitted.
Duplicate objects in a single list will cause an error.
Assumes the objects are of the same type. May fail with data types other 
than simple strings, integers, booleans, etc. The comparison is a hack
using ConvertTo-CSV. If the object properties are faithfully represented
as string from ConvertTo-CSV, then the comparison will likely work.
Multi-value properties will likely fail.
#>
function Compare-Object2 {
param(
    [psobject[]]
    $ReferenceObject,
    [psobject[]]
    $DifferenceObject,
    [switch]
    $IncludeEqual,
    [switch]
    $ExcludeDifferent,
    [string[]]
    $Property
)

    # Put the difference array into a hash table,
    # then destroy the original array variable for memory efficiency.
    $DifHash = @{}
    If ($PSBoundParameters.ContainsKey('Property')) {
        $DifferenceObject | ForEach-Object {$DifHash.Add(($_ | Select-Object $Property | ConvertTo-Csv -NoTypeInformation)[1],$_)}
    } Else {
        $DifferenceObject | ForEach-Object {$DifHash.Add($_,$null)}
    }
    Remove-Variable -Name DifferenceObject

    # Put the reference array into a hash table.
    # Keep the original array for enumeration use.
    $RefHash = @{}
    If ($PSBoundParameters.ContainsKey('Property')) {
        for ($i=0;$i -lt $ReferenceObject.Count;$i++) {
            $RefHash.Add(($ReferenceObject[$i] | Select-Object $Property | ConvertTo-Csv -NoTypeInformation)[1],$ReferenceObject[$i])
        }
    } Else {
        for ($i=0;$i -lt $ReferenceObject.Count;$i++) {
            $RefHash.Add($ReferenceObject[$i],$null)
        }
    }

    # This code is ugly but faster.
    # Do the IF only once per run instead of every iteration of the ForEach.
    If ($PSBoundParameters.ContainsKey('Property')) {
        If ($IncludeEqual) {
            $EqualHash = @{}
            # You cannot enumerate with ForEach over a hash table while you remove
            # items from it.
            # Must use the static array of reference to enumerate the items.
            ForEach ($Item in ($ReferenceObject | Select-Object $Property | ForEach-Object {($_ | ConvertTo-Csv -NoTypeInformation)[1]})) {
                If ($DifHash.ContainsKey($Item)) {
                    $EqualHash.Add($Item,$RefHash[$Item])
                    $DifHash.Remove($Item)
                    $RefHash.Remove($Item)
                }
            }
        } Else {
            ForEach ($Item in ($ReferenceObject | Select-Object $Property | ForEach-Object {($_ | ConvertTo-Csv -NoTypeInformation)[1]})) {
                If ($DifHash.ContainsKey($Item)) {
                    $DifHash.Remove($Item)
                    $RefHash.Remove($Item)
                }
            }
        }
    } Else {
        If ($IncludeEqual) {
            $EqualHash = @{}
            # You cannot enumerate with ForEach over a hash table while you remove
            # items from it.
            # Must use the static array of reference to enumerate the items.
            ForEach ($Item in $ReferenceObject) {
                If ($DifHash.ContainsKey($Item)) {
                    $EqualHash.Add($Item,$null)
                    $DifHash.Remove($Item)
                    $RefHash.Remove($Item)
                }
            }
        } Else {
            ForEach ($Item in $ReferenceObject) {
                If ($DifHash.ContainsKey($Item)) {
                    $DifHash.Remove($Item)
                    $RefHash.Remove($Item)
                }
            }
        }
    }

    If ($PSBoundParameters.ContainsKey('Property')) {
        If ($IncludeEqual) {
            $EqualHash.Values | Select-Object @{Name='SideIndicator';Expression={'=='}}, *
        }

        If (-not $ExcludeDifferent) {
            $RefHash.Values | Select-Object @{Name='SideIndicator';Expression={'<='}}, *
            $DifHash.Values | Select-Object @{Name='SideIndicator';Expression={'=>'}}, *
        }
    } Else {
        If ($IncludeEqual) {
            $EqualHash.Keys | Select-Object @{Name='InputObject';Expression={$_}},`
                @{Name='SideIndicator';Expression={'=='}}
        }

        If (-not $ExcludeDifferent) {
            $RefHash.Keys | Select-Object @{Name='InputObject';Expression={$_}},`
                @{Name='SideIndicator';Expression={'<='}}
            $DifHash.Keys | Select-Object @{Name='InputObject';Expression={$_}},`
                @{Name='SideIndicator';Expression={'=>'}}
        }
    }
}


cd 'C:\Users\asmcglon\Documents\_Customers\Huntington NB\Compare-Object'

Measure-Command -Expression {
    Compare-Object  -ReferenceObject (Get-Content .\file1a.txt) `
        -DifferenceObject (Get-Content .\file2a.txt) -IncludeEqual
} | Select-Object TotalMilliseconds

Measure-Command -Expression {
    Compare-Object2 -ReferenceObject (Get-Content .\file1a.txt) `
        -DifferenceObject (Get-Content .\file2a.txt) `
        -IncludeEqual -ExcludeDifferent
} | Select-Object TotalMilliseconds

Measure-Command -Expression {
Compare-Object  -ReferenceObject 'a','b','c' -DifferenceObject 'c','d','e' `
    -IncludeEqual -ExcludeDifferent
} | Select-Object TotalMilliseconds

Measure-Command -Expression {
Compare-Object2 -ReferenceObject 'a','b','c' -DifferenceObject 'c','d','e' `
    -IncludeEqual -ExcludeDifferent
} | Select-Object TotalMilliseconds


Start-Process calc
$p1 = Get-Process
Get-Process calc | Stop-Process
Start-Process notepad
$p2 = Get-Process
Get-Process notepad | Stop-Process
Compare-Object2 -ReferenceObject $p1 -DifferenceObject $p2 -Property Id
Compare-Object2 -ReferenceObject $p1 -DifferenceObject $p2 -Property Id, Name | ogv
Compare-Object2 -ReferenceObject $p1 -DifferenceObject $p2 -Property Id, Name -IncludeEqual -ExcludeDifferent | ogv
Compare-Object2 -ReferenceObject $p1 -DifferenceObject $p2 -Property Id -IncludeEqual -ExcludeDifferent
Compare-Object -ReferenceObject $p1 -DifferenceObject $p2 -Property Id -IncludeEqual -ExcludeDifferent

Compare-Object2 -ReferenceObject $p1 -DifferenceObject $p2 -Property Id -IncludeEqual | Select-Object -ExpandProperty InputObject
Compare-Object2 -ReferenceObject $p1 -DifferenceObject $p2 -Property Id -IncludeEqual -ExcludeDifferent

$s1 = Get-Service -Name *in*
$s2 = Get-Service -Name w*
Compare-Object2 -ReferenceObject $s1.name -DifferenceObject $s2.name -IncludeEqual | ogv
Compare-Object2 -ReferenceObject $s1 -DifferenceObject $s2 -Property Name -IncludeEqual | ogv
