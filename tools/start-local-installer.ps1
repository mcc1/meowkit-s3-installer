[CmdletBinding()]
param(
    [ValidateRange(1, 65535)]
    [int]$Port = 8000,

    [switch]$NoBrowser
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$installerRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$pythonCommand = Get-Command python.exe -ErrorAction SilentlyContinue
if ($null -eq $pythonCommand) {
    $pythonCommand = Get-Command py.exe -ErrorAction SilentlyContinue
}
if ($null -eq $pythonCommand) {
    throw '找不到 Python。請先安裝 Python，或直接使用其他本地 HTTP server。'
}

$pythonArguments = @()
if ($pythonCommand.Name -eq 'py.exe') {
    $pythonArguments += '-3'
}

$existingListener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($null -ne $existingListener) {
    throw "Port $Port 已被其他程式使用。請改用 -Port 8080，或先停止原本的 server。"
}

$serverArguments = $pythonArguments + @('-m', 'http.server', $Port, '--bind', '127.0.0.1')
$server = $null
$startParameters = @{
    FilePath         = $pythonCommand.Source
    ArgumentList     = $serverArguments
    WorkingDirectory = $installerRoot
    WindowStyle      = 'Hidden'
    PassThru          = $true
}
$server = Start-Process @startParameters

$url = "http://localhost:$Port/index.html"
try {
    $ready = $false
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        if ($server.HasExited) {
            throw "local HTTP server 提前結束，exit code $($server.ExitCode)"
        }
        try {
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 2
            if ($response.StatusCode -eq 200) {
                $ready = $true
                break
            }
        } catch {
            Start-Sleep -Milliseconds 250
        }
    }

    if (-not $ready) {
        throw "local HTTP server 未能在預期時間內啟動：$url"
    }

    Write-Host "Local installer: $url"
    Write-Host '請使用 desktop Chrome 或 Edge；按 Ctrl+C 結束 server。'
    if (-not $NoBrowser) {
        Start-Process $url | Out-Null
    }

    while ($true) {
        if ($server.HasExited) {
            throw "local HTTP server 已結束，exit code $($server.ExitCode)"
        }
        Start-Sleep -Seconds 1
    }
} finally {
    if ($null -ne $server -and -not $server.HasExited) {
        Stop-Process -Id $server.Id -Force
    }
}
