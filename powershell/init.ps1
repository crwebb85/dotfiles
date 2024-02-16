$checkhealthConfigPath = Get-ChildItem $PSScriptRoot\init\checkhealth.ps1 | Select -ExpandProperty FullName
echo "Sourcing $checkhealthConfigPath"
. "$checkhealthConfigPath"

$readlineConfigPath = Get-ChildItem $PSScriptRoot\init\PSFzf\PSFzf.ps1 | Select -ExpandProperty FullName
echo "Sourcing $readlineConfigPath"
. "$readlineConfigPath"

$readlineConfigPath = Get-ChildItem $PSScriptRoot\init\readline.ps1 | Select -ExpandProperty FullName
echo "Sourcing $readlineConfigPath"
. "$readlineConfigPath"

