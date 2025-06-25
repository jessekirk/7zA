$scripts = Get-ChildItem -Path . -Recurse -File -Exclude '*apply_monthly_updates*', '*branding*' -Filter *.ps1
$scripts | ForEach-Object { Start-Process -FilePath 'powershell.exe' -ArgumentList "-file `"$($_.Name)`"" -WorkingDirectory "$($_.Directory)" -NoNewWindow -Wait }

$scripts = Get-ChildItem -Path . -Recurse -File -Include '*branding*' -Filter *.ps1
$scripts | ForEach-Object { Start-Process -FilePath 'powershell.exe' -ArgumentList "-file `"$($_.Name)`"" -WorkingDirectory "$($_.Directory)" -NoNewWindow -Wait }