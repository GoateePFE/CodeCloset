# Array search performance

$array = (dir C:\Windows\ -File).Name
$array

$entry = 'invalidentry'
$entry = 'system.ini'
$found = $false
For ($i=0; $i -lt $array.count; $i++) {
    If ($array[$i] -eq $entry) {
        "We found $entry after $($i+1) iterations."
        $found = $true
        Break
    }
}
If (-not $found) {
    "We did not find $entry after $($i+1) iterations."
}


# Hash table search performance

$hashtable = @{}
ForEach ($file in (dir C:\Windows\ -File).Name) {
    $hashtable.Add($file,$null)
}

$entry = 'invalidentry'
$entry = 'system.ini'
$hashtable.ContainsKey($entry)


# Compare performance after 100 searches for item NOT in the set

# Array crawling search
Measure-Command -Expression {
    For ($h=1; $h -le 100; $h++) {
        $found = $false
        For ($i=0; $i -lt $array.count; $i++) {
            If ($array[$i] -eq 'invalidentry') {
                $found = $true
                Break
            }
        }
    }
}

# Hash search
Measure-Command -Expression {
    For ($h=1; $h -le 100; $h++) {
        $hashtable.ContainsKey('invalidentry')
    }
}
