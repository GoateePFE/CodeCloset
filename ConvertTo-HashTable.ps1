<#
This is a work-in-progress.
Looks like the PlatyPS module in the PSGallery does this already.
#>

Function ConvertTo-HashTable {
param(
    $Object,
    [switch]$AsString
)

    If ($AsString) {
        $ht = "@{`r`n"
        $Object | Get-Member -MemberType Properties | ForEach-Object {
            If ($Object.($_.Name)) {
                $ht += "`t$($_.Name) = $($Object.($_.Name))`r`n"
            }
        }
        $ht += '}'
        $ht
    } Else {
        $ht = @{}
        $Object | Get-Member -MemberType Properties | ForEach-Object {
            If ($Object.($_.Name)) {
                $ht.Add($_.Name,$Object.($_.Name))
            }
        }
        $ht
    }
}

ConvertTo-HashTable -Object (Get-Process idle)

ConvertTo-HashTable -Object (Get-Process idle) -AsString

