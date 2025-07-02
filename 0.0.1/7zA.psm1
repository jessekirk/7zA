$i = Get-Module -ListAvailable -Refresh 7zA
$json = Get-Content -Path (Join-Path -Path $i.ModuleBase -ChildPath settings.json) | ConvertFrom-Json

function dateTimeUtc { return (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmZ') }
function getLatestMsEdge { & $(Join-Path -Path $i.ModuleBase -ChildPath $json.helpers.msEdge.script -Resolve) }
function getLatestCurl { & $(Join-Path -Path $i.ModuleBase -ChildPath $json.helpers.curl.script -Resolve) }
function getLatestNotepadPlusPlus { & $(Join-Path -Path $i.ModuleBase -ChildPath $json.helpers.notepadPlusPlus.script -Resolve) }

$script:datetimeutc = dateTimeUtc

function returnTotalBuildTime
{
    $endtime = [datetime]::Now ; $t = $endtime - $starttime
    Write-Host -Object '' ; Write-Host -Object "Build minutes: $($t.TotalMinutes)" -ForegroundColor Cyan ; Write-Host -Object "Build seconds: $($t.TotalSeconds)" -ForegroundColor Cyan ; Write-Host ''
}

function rename7zReleasableToSamsVersion { Get-ChildItem -Path $fullyqualifieddestinationpath | Where-Object { $_.Name -eq 'Release' } | Rename-Item -NewName $($fullyqualifieddestinationpath | Split-Path -Leaf) -Force -Verbose ; returnTotalBuildTime }

function remove7zPackageUpdatesAfterReleasble
{
    $path = Get-ChildItem -Path $fullyqualifieddestinationpath -Recurse | Where-Object { $_.Name -ne 'Release' }
    if ($noremove -eq $true) { $path | ForEach-Object { Write-Host -Object "Keeping file/folder '$_' after 'Release/' is built." -ForegroundColor Green } ; rename7zReleasableToSamsVersion ; return }
    Get-ChildItem -Path $fullyqualifieddestinationpath | Where-Object { $_.Name -ne 'Release' } | Remove-Item -Recurse -Force -Verbose ; rename7zReleasableToSamsVersion
}

function begin256HashingOf7zPackage
{
    $array = @()
    (Get-ChildItem -Path $fullyqualifieddestinationpath -Recurse -File).FullName | ForEach-Object {
        Write-Verbose -Message "Hashing $_ " -Verbose ; $i = Get-FileHash -Path $_ -Algorithm SHA256
        $h = [pscustomobject]@{ name = $i.Path | Split-Path -Leaf ; hash = $i.Hash.ToLower() ; algorithm = $i.algorithm }
        $array += $h
    }

    $logfilepath = (Get-ChildItem -Path $fullyqualifieddestinationpath -Recurse -File -Filter '*.7z').FullName.Replace('.7z', '_Sha256_values.txt') ; $array | Format-List | Out-File -FilePath $logfilepath
    Get-ChildItem -Path "$fullyqualifieddestinationpath\Release" -Recurse -Force | Unblock-File -Verbose ; remove7zPackageUpdatesAfterReleasble
}

function build7zReleasable
{
    $fullyqualifieddestinationpath = $fullyqualifieddestinationpath | Split-Path -Parent ; $fullyqualifieddestinationpath = $fullyqualifieddestinationpath += '\'

    New-Item -Path $fullyqualifieddestinationpath -Name 'Release\bin' -ItemType Directory -Force -Verbose | Out-Null
    Move-Item -Path $(Join-Path -Path $fullyqualifieddestinationpath -ChildPath '*.7z') -Destination $(Join-Path -Path $fullyqualifieddestinationpath -ChildPath 'Release') -Verbose
    Join-Path -Path $i.ModuleBase -ChildPath $json.includes -Resolve | Copy-Item -Destination $(Join-Path -Path $fullyqualifieddestinationpath -ChildPath 'Release\bin') -Container -Verbose
    (Get-ChildItem -Path "$path\monthly updates" -Recurse | Where-Object { $_.Name -match 'monthly_updates.cmd' }).FullName | Copy-Item -Destination $(Join-Path -Path $fullyqualifieddestinationpath -ChildPath 'Release') -Container -Verbose
    begin256HashingOf7zPackage
}

function build7zPackage
{
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory)][string]$sourcePath,
        [parameter()][switch]$noRemove7zPackageUpdatesAfterReleasble
    )

    $script:starttime = [datetime]::Now

    if ($noRemove7zPackageUpdatesAfterReleasble.IsPresent) { $script:noremove = $true } else { $noremove = $false }
    if (-not(Test-Path -Path $sourcePath -ErrorAction SilentlyContinue)) { throw "The source path $sourcePath does not exist." }
    if (-not($sourcePath.EndsWith('\'))) { $sourcePath += '\' }

    $script:path = (Resolve-Path -Path $json.repo -ErrorAction SilentlyContinue).Path ; if ($null -ne $path) { if (-not(Test-Path -Path "$path\.git")) { throw 'This requires a Git repository. Verify path to only 1 valid repo.' } }
    (Get-ChildItem -Path "$path\monthly updates" -Recurse | Where-Object { $_.Name -match 'monthly_updates.ps1' }).FullName | Copy-Item -Destination $sourcePath -Container -Verbose

    $destinationpath = ($sourcePath | Split-Path -Leaf) + '_' + $datetimeutc + '.7z'
    $script:fullyqualifieddestinationpath = $sourcePath + $destinationpath

    $files = Get-ChildItem -Path $sourcePath -Recurse ; $files | Unblock-File -Verbose ; $files | ForEach-Object { Write-Verbose -Message "Adding $_ to $destinationpath" -Verbose }
    & (Join-Path -Path $i.ModuleBase -ChildPath $json.sevenZ -Resolve) $json.args $fullyqualifieddestinationpath $sourcePath ; build7zReleasable
}