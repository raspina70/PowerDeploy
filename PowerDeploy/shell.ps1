Push-Location (Split-Path -parent "$($MyInvocation.MyCommand.path)")

# ===========================================================================================================
# global update functionsfunctions

function Invoke-UpdateFromTFS
{
	$location = Get-Location

	$workspace_name = "PowerDeploy"

	$xml = [xml](Get-Content "shell.settings")

	$local_dir = $xml.config.PowerDeployInstallDir
	$remote_dir = $xml.config.update.source
	$tfs_server = $xml.config.update.server

	if ((Test-Path "$local_dir") -eq $false)
	{
		Write-Host "No PowerDeploy installation found. I'll install it for you to $local_dir"
		New-Item -ItemType directory -Path "$local_dir"
		Push-Location "$local_dir"

		tf workfold /unmap "$local_dir" | Out-Null
		tf workspace /new /server:$tfs_server /noprompt $workspace_name
		tf workfold "$remote_dir" "$local_dir" /workspace:$workspace_name

		Pop-Location
	}

	Push-Location $local_dir

	tf get $local_dir /recursive /overwrite /noprompt

	Pop-Location $location
}

function Invoke-UpdateFromGIT
{
	$xml = [xml](Get-Content "shell.settings")

	if((Test-Path $xml.config.PowerDeployInstallDir) -eq $false)
	{
		New-Item -Path "$($xml.config.PowerDeployInstallDir)" -ItemType directory | Out-Null
		Write-Host "No PowerDeploy installation found. I'll install it for you to $($xml.config.PowerDeployInstallDir)"
		git clone $xml.config.update.repository "$($xml.config.PowerDeployInstallDir)"
	}
	else
	{
		Write-Host "Updating PowerDeploy from git repository"

		Push-Location "$xml.config.PowerDeployInstallDir"
		git pull
		Pop-Location
	}
}
# ===========================================================================================================


# Load vs-tools, update, load and initialize powerdeploy

Remove-Module "PowerDeploy" -ErrorAction Continue


$xml = [xml](Get-Content "shell.settings")

. (Join-Path "$($xml.config.PowerDeployInstallDir)" "scripts/vsvars.ps1")

$vs_dir = Resolve-Path (Join-Path (Get-Item env:VS$($xml.config.vstoolsversion.Replace('.', ''))COMNTOOLS).Value '..\IDE')

$env:path += ";$vs_dir"


# update poweredeploy & set an "update" alias which allows to update powerdeploy & environments
if ($xml.config.update.mechanism.ToUpper() -eq 'TFS')
{
	Invoke-UpdateFromTFS
	Set-Alias update Invoke-UpdateFromTFS -Scope Global
}
elseif ($xml.config.update.mechanism.ToUpper() -eq 'GIT')
{
	Invoke-UpdateFromGIT
	Set-Alias update Invoke-UpdateFromGIT -Scope Global
}
# end update

Import-Module (Join-Path "$($xml.config.PowerDeployInstallDir)" "PowerDeploy.psm1") -DisableNameChecking

$config = @{
	ProjectDir = Resolve-Path "$($xml.config.ProjectDir)";
	PowerDeployInstallDir = Resolve-Path "$($xml.config.PowerDeployInstallDir)";
	update = $xml.config.update
}

$powerdeploy.config = $config


Write-Host "__________                         ________                .__                "
Write-Host "\______   \______  _  __ __________\______ \   ____ ______ |  |   ____ ___.__."
Write-Host " |     ___/  _ \ \/ \/ // __ \_  __ \    |  \_/ __ \\____ \|  |  /  _ <   |  |"
Write-Host " |    |  (  <_> )     /\  ___/|  | \/    `   \  ___/|  |_> >  |_(  <_> )___  |"
Write-Host " |____|   \____/ \/\_/  \___  >__| /_______  /\___  >   __/|____/\____// ____|"
Write-Host "                            \/             \/     \/|__|               \/     "
Write-Host "                                                             by tobias zürcher"
Write-Host ""

Show-PowerDeployHelp

Write-Host ""

#TODO: maybe show available packages/environments

Initialize-PowerDeploy "$($powerdeploy.config.ProjectDir)"

$Host.UI.RawUI.WindowTitle = "PowerDeploy for project " + $powerdeploy.project.id + " in $($powerdeploy.config.ProjectDir)"

# create some nice aliases
Set-Alias Build Invoke-Build -Scope Global -Force
Set-Alias b Invoke-Build -Scope Global -Force

Set-Alias Prepare Prepare-DeploymentUnit -Scope Global -Force
Set-Alias p Prepare-DeploymentUnit -Scope Global -Force

Set-Alias Configure Configure-Environment -Scope Global -Force
Set-Alias Config Configure-Environment -Scope Global -Force
Set-Alias c Configure-Environment -Scope Global -Force

Set-Alias Deploy Invoke-Deploy -Scope Global -Force
Set-Alias d Invoke-Deploy -Scope Global -Force

Set-Alias op Open-ProjectDir -Scope Global -Force

Set-Alias Help Show-PowerDeployHelp -Scope Global -Force