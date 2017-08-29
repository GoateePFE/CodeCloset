
Function Clean-CarriageReturns {
param($string)
    while ($string.contains("`r`n`r`n`r`n")) {
        $string = $string.replace("`r`n`r`n`r`n","`r`n`r`n")
    }
    return $string
}

Import-Module .\RBKCD.psm1 -Force

$ModuleName = 'RBKCD'

"# Help for module " + $ModuleName | Set-Content -Path ".\$($ModuleName).md"

$md = ForEach ($cmdlet in (Get-Command -Module $ModuleName).Name) {

    $gh = Get-Help $cmdlet -Full

    ""
    "## " + $gh.Name
    ""

    "### Synopsis"
    $gh.Synopsis
    ""

    "### Description"
    $gh.description.text
    ""

    "### Parameters"
    $gh.parameters.parameter | Out-String

    If ($gh.alertSet) {
        "### Notes"
        $gh.alertSet.alert.text
        ""
    }

    "### Examples"
    #$gh.Examples.example | Out-String
    $gh.Examples.example | %{
        $_.title
        ""
        '```'
        $_.introduction.text + ' ' + ($_.code -join "`r`n") + "`r`n" + ($_.remarks.text -join "`r`n")
        '```'
    }
}

Clean-CarriageReturns -String ($md -join "`r`n") | Add-Content -Path ".\$($ModuleName).md"
