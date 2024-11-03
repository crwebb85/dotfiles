try {
    $readlineConfigPath = Get-ChildItem $PSScriptRoot\PSFzf.Base.ps1 | Select-Object -ExpandProperty FullName
    . "$readlineConfigPath"

    $readlineConfigPath = Get-ChildItem $PSScriptRoot\PSFzf.Functions.ps1 | Select-Object -ExpandProperty FullName
    . "$readlineConfigPath"

    $readlineConfigPath = Get-ChildItem $PSScriptRoot\PSFzf.Git.ps1 | Select-Object -ExpandProperty FullName
    . "$readlineConfigPath"

    $readlineConfigPath = Get-ChildItem $PSScriptRoot\PSFzf.TabExpansion.ps1 | Select-Object -ExpandProperty FullName
    . "$readlineConfigPath"
} catch {
    # Output the Error and Log to a file
    Write-host -f red "Encountered Error:"$_.Exception.Message
}


