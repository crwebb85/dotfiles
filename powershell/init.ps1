$readlineConfigPath = Get-ChildItem $PSScriptRoot\init\readline.ps1 | Select -ExpandProperty FullName

echo "Sourcing $readlineConfigPath"
. "$readlineConfigPath"
