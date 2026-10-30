@echo off
setlocal DisableDelayedExpansion
rem Default folder. You may change this line, or pass a folder as argument 1.
set "SG_DEST=%~dp0Downloads"
if not "%~1"=="" set "SG_DEST=%~1"
set "SG_BAT_PATH=%~f0"
rem Paths are passed through environment variables, never inserted into PS code.
powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$text=[IO.File]::ReadAllText($env:SG_BAT_PATH); $parts=$text -split '(?m)^# POWERSHELL_PAYLOAD\r?$',2; & ([ScriptBlock]::Create($parts[1]))"
set "SG_RESULT=%ERRORLEVEL%"
if /i not "%~2"=="/nopause" pause
exit /b %SG_RESULT%
# POWERSHELL_PAYLOAD
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$pending = $null
try {
    $folder = [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($env:SG_DEST))
    [void][IO.Directory]::CreateDirectory($folder)
    $target = [IO.Path]::Combine($folder, 'ScrapGarden-Windows.zip')
    $pending = [IO.Path]::Combine($folder, 'ScrapGarden-' + [Guid]::NewGuid().ToString('N') + '.pending')
    $headers = @{ 'User-Agent' = 'ScrapGarden-Windows-Downloader'; 'Cache-Control' = 'no-cache' }
    $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/hazro/ScrapGarden-Releases/releases/latest' -Headers $headers -TimeoutSec 60
    $asset = @($release.assets | Where-Object { $_.name -eq 'ScrapGarden-Windows.zip' -and $_.state -eq 'uploaded' })
    if ($asset.Count -ne 1 -or $asset[0].digest -notmatch '^sha256:[0-9a-fA-F]{64}$') {
        throw 'The latest ZIP metadata is unavailable. The existing ZIP was not changed.'
    }
    Write-Host ('Downloading SCRAP GARDEN ' + $release.tag_name + ' ...')
    Write-Host ('Folder: ' + $folder)
    # Stream through literal .NET paths: Windows PowerShell 5.1 OutFile treats [] as wildcards.
    $request = [Net.WebRequest]::Create('https://github.com/hazro/ScrapGarden-Releases/releases/latest/download/ScrapGarden-Windows.zip')
    $request.UserAgent = 'ScrapGarden-Windows-Downloader'
    $request.Headers['Cache-Control'] = 'no-cache'
    $request.AllowAutoRedirect = $true
    $request.MaximumAutomaticRedirections = 10
    $request.Timeout = 300000
    $request.ReadWriteTimeout = 300000
    $response = $null; $inputStream = $null; $outputStream = $null
    try {
        $response = $request.GetResponse()
        $inputStream = $response.GetResponseStream()
        $outputStream = [IO.File]::Open($pending, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $inputStream.CopyTo($outputStream)
    } finally {
        if ($outputStream) { $outputStream.Dispose() }
        if ($inputStream) { $inputStream.Dispose() }
        if ($response) { $response.Dispose() }
    }
    # Use .NET hashing so no extra PowerShell module is required.
    $fileStream = [IO.File]::OpenRead($pending)
    $hasher = [Security.Cryptography.SHA256]::Create()
    try {
        if ($fileStream.Length -ne [long]$asset[0].size) {
            throw 'The downloaded file size does not match. The existing ZIP was not changed.'
        }
        $actualHash = [BitConverter]::ToString($hasher.ComputeHash($fileStream)).Replace('-', '').ToLowerInvariant()
    } finally {
        $fileStream.Dispose()
        $hasher.Dispose()
    }
    if ($actualHash -ne $asset[0].digest.Substring(7).ToLowerInvariant()) {
        throw 'The SHA256 check failed. The existing ZIP was not changed; please run again.'
    }
    if ([IO.File]::Exists($target)) {
        [IO.File]::Replace($pending, $target, $null)
    } else {
        [IO.File]::Move($pending, $target)
    }
    $pending = $null
    Write-Host ('Saved: ' + $target)
    Write-Host ('SHA256 verified: ' + $actualHash)
    Write-Host 'Complete. Extract the ZIP before starting the game.'
    exit 0
} catch {
    if ($pending -and [IO.File]::Exists($pending)) {
        [IO.File]::Delete($pending)
    }
    [Console]::Error.WriteLine('Download failed: ' + $_.Exception.Message)
    exit 1
}
