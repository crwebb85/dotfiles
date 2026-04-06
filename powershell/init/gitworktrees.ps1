param(
    [string]$branch
)

# make sure script stops if an error occurs
$PSNativeCommandUseErrorActionPreference = $true
$ErrorActionPreference = "Stop"


#validate input
if ($branch -isnot [string])
{
    throw "Invalid argument: branch must be a string"
}

if ([string]::IsNullOrWhiteSpace($branch))
{
    throw "Invalid argument: branch must not be null or whitespace here"
}

#find git directory
$gitDir = (git rev-parse --show-toplevel).Trim()

#sanity checks
if ($gitDir -isnot [string])
{
    throw "wth repo directory should be a string here"
}
if ([string]::IsNullOrWhiteSpace($gitDir))
{
    throw "wth repo directory should not be null or whitespace here"
}
if (-not (Test-Path -Path $gitDir -PathType Container))
{
    throw "wth repo directory should exist here"
}

# determine new worktree path to create
$newWorktreePath = Join-Path "$gitDir" ".gitworktrees" "$branch"

#create worktree
# TODO do something smarter so that I don't need to already have an existing remote branch
git worktree add "$newWorktreePath" "origin/$branch"

$sourceRelativePaths = rg --files `
    --hidden `
    --ignore-vcs `
    --glob "!.gitworktrees" `
    --glob "appsettings.*.json"

Write-Output "Will copy the following files $gitDir to $newWorktreePath"
Write-Output $sourceRelativePaths

$choice = ""
while ($choice -notmatch "[yYnN]")
{
    $choice = Read-Host "Do you want to continue? (Y/N)"
}

if ($choice -match "[yY]")
{
    Write-Host "Continuing with the operation..."
} else
{
    Write-Host "Skipped copying files."
    return
}

foreach ($sourceRelativePath in $sourceRelativePaths)
{
    $sourceFile = Join-Path "$gitDir" "$sourceRelativePath"
    $destinationFile = Join-Path "$newWorktreePath" "$sourceRelativePath"

    if (Test-Path $sourceFile)
    {
        #Ensure the destination directory exists
        $destinationSubDir = Split-Path $destinationFile -Parent
        if (-not (Test-Path $destinationSubDir))
        {
            Write-Output "Created folder $destinationSubDir"
            New-Item -Path $destinationSubDir -ItemType Directory -Force
        }

        Copy-Item -Path $sourceFile -Destination $destinationFile -Force
        Write-Host "Copied: $sourceRelativePAth"
    }
}
