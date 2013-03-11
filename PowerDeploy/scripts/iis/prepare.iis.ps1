[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true, Position = 1)]
    [string]$work_dir,
    
    [switch]$Disassemble,
    [switch]$Reassemble
)

# unpack the created iis package.zip that Configure-Environment can apply
# the template variables to the according files
function Disassemble()
{   
    $out = Join-Path $work_dir "out/"
    
    sz x -y "-o$($out)" (Join-Path $work_dir package.zip) | Out-Null

    Move-Item (Join-Path $out "parameters.xml") (Join-Path $out "parameters.template.xml")
}

function Reassemble()
{
    sz a -tzip (Join-Path $work_dir package.zip) (Join-Path $work_dir "out/*") | Out-Null
    
    Remove-Item (Join-Path $work_dir "out") -Recurse
}

if ($Disassemble -eq $false -and $Reassemble -eq $false) { "maybe u should have a look at the source code :)" }

if ($Disassemble) { Disassemble }
if ($Reassemble) { Reassemble }