$settings = Get-Content -Path '..\settings.json' | ConvertFrom-Json
$json = Invoke-RestMethod -Uri $settings.helpers.msEdge.uri

$version = $json | Where-Object { $_.product -eq 'stable' } | Select-Object -ExpandProperty releases | Select-Object | Where-Object { $_.platform -eq 'windows' -and $_.architecture -eq 'x64' } | Sort-Object -Property productversion -Descending | Select-Object -First 1 | Select-Object -ExpandProperty productversion
$urilocation = $json | Where-Object { $_.product -eq 'stable' } | Select-Object -ExpandProperty releases | Select-Object | Where-Object { $_.platform -eq 'windows' -and $_.architecture -eq 'x64' }`
| Sort-Object -Property productversion -Descending | Select-Object -First 1 | Select-Object -ExpandProperty artifacts | Select-Object -ExpandProperty location

$path = "$($(Get-Location).Path)\Microsoft Edge\v$version"
$filename = $urilocation | Split-Path -Leaf

New-Item -Path $path -ItemType Directory -Verbose | Out-Null
Start-BitsTransfer -Source $urilocation -Destination $path\$filename -TransferType Download -Verbose