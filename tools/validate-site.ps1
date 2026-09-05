[CmdletBinding()]
param(
    [string]$GeneratedRoot,

    [ValidateSet('stable', 'local-test')]
    [string[]]$Channel = @('stable', 'local-test')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$installerRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if ([string]::IsNullOrWhiteSpace($GeneratedRoot)) {
    $GeneratedRoot = Join-Path $installerRoot 'generated'
}

function Resolve-ContainedFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath) -or $RelativePath -match '^[a-zA-Z][a-zA-Z0-9+.-]*:') {
        throw "只允許 generated channel 內的相對路徑：$RelativePath"
    }

    $rootPath = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $candidatePath = [IO.Path]::GetFullPath((Join-Path $rootPath $RelativePath))
    $rootPrefix = $rootPath + [IO.Path]::DirectorySeparatorChar
    if (-not $candidatePath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "generated channel path 跨出允許目錄：$RelativePath"
    }

    return $candidatePath
}

function Read-JsonFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "找不到必要檔案：$Path"
    }

    try {
        return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
    } catch {
        throw "JSON 無法解析：$Path`n$($_.Exception.Message)"
    }
}

if (-not (Test-Path -LiteralPath $GeneratedRoot -PathType Container)) {
    throw "找不到 generated output：$GeneratedRoot"
}

foreach ($channelName in $Channel) {
    $channelRoot = Join-Path $GeneratedRoot $channelName
    if (-not (Test-Path -LiteralPath $channelRoot -PathType Container)) {
        throw "找不到 channel output：$channelRoot"
    }

    $metadataPath = Join-Path $channelRoot 'metadata.json'
    $metadata = Read-JsonFile $metadataPath
    if ($metadata.schemaVersion -ne 1 -or $metadata.channel -ne $channelName) {
        throw "metadata schema/channel 不符合預期：$metadataPath"
    }
    if ([string]::IsNullOrWhiteSpace([string]$metadata.version)) {
        throw "metadata 缺少 firmware version：$metadataPath"
    }
    if ([string]::IsNullOrWhiteSpace([string]$metadata.manifest) -or
        [string]::IsNullOrWhiteSpace([string]$metadata.artifact) -or
        [string]::IsNullOrWhiteSpace([string]$metadata.sha256)) {
        throw "metadata 缺少 manifest、artifact 或 sha256：$metadataPath"
    }

    $manifestPath = Resolve-ContainedFile $channelRoot ([string]$metadata.manifest)
    $manifest = Read-JsonFile $manifestPath
    if ($manifest.version -ne $metadata.version) {
        throw "metadata 與 manifest version 不一致：$channelName"
    }
    if ($null -eq $manifest.builds -or $manifest.builds.Count -lt 1 -or
        $null -eq $manifest.builds[0].parts -or $manifest.builds[0].parts.Count -lt 1) {
        throw "manifest 沒有 firmware part：$manifestPath"
    }

    $manifestArtifact = [string]$manifest.builds[0].parts[0].path
    if ($manifestArtifact -ne [string]$metadata.artifact) {
        throw "metadata 與 manifest artifact 不一致：$channelName"
    }
    $artifactPath = Resolve-ContainedFile $channelRoot ([string]$metadata.artifact)
    if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf)) {
        throw "找不到 factory image：$artifactPath"
    }

    $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $artifactPath).Hash.ToLowerInvariant()
    if ($actualHash -ne ([string]$metadata.sha256).ToLowerInvariant()) {
        throw "metadata SHA256 不符合 factory image：$channelName"
    }

    $checksumsPath = Join-Path $channelRoot 'SHA256SUMS.txt'
    if (-not (Test-Path -LiteralPath $checksumsPath -PathType Leaf)) {
        throw "找不到 checksum file：$checksumsPath"
    }
    $checksumLine = (Get-Content -LiteralPath $checksumsPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1)
    if ($checksumLine -notmatch '^\s*([0-9a-fA-F]{64})\s+(.+?)\s*$') {
        throw "checksum file 格式錯誤：$checksumsPath"
    }
    if ($Matches[1].ToLowerInvariant() -ne $actualHash -or
        [IO.Path]::GetFileName($Matches[2].Trim()) -ne [IO.Path]::GetFileName($artifactPath)) {
        throw "checksum file 與 factory image 不一致：$channelName"
    }

    Write-Host "VALID $channelName version=$($metadata.version) artifact=$($metadata.artifact) sha256=$actualHash"
}
