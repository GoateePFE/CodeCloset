
# Rename a column
# Calculate a column

Get-ChildItem C:\Windows -File |
Select-Object Name, Length, `
    @{Name='Size';Expression={$_.Length}},
    @{Name='SizeInKB';Expression={[math]::Round($_.Length/1kb,2)}} |
Format-Table -AutoSize

# See example 4
(Get-Help Select-Object).Examples

