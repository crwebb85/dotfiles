
function Invoke-FuzzyProjectLocation() {
    param($SearchString = $null)
    $SearchPaths = @()
    $MyDocumentsPath = [Environment]::GetFolderPath("MyDocuments") # Windows likes to now default this to the OneDrive Documents folder 
    if ($null -ne $MyDocumentsPath -and $(Test-Path -Path "$MyDocumentsPath" -PathType Any)) {
        $SearchPath = [System.IO.Path]::Combine($MyDocumentsPath, "projects")
        if ($(Test-Path -Path "$SearchPath" -PathType Any)) {
            $SearchPaths += $SearchPath
        }
    }

    $UserProfilePath = $env:USERPROFILE
    if ($null -ne $UserProfilePath -and $(Test-Path -Path "$UserProfilePath" -PathType Any)) { 
        $SecondaryMyDocumentsPath = [System.IO.Path]::Combine($UserProfilePath, "documents")

        $SearchPath = [System.IO.Path]::Combine($SecondaryMyDocumentsPath, "projects")
        if ($(Test-Path -Path "$SearchPath" -PathType Any) -and $SearchPath -notin $SearchPaths) {
            $SearchPaths += $SearchPath
        }
    }

    # Note: MYWORKSPACE is a custom environment variable I will add
    # if I need to store my projects/poc's on a different drive and not in my
    # documents folder
    $MyWorkspacePath = $env:MYWORKSPACE
    if ($null -ne $MyWorkspacePath -and $(Test-Path -Path "$MyWorkspacePath" -PathType Any)) { 
        $SearchPath = [System.IO.Path]::Combine($MyWorkspacePath, "projects")
        if ($(Test-Path -Path "$SearchPath" -PathType Any) -and $SearchPath -notin $SearchPaths) {
            $SearchPaths += $SearchPath
        }
    }

    $PossiblePaths = @()
    $PossiblePaths += @(Get-ChildItem $SearchPaths -Directory -ErrorAction Ignore  | Select-Object FullName)


    # Add my dotfiles to the searchable list (for quick selection)
    $ConfigPath = $Env:XDG_CONFIG_HOME
    if ($null -ne $ConfigPath -and $(Test-Path -Path "$ConfigPath" -PathType Any)) {
        $PossiblePaths += $ConfigPath
    }

    # Add the project parent directories to the searchable list (to make creating new projects easier)
    $PossiblePaths += $SearchPaths
    
    $result = $null
    try {
        $PossiblePaths | Invoke-Fzf -Query $SearchString | ForEach-Object { $result = $_ }
    } catch {
        
    }

    if ($null -ne $result) {
        Set-Location $result
    }
}

function Invoke-FuzzySetProofOfConceptLocation() {
    param($SearchString = $null)

    $SearchPaths = @()
    $MyDocumentsPath = [Environment]::GetFolderPath("MyDocuments") # Windows likes to now default this to the OneDrive Documents folder 
    if ($null -ne $MyDocumentsPath -and $(Test-Path -Path "$MyDocumentsPath" -PathType Any)) {
        $SearchPath = [System.IO.Path]::Combine($MyDocumentsPath, "poc")
        if ($(Test-Path -Path "$SearchPath" -PathType Any)) {
            $SearchPaths += $SearchPath
        }
    }

    $UserProfilePath = $env:USERPROFILE
    if ($null -ne $UserProfilePath -and $(Test-Path -Path "$UserProfilePath" -PathType Any)) { 
        $SecondaryMyDocumentsPath = [System.IO.Path]::Combine($UserProfilePath, "documents")

        $SearchPath = [System.IO.Path]::Combine($SecondaryMyDocumentsPath, "poc")
        if ($(Test-Path -Path "$SearchPath" -PathType Any) -and $SearchPath -notin $SearchPaths) {
            $SearchPaths += $SearchPath
        }
    }

    # Note: MYWORKSPACE is a custom environment variable I will add
    # if I need to store my projects/poc's on a different drive and not in my
    # documents folder
    $MyWorkspacePath = $env:MYWORKSPACE
    if ($null -ne $MyWorkspacePath -and $(Test-Path -Path "$MyWorkspacePath" -PathType Any)) { 
        $SearchPath = [System.IO.Path]::Combine($MyWorkspacePath, "poc")
        if ($(Test-Path -Path "$SearchPath" -PathType Any) -and $SearchPath -notin $SearchPaths) {
            $SearchPaths += $SearchPath
        }
    }

    $PossiblePaths = @()
    $PossiblePaths += @(Get-ChildItem $SearchPaths -Directory -ErrorAction Ignore  | Select-Object FullName)

    # Add the poc parent directories to the searchable list (to make creating new poc's easier)
    $PossiblePaths += $SearchPaths

    $result = $null
    try {
        $PossiblePaths | Invoke-Fzf -Query $SearchString | ForEach-Object { $result = $_ }
    } catch {
        
    }

    if ($null -ne $result) {
        Set-Location $result
    }
}

# TODO this doesn't actually seem to work
function Invoke-Reload-Profile {
    @( $Profile.AllUsersAllHosts, 
       $Profile.AllUsersCurrentHost, 
       $Profile.CurrentUserAllHosts, 
       $Profile.CurrentUserCurrentHost 
    ) | ForEach-Object { 
        if (Test-Path $_) { 
            Write-Verbose "Reloading $_"
            . $_ 
        } 
    }
}

function Invoke-Reload-Path-Variable {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Invoke-Delete-Dot-Git-Folder {
    param($RepoPath = $PWD)
    
    $dotGitPath = "$RepoPath\.git"
    if (-not $(Test-Path "$dotGitPath")) {
        Write-Warning "The path '$RepoPath' does not appear to be a Git repository."
        return
    }

    $confirm = Read-Host "Are you sure you want to delete the Git folder at the path? `n $dotGitPath `n (y/n)"
    if ($confirm -ne 'y')
    {
        Write-Output 'Canceled operation'
        return 
    }

    $confirmation_text = Read-Host "Are you `absolutely` sure you want to delete the Git folder at the path? `n If so confirm by typing the following path exactly: `n $dotGitPath `n"
    if ($confirmation_text -ne $dotGitPath) {
        Write-Output 'Canceled operation because the typed path does not match'
        return 
    }

    # TODO maybe add one more check if the current branch has unpushed changes

    # Stop the git daemon for the git repository
    try {
        git -C "$RepoPath" fsmonitor--daemon stop
    } catch {
        Write-Warning "An error occurred, while trying to stop the git daemon"
        # Propagates the original error to the parent scope
        Write-Output $_
    }

    # # Unhide the files in the .git folder 
    # # Im not sure if this is needed so Im going to keep it commented but
    # # several people on stack overflow said you should unhide the files 
    # # in the .git directory
    # Get-ChildItem -Path "$dotGitPath" -Force | ForEach-Object { 
    #     $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::Hidden) 
    # }

    # Deletes ONLY the Git tracking data
    try {
        Remove-Item -Path "$RepoPath\.git" -Recurse -Force
        Write-Host "Git repository data removed successfully." -ForegroundColor Green
    } catch {
        Write-Warning "An error occurred, while trying delete the .git folder"
        # Propagates the original error to the parent scope
        Write-Output $_

        Write-Output "`n This may be due to a process keeping a file lock on a file in the .git folder."
        Write-Output "`n You can use the resource monitor to kill the process."
        Write-Output "`n In the CPU panel there is an `Associated Handles` section with a search bar."
        Write-Output "`n Type the filepath of the .git folder and click the search button."

        $ConfigPath = $Env:XDG_CONFIG_HOME
        if ($null -ne $ConfigPath -and $(Test-Path -Path "$ConfigPath" -PathType Any)) {
           Invoke-Item  "$ConfigPath\resmon\resmon.ResmonCfg"
        }
    }
}

function Invoke-LazyNvim () {
    $env:NVIM_APPNAME = "nvim-lazy";
    try {
        nvim $args
    } catch {
        Write-Warning "An error occurred, re-throwing..."
        # Propagates the original error to the parent scope
        throw $_
    } finally {
        # This block executes before the error stops the script
        $env:NVIM_APPNAME = $null
    }
}

# temporary until I rename it back to nvim-lazy
function Invoke-OldNvim () {
    $env:NVIM_APPNAME = "nvim-lazy.bak";
    try {
        nvim $args
    } catch {
        Write-Warning "An error occurred, re-throwing..."
        # Propagates the original error to the parent scope
        throw $_
    } finally {
        # This block executes before the error stops the script
        $env:NVIM_APPNAME = $null
    }
}

Set-Alias -Name zp -Value Invoke-FuzzyProjectLocation
Set-Alias -Name zc -Value Invoke-FuzzySetProofOfConceptLocation 
Set-Alias -Name lnvim -Value Invoke-LazyNvim
Set-Alias -Name onvim -Value Invoke-OldNvim
