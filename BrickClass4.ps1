# Add a method for Show()
# Change default constructor to randomize all properties

Enum style {
    Brick
    Round
    RoofTile45
    RoofTile25
}

Enum color {
    Yellow
    Red
    Orange
    Black
    Gray
    Blue
    Green
    White
}


class brick {
[style] $Style
[color] $Color
[string] $Size


# Constructor is a function named same as the class
# $this references the properties of the object
Brick() {
    [style] $this.Style = (0..3 | Get-Random)
    [color] $this.Color = (0..7 | Get-Random)
    [string]$this.Size = ('1x1','1x2','2x2','1x6','2x3','2x6','2x8','2x10' | Get-Random)

    # If the style is a roof tile, then it can only be 1 stud wide.
    If ($this.Style -like "RoofTile*") {$this.Size = '1' + $this.Size.Substring(1,2)}
}


# Overloaded constructor
Brick(
    [style]$Style,
    [color]$Color,
    [string]$Size
)
{
    $this.Style = $Style
    $this.Color = $Color
    $this.Size  = $Size
}


[string]Measure()
{
    $Studs = Invoke-Expression $this.Size.Replace('x','*')
    If ($Studs -eq 1) {$Plural = $null} Else {$Plural = 's'}
    Return "$($this.Color) $($this.Style) $($this.Size) has $Studs stud$Plural."
}


[void]Show()
{
    $null = $this.Size -match '(?<Dim1>\d)x(?<Dim2>\d)'
    $Slope = $null
    For ($s=1; $s -le [int]$Matches.Dim1; $s++) {
        Write-Host ('O' * [int]$Matches.Dim2) -BackgroundColor (($this.Color -replace 'Orange','Yellow') -replace 'Brown','DarkRed')
        If ($this.Style -like '*tile*') {
            Switch -Wildcard ($this.Style) {
                '*25*' {$Slope = 2;break}
                '*45*' {$Slope = 1}
            }
            1..$Slope | ForEach-Object {
                Write-Host (' ' * [int]$Matches.Dim2) -BackgroundColor (($this.Color -replace 'Orange','Yellow') -replace 'Brown','DarkRed')
            }
        }
    }
}

}


$b = [brick]::New('RoofTile45','Green','1x2')

$b

# Notice new method "Show"
$b | Get-Member

$b.Measure()
$b.Show()

[brick]::New().Show()
