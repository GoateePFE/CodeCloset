<#
.SYNOPSIS
You'll love this one.
.DESCRIPTION
Get your awesome on!
.EXAMPLE
Get-Awesome
#>
Function Get-Awesome {
    "Everything is awesome!"
}

<#
.SYNOPSIS
Run this to become awesome!
.DESCRIPTION
You can even make your friends awesome with the Name parameter.
.EXAMPLE
Set-Awesome
.EXAMPLE
Set-Awesome -Name Emmet
#>
Function Set-Awesome {
param(
    $Name = 'Emmet'
)
    "Today, $Name is $(Get-Random -Maximum 120 -Minimum 80)% awesome!"
}

<#
.SYNOPSIS
Dumps all the legos into the floor.
.DESCRIPTION
Optionally specify how many you want.
.PARAMETER Count
How many bricks do you want?
.EXAMPLE
Get-Brick
.EXAMPLE
Get-Brick -Count 5
#>
Function Get-Brick {
param($Count = 1)

@'
Style,Color,Size
Brick,Blue,2x8
Brick,Blue,2x3
Round,Blue,2x2
Brick,Green,2x6
Brick,Green,2x3
Brick,Green,2x2
Roof Tile 45,Green,1x1
Brick,White,1x6
Brick,White,1x4
Brick,White,2x4
Brick,White,2x2
Round,White,1x1
Round,White,2x2
Brick,Black,2x6
Brick,Black,2x2
Round,Black,1x1
Roof Tile 25,Black,1x1
Brick,Gray,2x3
Round,Gray,2x2
Roof Tile 45,Gray,1x1
Brick,Brown,2x6
Brick,Brown,1x2
Round,Brown,1x1
Round,Brown,2x2
Brick,Red,2x8
Brick,Red,1x6
Brick,Red,2x4
Brick,Red,1x2
Roof Tile 45,Red,1x1
Roof Tile 45,Red,1x2
Round,Red,1x1
Round,Red,2x2
Brick,Orange,2x3
Brick,Orange,1x2
Roof Tile 45,Orange,1x2
Brick,Yellow,2x4
Brick,Yellow,1x2
Roof Tile 45,Yellow,1x2
'@ | ConvertFrom-Csv | Get-Random -Count $Count
}

<#
Function Pick-Brick {

    # This method returns invalid combinations
    $Color = 'Yellow','Green','Red','Blue','Black','Gray' | Get-Random
    $Size  = '1x8','1x1','1x2','2x3','2x4','2x6','2x8' | Get-Random
    $Shape = 'Brick','Round','Roof Tile' | Get-Random

    "Can you find a $Color $Shape $Size ?"

}
#>

Function Find-Brick {

    # This methods guarantees valid combinations
    $Brick = Get-Brick -Count 1

    "Can you find a $($Brick.Color) $($Brick.Style) $($Brick.Size)?"

}

<#
.SYNOPSIS
Counts the studs on a brick.
.DESCRIPTION
Pipe Get-Brick into Measure-Brick.
.PARAMETER Brick
A brick coming from the Get-Brick cmdlet.
.EXAMPLE
Get-Brick | Measure-Brick
.EXAMPLE
Get-Brick -Count 5 | Measure-Brick
#>
Function Measure-Brick {
param(
    [parameter(ValueFromPipeline=$true)]
    $Brick
)

Process
{
    $Studs = Invoke-Expression $Brick.Size.Replace('x','*')
    If ($Studs -eq 1) {$Plural = $null} Else {$Plural = 's'}
    "$($Brick.Color) $($Brick.Style) $($Brick.Size) has $Studs stud$Plural."
}

}

<#
.SYNOPSIS
Displays a brick in colorful ASCII art.
.DESCRIPTION
Pipe Get-Brick into Show-Brick.
.PARAMETER Brick
A brick coming from the Get-Brick cmdlet.
.EXAMPLE
Get-Brick | Show-Brick
.EXAMPLE
Get-Brick -Count 5 | Show-Brick
#>
Function Show-Brick {
param(
    [parameter(ValueFromPipeline=$true)]
    $Brick
)

Process
{
    $null = $Brick.Size -match '(?<Dim1>\d)x(?<Dim2>\d)'
    $Brick
    For ($s=1; $s -le [int]$Matches.Dim1; $s++) {

<# Horizontal algorithm, but break with 1x2 shape
        Write-Host ('O' * [int]$Matches.Dim2) -BackgroundColor (($Brick.Color -replace 'Orange','Yellow') -replace 'Brown','DarkRed') -NoNewline
        If ($Brick.Style -like '*tile*') {
            Switch -Wildcard ($Brick.Style) {
                '*25*' {$Slope = 2;break}
                '*45*' {$Slope = 1}
            }
            Write-Host (' ' * $Slope) -BackgroundColor (($Brick.Color -replace 'Orange','Yellow') -replace 'Brown','DarkRed') -NoNewline
        }
        Write-Host ''
#>

        Write-Host ('O' * [int]$Matches.Dim2) -BackgroundColor (($Brick.Color -replace 'Orange','Yellow') -replace 'Brown','DarkRed')
        If ($Brick.Style -like '*tile*') {
            Switch -Wildcard ($Brick.Style) {
                '*25*' {$Slope = 2;break}
                '*45*' {$Slope = 1}
            }
            1..$Slope | ForEach-Object {
                Write-Host (' ' * [int]$Matches.Dim2) -BackgroundColor (($Brick.Color -replace 'Orange','Yellow') -replace 'Brown','DarkRed')
            }
        }
    }
}

}
