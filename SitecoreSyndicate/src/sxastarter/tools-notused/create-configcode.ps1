# Description: 
# Creates a script ..\generated\App_Config.script.ps1 that will create the 
# c:\inetpub\wwwroot\App_Config\Include\zzz_all.config file from the source file
# src\platform\App_Config\Include\zzz\zzz_all.config. 
# Author: Serge van den Oever [Macaw]
# Version: 1.0

$VerbosePreference="SilentlyContinue" # change to Continue to see verbose output
$DebugPreference="SilentlyContinue" # change to Continue to see debug output
$ErrorActionPreference="Stop"

. "$PSScriptRoot\Test-Xml.ps1"

$rootDirectory = Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\src\platform\App_Config")
$destinationDirectory = 'c:\inetpub\wwwroot\App_Config'
$lines = ''

# Create directories
$lines += "New-Item -ItemType Directory -Force -Path '$destinationDirectory\Include\zzz' | Out-Null`n"
$lines += "Write-Host 'Created directory $destinationDirectory\Include\zzz'`n"
$sourceFilePath = "$rootDirectory\Include\zzz\zzz_all.config"
if (-not (Test-Path -Path $sourceFilePath)) {
    Write-Error "File $sourceFilePath does not exist"
}
$xmlValidationResults = Test-Xml -Path $sourceFilePath
if (-not $xmlValidationResults.ValidXmlFile) {
    Write-Error "Invalid XML file $($sourceFilePath): $($xmlValidationResults.Error)"
}
$destinationFilePath = "$destinationDirectory\Include\zzz\zzz_all.config"
Write-Host "Processing file $sourceFilePath"
$content = Get-Content -Path $sourceFilePath
$bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
$encoded = [System.Convert]::ToBase64String($bytes)
$lines += "Write-Host 'Create file $destinationFilePath'`n"
$lines += "Write-Host 'After file creation the application pool is recycled'`n"
$lines += "Set-Content -Path $destinationFilePath -Value ([System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String(`"$encoded`")))`n"

$generatedFolder = Join-Path -Path $PSScriptRoot -ChildPath "..\generated"
New-Item -ItemType Directory -Force -Path $generatedFolder | Out-Null
Write-Host "Generate script to $generatedFolder\App_Config.script.ps1"
Set-Content -Path "$generatedFolder\App_Config.script.ps1" -Value $lines
Write-Host "Done."