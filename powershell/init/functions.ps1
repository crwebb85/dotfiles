
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

