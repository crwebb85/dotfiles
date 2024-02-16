$moduleNames = "PSReadLine"
foreach ($moduleName in $moduleNames) {

    if (Get-Module -ListAvailable -Name $moduleName) {
        Write-Host "$moduleName exists"
    } 
    else {
        Write-Host "Unable to find module $moduleName"
    }
}

if ((Get-Command "fzf.exe" -ErrorAction SilentlyContinue) -eq $null) 
{ 
   Write-Host "Unable to find fzf.exe in your PATH"
}else {
    Write-Host "fzf is in your PATH"
}

if ((Get-Command "zoxide.exe" -ErrorAction SilentlyContinue) -eq $null) 
{ 
   Write-Host "Unable to find zoxide.exe in your PATH"
}else {
    Write-Host "zoxide is in your PATH"
}
