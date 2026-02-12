function Invoke-SetupJupytextVenv {
    param ()

    Write-Host "Setting up Jupytext python virtual environment"

    if ($PSScriptRoot -eq $null)
    {
        Write-Error "PSScriptRoot path was null"
        return
    }

    if (Get-Command -Name "py" -ErrorAction SilentlyContinue) {
        Write-Host "The executable 'py' is available in the PATH."
    } else {
        Write-Error "The executable 'py' is NOT available in the PATH."
        return
    }

    $venvPath = "$PSScriptRoot\venv"

    if (Test-Path -Path $venvPath) {
        Write-Host "venv directory already exists."
    } else {
        Write-Host "Creating venv directory"
        py -m venv $venvPath
    }

    $activatePath = "$venvPath\Scripts\Activate.ps1"
    if (Test-Path -Path $venvPath) {
        Write-Host "Activating python virtual environment"
        . $venvPath\Scripts\Activate.ps1
    } else {
        Write-Error "Could not find $activatePath"
        return
    }

    $requirementsPath = "$PSScriptRoot\requirements.txt"
    pip install -r $requirementsPath

    deactivate

    Write-Host "Finished setting up venv"
}

Invoke-SetupJupytextVenv
