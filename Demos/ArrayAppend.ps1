$files = @(Get-ChildItem C:\windows)

Measure-Command -Expression {
    $myarray = @()
    ForEach ($file in $files) {
        $myarray += $file.name
    }
    $myarray
}


Measure-Command -Expression {
    $myarray = ForEach ($file in $files) {
        $file.name
    }
    $myarray
}
