Write-Host "Press any key..."
$keyInfo = [Console]::ReadKey($true)

Write-Host "You pressed:"
Write-Host "  Key: $($keyInfo.Key)"
Write-Host "  Character: $($keyInfo.KeyChar)"
Write-Host "  Modifiers: $($keyInfo.Modifiers)"

Write-Host "You pressed $($keyInfo.Key)  + $($keyInfo.Modifiers)"

