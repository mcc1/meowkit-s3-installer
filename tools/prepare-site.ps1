[CmdletBinding()]
param(
    [string]$GeneratedRoot,

    [string]$SiteRoot,

    [ValidateSet('stable', 'local-test')]
    [string[]]$Channel = @('stable', 'local-test'),

    [switch]$Clean
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$installerRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if ([string]::IsNullOrWhiteSpace($GeneratedRoot)) {
    $GeneratedRoot = Join-Path $installerRoot 'generated'
}
if ([string]::IsNullOrWhiteSpace($SiteRoot)) {
    $SiteRoot = Join-Path $installerRoot 'site'
}

& (Join-Path $PSScriptRoot 'validate-site.ps1') -GeneratedRoot $GeneratedRoot -Channel $Channel

$sitePath = [IO.Path]::GetFullPath($SiteRoot)
if ($Clean) {
    if ($sitePath.Length -lt 5 -or $sitePath -eq [IO.Path]::GetPathRoot($sitePath)) {
        throw "拒絕清理不安全的 site path：$sitePath"
    }
    if (Test-Path -LiteralPath $sitePath -PathType Container) {
        Get-ChildItem -LiteralPath $sitePath -Force | Remove-Item -Recurse -Force
    }
}

New-Item -ItemType Directory -Path $sitePath -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $installerRoot 'index.html') -Destination (Join-Path $sitePath 'index.html') -Force

$noJekyllPath = Join-Path $installerRoot '.nojekyll'
if (Test-Path -LiteralPath $noJekyllPath -PathType Leaf) {
    Copy-Item -LiteralPath $noJekyllPath -Destination (Join-Path $sitePath '.nojekyll') -Force
}

$siteGenerated = Join-Path $sitePath 'generated'
New-Item -ItemType Directory -Path $siteGenerated -Force | Out-Null
Get-ChildItem -LiteralPath $GeneratedRoot -Force | Copy-Item -Destination $siteGenerated -Recurse -Force

Write-Host "Prepared installer site: $sitePath"
Write-Host "Channels: $($Channel -join ', ')"
