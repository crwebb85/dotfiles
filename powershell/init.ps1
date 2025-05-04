$checkhealthConfigPath = Get-ChildItem $PSScriptRoot\init\checkhealth.ps1 | Select-Object -ExpandProperty FullName
Write-Output "Sourcing $checkhealthConfigPath"
. "$checkhealthConfigPath"

$psfzfConfigPath = Get-ChildItem $PSScriptRoot\init\PSFzf\PSFzf.ps1 | Select-Object -ExpandProperty FullName
Write-Output "Sourcing $psfzfConfigPath"
. "$psfzfConfigPath"

$readlineConfigPath = Get-ChildItem $PSScriptRoot\init\readline.ps1 | Select-Object -ExpandProperty FullName
Write-Output "Sourcing $readlineConfigPath"
. "$readlineConfigPath"

Set-Alias -Name zp -Value Invoke-FuzzyProjectLocation
Set-Alias -Name zc -Value Invoke-FuzzySetProofOfConceptLocation 

function Write-BranchName () {
    try {
        $branch = git rev-parse --abbrev-ref HEAD

        if ($branch -eq "HEAD") {
            # we're probably in detached HEAD state, so print the SHA
            $branch = git rev-parse --short HEAD
            Write-Host " ($branch)" -ForegroundColor "red"
        } else {
            # we're on an actual branch, so print it
            Write-Host " ($branch)" -ForegroundColor "blue"
        }
    } catch {
        # we'll end up here if we're in a newly initiated git repo
        Write-Host " (no branches yet)" -ForegroundColor "yellow"
    }
}

$Global:__LastHistoryId = -1

function Get-LastExitCode {
    if ($? -eq $True) {
        return 0
    }
    if ("$LastExitCode" -ne "") {
        return $LastExitCode 
    }
    return -1
}

# Sets the look of the prompt line specifically adding the git branch name
function prompt {
    # based on  https://stackoverflow.com/a/44411205 
    # and https://devblogs.microsoft.com/commandline/shell-integration-in-the-windows-terminal/

    $path = "$($executionContext.SessionState.Path.CurrentLocation)"

    # First, emit a mark for the _end_ of the previous command.
    $gle = $(Get-LastExitCode);
    $LastHistoryEntry = $(Get-History -Count 1)
    # Skip finishing the command if the first command has not yet started
    if ($Global:__LastHistoryId -ne -1) {
        if ($LastHistoryEntry.Id -eq $Global:__LastHistoryId) {
            # Don't provide a command line or exit code if there was no history entry (eg. ctrl+c, enter on no command)
            Write-Host "`e]133;D`a" -NoNewline # OSC 133 ; D ; (“FTCS_COMMAND_FINISHED“) but omit the exit code since there is none
        } else {
            Write-Host "`e]133;D;$gle`a" -NoNewline # OSC 133 ; D ; <ExitCode> ST (“FTCS_COMMAND_FINISHED“) – the end of a command with the last ExitCode. The Terminal will treat 0 as “success” and anything else as an error.
        }
    }

    # Add new line
    Write-Host "`n" -NoNewline

    # Prompt started
    Write-Host "`e]133;A`a" -NoNewline # OSC 133 ; A ST (“FTCS_PROMPT“) – The start of a prompt.

    # Add prompt prefix
    Write-Host "PS `a" -NoNewline 

    # OSC 9 ; 9 ; <CWD> ST (“ConEmu Set working directory“) – Tell the Terminal 
    # what the current working directory is. 
    # CWD needs to be a Windows filesystem path for this to work. 
    # TODO: If using this in WSL or cygwin, I'll need to use wslpath or cygpath.
    Write-Host "`e]9;9;`"$path`"`a" -NoNewline # this path is not visible it is solely for other tools to use

    # Show CWD path
    Write-Host "$path" -NoNewline -ForegroundColor "green"

    $isGitRepo = $(git rev-parse --is-inside-work-tree 2>$null)
    if ($isGitRepo) {
        # Add the git branch name if a git repository
        Write-BranchName
    } 

    $Global:__LastHistoryId = $LastHistoryEntry.Id

    # My Prompt
    $userPrompt = "$('>' * ($nestedPromptLevel + 1))"
    # Prompt ended, Command started
    $userPrompt += "`e]133;B`a" # OSC 133 ; B ST (“FTCS_COMMAND_START“) – The start of a command-line (READ: the end of the prompt).

    return $userPrompt
}
