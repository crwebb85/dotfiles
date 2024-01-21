# Run this script once to copy the profile.ps1 script to the folder that powershell expects it to be in 

$profile_dest = $PROFILE | Select -ExpandProperty CurrentUserAllHosts
$profile_src = "$Env:userprofile\Documents\.config\powershell\profile.ps1"
echo "Copying $profile_src to $profile_dest"
Copy-Item -Path $profile_src -Destination $profile_dest
