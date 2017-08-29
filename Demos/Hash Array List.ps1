# Richard Rogers, ACS

$hash = @{}
$array = @()
$arraylist = New-Object System.Collections.ArrayList($null)

"`r`nBuild (ms)"
"Build Hash: " + (Measure-Command -Expression {1..2555 | %{$hash.Add("192.168.0.$_",0)}}).TotalMilliseconds
"Build Array: " + (Measure-Command -Expression {1..2555 | %{$array += "192.168.0.$_"}}).TotalMilliseconds
"Build ArrayList: " + (Measure-Command -Expression {1..2555 | %{$arraylist.Add("192.168.0.$_")}}).TotalMilliseconds
"`r`n`r`nSearch (ms)"
"Search Hash: " + (Measure-Command -Expression {1..2555 | %{$hash.ContainsKey("192.168.0.$_")}}).TotalMilliseconds
"Search Array: " + (Measure-Command -Expression {1..2555 | %{$array -contains "192.168.0.$_"}}).TotalMilliseconds
"Search ArrayList: " + (Measure-Command -Expression {1..2555 | %{$arraylist -contains "192.168.0.$_"}}).TotalMilliseconds
"`r`n`r`nSearch - Single item (ms)"
"Search Hash - Single item: " + (Measure-Command -expression {$hash['192.168.0.2555']}).TotalMilliseconds
"Search Array - Single item: " + (Measure-Command -Expression {$array -contains "192.168.0.2554"}).TotalMilliseconds
"Search ArrayList - Single item: " + (Measure-Command -Expression {$arraylist -contains "192.168.0.2553"}).TotalMilliseconds  