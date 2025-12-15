run

```
nvim ./ --clean -u .\cli-tools\debug-keymap-issues\set_powershell_shell.lua -c "terminal"
./cli-tools/debug-keymap-issues/printkey.ps1
```

or

```
cd ./cli-tools/debug-keymap-issues
nvim ./ --clean -u .\set_powershell_shell.lua -c "terminal"
.\printkey.ps1
```
