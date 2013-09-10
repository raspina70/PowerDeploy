[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true, Position = 1)]
    [string]$project_file,
    
    [Parameter(Mandatory = $true, Position = 2)]
    [string]$package_id,
    
    [Parameter(Mandatory = $true, Position = 3)]
    [string]$config_prefix,

    [Parameter(Mandatory = $true, Position = 4)]
    [string]$version,
    
    [switch]$Build,
    [switch]$Package
)

$workDir = (Join-Path (Join-Path $env:TEMP PowerDeploy) ([guid]::NewGuid().ToString()))
$packageLocation = Join-Path $workDir "unzipped"

function DoBuild()
{
    Write-Verbose "Building $project_file"
    
    Write-Host $packageLocation
    exec { msbuild $project_file /p:Configuration=Release /p:RunCodeAnalysis=false /verbosity:minimal /p:AutoParameterizationWebConfigConnectionStrings=false /p:IncludeIisSettings=false /p:FilesToIncludeForPublish=OnlyFilesToRunTheApp /p:IncludeSetAclProviderOnDestination=false /p:DeployOnBuild=true /p:DeployTarget=Package /p:_PackageTempDir="$packageLocation" /t:Rebuild /t:Package }
}

function Package()
{
    AddPackageParameters 

    # msbuild extracts iis-content to $packageLocation, zip that into package.zip
    sz a -tzip "$workDir\package.zip" "$packageLocation/*" | Out-Null
    Remove-Item "$packageLocation" -Recurse -Force

    # zip neutral package
    sz a -tzip (Join-Path $powerdeploy.paths.project "deployment/deploymentUnits/$($package_id)_$version.zip") "$workDir/*" | Out-Null
    
    # remove temp folder
    Remove-Item $workDir -Recurse -Force
}

function AddPackageParameters()
{    
    $file = Join-Path $workDir "package.template.xml"
    
    $xml = New-Object System.Xml.XmlTextWriter($file, $null)
    $xml.Formatting = "Indented"
    $xml.Indentation = 4
    
    $xml.WriteStartDocument()
    $xml.WriteStartElement("package")
    $xml.WriteAttributeString("type", "iis")
    $xml.WriteAttributeString("id", $package_id)
    $xml.WriteAttributeString("version", $version)
    $xml.WriteAttributeString("environment", "`${env}`${subenv}")
    
    # pass to each individual impl:
    $xml.WriteElementString("appserver", "`${$($config_prefix)_AppServer_Name}")
    $xml.WriteElementString("username", "`${$($config_prefix)_AppServer_Account}")
    $xml.WriteElementString("password", "`${$($config_prefix)_AppServer_Password}")
    $xml.WriteElementString("apppoolname", "`${$($config_prefix)_AppServer_AppPoolName=$config_prefix (`$[env]`$[subenv])}") # todo: make defaultable
    $xml.WriteElementString("virtualdir", "`${$($config_prefix)_AppServer_Root=}/$package_id")
    $xml.WriteElementString("website", "`${$($config_prefix)_AppServer_WebSite}") # Default Web Site
    $xml.WriteEndElement()
    $xml.WriteEndDocument()
    
    $xml.Flush()
    $xml.Close()
}

if ($Build -eq $null -and $Package -eq $null) { Write-Host "wrong usage of this script. maybe you should have a look at the source code :)" }

if ($Build) { DoBuild }
if ($Package) { Package }
