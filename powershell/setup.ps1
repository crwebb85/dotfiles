# Run this script once to copy the profile.ps1 script to the folder that powershell expects it to be in 

$profile_dest = $PROFILE | Select -ExpandProperty CurrentUserAllHosts
$profile_src = "$Env:XDG_CONFIG_HOME\powershell\profile.ps1"
echo "Creating profile directory if it does not exist"
$profile_dest_parent = Split-Path -parent $profile_dest
New-Item -ItemType Directory -Force -Path $profile_dest_parent
echo "Copying $profile_src to $profile_dest"
Copy-Item -Path $profile_src -Destination $profile_dest
