
function datetimeutc { return (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmZ') }

<#

7za.exe path /Dependencies/Build/7z/x64/7za.exe

Copy /Dependencies/Includes/*.* to the folder after 7.z package is built

& 7za.exe a -mx9 -mmt3 -md=2048m -m0=lzma2:fb64 -ms=16384m -bt "C:\Users\jesse.kirk\Desktop\Pack\SAMS-C2-v7.0.4_20250624T1316Z.7z" "C:\Users\jesse.kirk\Desktop\Pack\SAMS-C2-v7.0.4_20250624T1316Z\"

#>