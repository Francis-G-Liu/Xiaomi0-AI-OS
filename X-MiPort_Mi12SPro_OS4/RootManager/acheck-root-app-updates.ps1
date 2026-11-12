<#
Checks the latest stable GitHub release APKs for the Root apps in this folder.
Run from PowerShell: .\check-root-app-updates.ps1
#>
[CmdletBinding()]
param(
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$proxy = 'http://127.0.0.1:7897'

$apps = @(
    [pscustomobject]@{ Name='APatch'; Repo='bmax121/APatch'; LocalPattern='APatch_*.apk'; AssetPattern='^APatch_.*\.apk$'; KeyPattern='^APatch_(\d+)_([0-9a-f]+)' }
    [pscustomobject]@{ Name='FolkPatch'; Repo='LyraVoid/FolkPatch'; LocalPattern='FolkPatch_*.apk'; AssetPattern='^FolkPatch_.*\.apk$'; KeyPattern='^FolkPatch_(\d+)_([0-9a-f]+)' }
    [pscustomobject]@{ Name='KernelSU'; Repo='tiann/KernelSU'; LocalPattern='KernelSU_v*.apk'; AssetPattern='^KernelSU_v[^_]+_.*\.apk$'; KeyPattern='^KernelSU_v([0-9][0-9A-Za-z.+-]*)_(\d+)' }
    [pscustomobject]@{ Name='KernelSU-Next'; Repo='KernelSU-Next/KernelSU-Next'; LocalPattern='KernelSU_Next_*.apk'; AssetPattern='^KernelSU_Next_.*\.apk$'; KeyPattern='^KernelSU_Next_v([0-9][0-9A-Za-z.+-]*)_(\d+)' }
    [pscustomobject]@{ Name='Magisk'; Repo='topjohnwu/Magisk'; LocalPattern='Magisk-v*.apk'; AssetPattern='^Magisk-v.*\.apk$'; KeyPattern='^Magisk-v([0-9][0-9A-Za-z.+-]*?)(?:\((\d+)\))?\.apk$' }
    [pscustomobject]@{ Name='SukiSU-Ultra'; Repo='SukiSU-Ultra/SukiSU-Ultra'; LocalPattern='SukiSU_*.apk'; AssetPattern='^SukiSU_.*\.apk$'; KeyPattern='^SukiSU_v([0-9][0-9A-Za-z.+-]*)_(\d+)' }
)

function Get-VersionKey([string]$FileName, [string]$Pattern) {
    $match = [regex]::Match($FileName, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (-not $match.Success) { return $null }
    return (($match.Groups | Select-Object -Skip 1 | ForEach-Object { $_.Value }) -join '|').ToLowerInvariant()
}

function Select-ReleaseApk($App, $Release) {
    $assets = @($Release.assets | Where-Object {
        $_.name -match $App.AssetPattern -and
        $_.name -match '\.apk$' -and
        $_.name -notmatch '(?i)debug|spoof(?:ed)?'
    })

    if ($assets.Count -eq 0) {
        throw "Release '$($Release.tag_name)' has no eligible APK asset for $($App.Name)."
    }

    # Prefer explicitly marked release/signed builds. If multiple plausible APKs
    # remain, stop instead of guessing and downloading a variant.
    $ranked = @($assets | Sort-Object -Property @{
        Expression = { if ($_.name -match '(?i)release|signed') { 0 } else { 1 } }
    }, name)
    if ($ranked.Count -gt 1) {
        $best = @($ranked | Where-Object { $_.name -match '(?i)release|signed' })
        if ($best.Count -ne 1) {
            $names = ($assets | ForEach-Object name) -join ', '
            throw "Multiple eligible APKs found for $($App.Name): $names. No file was downloaded."
        }
        return $best[0]
    }
    return $ranked[0]
}

function Format-RequestError($ErrorRecord) {
    $parts = @($ErrorRecord.Exception.Message)
    $response = $ErrorRecord.Exception.Response
    if ($response) {
        try {
            if ($response.StatusCode) { $parts += "HTTP status: $([int]$response.StatusCode) $($response.StatusDescription)" }
            if ($ErrorRecord.ErrorDetails.Message) {
                $parts += $ErrorRecord.ErrorDetails.Message
            } elseif ($response.GetResponseStream()) {
                $reader = [System.IO.StreamReader]::new($response.GetResponseStream())
                try { $body = $reader.ReadToEnd(); if ($body) { $parts += $body } } finally { $reader.Dispose() }
            }
        } catch { }
    }
    return ($parts -join [Environment]::NewLine)
}

$headers = @{ 'User-Agent' = 'Root-App-Release-Checker'; 'Accept' = 'application/vnd.github+json' }
if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
    $headers['Authorization'] = "Bearer $($env:GITHUB_TOKEN)"
    Write-Host 'Using authenticated GitHub API access.'
} else {
    Write-Host 'No GITHUB_TOKEN set; using the proxy IP shared unauthenticated API quota.' -ForegroundColor Yellow
}
$failed = $false

foreach ($app in $apps) {
    Write-Host "[$($app.Name)] Checking https://github.com/$($app.Repo)/releases/latest"
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$($app.Repo)/releases/latest" -Headers $headers -Proxy $proxy
        $asset = Select-ReleaseApk $app $release
        $localFiles = @(Get-ChildItem -LiteralPath (Get-Location).Path -File -Filter $app.LocalPattern | Sort-Object LastWriteTime -Descending)
        $local = if ($localFiles.Count) { $localFiles[0] } else { $null }
        $remoteKey = Get-VersionKey $asset.name $app.KeyPattern
        $localKey = if ($local) { Get-VersionKey $local.Name $app.KeyPattern } else { $null }

        if (-not $remoteKey) { throw "Cannot recognize version in release APK name '$($asset.name)'." }
        if ($local -and $localKey -eq $remoteKey) {
            Write-Host "  Up to date: $($local.Name) ($($release.tag_name))" -ForegroundColor Green
            continue
        }

        if ($local) {
            Write-Host "  Update available: $($local.Name) -> $($asset.name) ($($release.tag_name))" -ForegroundColor Yellow
        } else {
            Write-Host "  No local APK found; latest is $($asset.name) ($($release.tag_name))" -ForegroundColor Yellow
        }

        if ($CheckOnly) { continue }
        $destination = Join-Path (Get-Location).Path $asset.name
        if (Test-Path -LiteralPath $destination) {
            Write-Host "  Already downloaded: $($asset.name)"
            continue
        }
        Invoke-WebRequest -Uri $asset.browser_download_url -Headers @{ 'User-Agent' = $headers['User-Agent'] } -Proxy $proxy -OutFile $destination
        Write-Host "  Downloaded: $destination" -ForegroundColor Cyan
    }
    catch {
        $failed = $true
        Write-Host "  ERROR: $(Format-RequestError $_)" -ForegroundColor Red
    }
}

if ($failed) { exit 1 }
