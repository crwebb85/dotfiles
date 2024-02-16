$readlineConfigPath = Get-ChildItem $PSScriptRoot\PSFzf.Base.ps1 | Select -ExpandProperty FullName
. "$readlineConfigPath"

$readlineConfigPath = Get-ChildItem $PSScriptRoot\PSFzf.Functions.ps1 | Select -ExpandProperty FullName
. "$readlineConfigPath"

$readlineConfigPath = Get-ChildItem $PSScriptRoot\PSFzf.Git.ps1 | Select -ExpandProperty FullName
. "$readlineConfigPath"

$readlineConfigPath = Get-ChildItem $PSScriptRoot\PSFzf.TabExpansion.ps1 | Select -ExpandProperty FullName
. "$readlineConfigPath"

