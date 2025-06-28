$i = Get-Module -ListAvailable -Refresh 7zA
$json = Get-Content -Path (Join-Path -Path $i.ModuleBase -ChildPath settings.json) | ConvertFrom-Json
function datetimeutc { return (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmZ') }

function sha256hashpackage
{
    $array = @()
    (Get-ChildItem -Path $fullyqualifieddestinationpath -Recurse -File).FullName | ForEach-Object {
        Write-Verbose -Message "Hashing $_ " -Verbose ; $i = Get-FileHash -Path $_ -Algorithm SHA256
        $h = [pscustomobject]@{ name = $i.Path | Split-Path -Leaf ; hash = $i.Hash.ToLower() ; algorithm = $i.algorithm }
        $array += $h
    }

    $logfilepath = (Get-ChildItem -Path $fullyqualifieddestinationpath -Recurse -File -Filter '*.7z').FullName.Replace('.7z', '_Sha256_values.txt') ; $array | Format-List | Out-File -FilePath $logfilepath
}

function buildreleasable
{
    $fullyqualifieddestinationpath = $fullyqualifieddestinationpath | Split-Path -Parent ; $fullyqualifieddestinationpath = $fullyqualifieddestinationpath += '\'

    New-Item -Path $fullyqualifieddestinationpath -Name 'Release\bin' -ItemType Directory -Force -Verbose | Out-Null
    Move-Item -Path $(Join-Path -Path $fullyqualifieddestinationpath -ChildPath '*.7z') -Destination $(Join-Path -Path $fullyqualifieddestinationpath -ChildPath 'Release') -Verbose
    (Join-Path -Path $i.ModuleBase -ChildPath $json.includes -Resolve) | Copy-Item -Destination $(Join-Path -Path $fullyqualifieddestinationpath -ChildPath 'Release\bin') -Container -Verbose
    sha256hashpackage
}

function build7zpackage
{
    [cmdletbinding()]
    param([parameter(Mandatory)][string]$sourcepath)

    if (-not(Test-Path -Path $sourcepath -ErrorAction SilentlyContinue)) { throw "The source path $sourcepath does not exist." }
    if (-not($sourcepath.EndsWith('\'))) { $sourcepath += '\' }

    $datetimeutc = datetimeutc
    $destinationpath = ($sourcepath | Split-Path -Leaf) + '_' + $datetimeutc + '.7z'
    $script:fullyqualifieddestinationpath = $sourcepath + $destinationpath

    $files = Get-ChildItem -Path $sourcepath -Recurse ; $files | ForEach-Object { Write-Verbose -Message "Adding $_ to $destinationpath" -Verbose }
    & (Join-Path -Path $i.ModuleBase -ChildPath $json.sevenZ -Resolve) $json.args $fullyqualifieddestinationpath $sourcepath ; buildreleasable
}