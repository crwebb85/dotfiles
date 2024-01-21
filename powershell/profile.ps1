# Run the setup.ps1 script once to copy this profile.ps1 script to the folder that powershell expects it to be in
# Once in the correct path this file will source my powershell configuration when powershell starts.
echo "Sourcing my profile"
. "$Env:userprofile\Documents\.config\powershell\init.ps1"
echo "Finished sourcing my profile"
