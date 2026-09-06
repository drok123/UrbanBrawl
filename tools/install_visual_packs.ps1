$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression.FileSystem

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$cacheRoot = Join-Path $projectRoot ".visual_pack_cache"
$projectDownloads = Join-Path $projectRoot "visual_pack_downloads"
$userDownloads = Join-Path $env:USERPROFILE "Downloads"

$packPages = @{
    City = "https://quaternius.com/packs/downtowncitymegakit.html"
    Characters = "https://quaternius.com/packs/universalbasecharacters.html"
    UAL1 = "https://quaternius.com/packs/universalanimationlibrary.html"
    UAL2 = "https://quaternius.com/packs/universalanimationlibrary2.html"
}

function Reset-Directory([string]$Path) {
    if (Test-Path $Path) {
        Remove-Item $Path -Recurse -Force
    }
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function Get-CandidateZips {
    $roots = @($projectDownloads, $userDownloads) | Where-Object { Test-Path $_ }
    $items = @()
    foreach ($root in $roots) {
        $items += Get-ChildItem -Path $root -Filter "*.zip" -File -ErrorAction SilentlyContinue
    }
    return $items | Sort-Object LastWriteTime -Descending -Unique
}

function Get-ZipEntryNames([string]$ZipPath) {
    $archive = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        return @($archive.Entries | ForEach-Object { $_.FullName })
    }
    finally {
        $archive.Dispose()
    }
}

function Score-Pack([System.IO.FileInfo]$Zip, [string]$Kind) {
    $name = $Zip.Name.ToLowerInvariant()
    $entries = Get-ZipEntryNames $Zip.FullName
    $joined = ($entries -join "`n").ToLowerInvariant()
    $score = 0

    switch ($Kind) {
        "City" {
            if ($name -match "downtown.*city|city.*megakit") { $score += 300 }
            $score += [Math]::Min(160, ([regex]::Matches($joined, "building|facade|sidewalk|street")).Count * 2)
        }
        "Characters" {
            if ($name -match "universal.*base.*character|base.*character") { $score += 300 }
            $score += [Math]::Min(160, ([regex]::Matches($joined, "regular.*male|regular.*female|hairstyle|superhero|teen")).Count * 3)
        }
        "UAL1" {
            if ($name -match "universal.*animation.*library" -and $name -notmatch "library.?2|animation.?2") { $score += 300 }
            if ($name -match "ual1") { $score += 300 }
            $score += [Math]::Min(120, ([regex]::Matches($joined, "crawl|swim|walk|jog|pistol|rifle")).Count)
            $score -= [Math]::Min(100, ([regex]::Matches($joined, "farming|fishing|zombie|parkour")).Count)
        }
        "UAL2" {
            if ($name -match "universal.*animation.*library.?2|animation.*library.?2|ual2") { $score += 300 }
            $score += [Math]::Min(160, ([regex]::Matches($joined, "farming|fishing|zombie|parkour|combo|sword")).Count * 2)
        }
    }
    return $score
}

function Find-Pack([string]$Kind) {
    $best = $null
    $bestScore = 0
    foreach ($zip in Get-CandidateZips) {
        try {
            $score = Score-Pack $zip $Kind
            if ($score -gt $bestScore) {
                $bestScore = $score
                $best = $zip
            }
        }
        catch {
            Write-Host "Skipping unreadable ZIP: $($zip.FullName)" -ForegroundColor DarkGray
        }
    }
    if ($bestScore -lt 80) { return $null }
    return $best
}

function Resolve-Packs {
    return @{
        City = Find-Pack "City"
        Characters = Find-Pack "Characters"
        UAL1 = Find-Pack "UAL1"
        UAL2 = Find-Pack "UAL2"
    }
}

function Missing-Packs($packs) {
    return @("City", "Characters", "UAL1", "UAL2") | Where-Object { $null -eq $packs[$_] }
}

function Open-MissingPackPages($missing) {
    foreach ($kind in $missing) {
        Write-Host "Opening official Quaternius page for $kind..." -ForegroundColor Cyan
        Start-Process $packPages[$kind]
    }
}

function Expand-Pack([System.IO.FileInfo]$Zip, [string]$Name) {
    $destination = Join-Path $cacheRoot $Name
    Reset-Directory $destination
    Write-Host "Extracting $($Zip.Name)..." -ForegroundColor Cyan
    Expand-Archive -Path $Zip.FullName -DestinationPath $destination -Force
    return $destination
}

function Find-BestSceneTree([string]$ExtractRoot) {
    $sceneFiles = Get-ChildItem -Path $ExtractRoot -Recurse -File | Where-Object { $_.Extension -in @(".glb", ".gltf") }
    if (-not $sceneFiles) {
        throw "No GLB/glTF files found under $ExtractRoot"
    }

    $namedFolders = Get-ChildItem -Path $ExtractRoot -Recurse -Directory | Where-Object { $_.Name -match "(?i)^gltf$|^glb$|gltf|glb" }
    $bestFolder = $null
    $bestCount = 0
    foreach ($folder in $namedFolders) {
        $count = @(Get-ChildItem -Path $folder.FullName -Recurse -File | Where-Object { $_.Extension -in @(".glb", ".gltf") }).Count
        if ($count -gt $bestCount) {
            $bestCount = $count
            $bestFolder = $folder
        }
    }
    if ($null -ne $bestFolder) {
        return $bestFolder.FullName
    }

    return $ExtractRoot
}

function Install-SceneTree([string]$ExtractRoot, [string]$Destination) {
    $source = Find-BestSceneTree $ExtractRoot
    Reset-Directory $Destination
    Write-Host "Installing glTF tree: $source" -ForegroundColor Green
    Copy-Item (Join-Path $source "*") $Destination -Recurse -Force
}

function Install-UalSubset([string]$ExtractRoot, [string]$Destination) {
    Reset-Directory $Destination
    $glbs = @(Get-ChildItem -Path $ExtractRoot -Recurse -File | Where-Object { $_.Extension -eq ".glb" })
    if (-not $glbs) {
        throw "No GLB animation files found under $ExtractRoot"
    }

    $pattern = "idle|walk|jog|run|sprint|punch|kick|attack|melee|hit|impact|death|dodge|roll|shoot|aim|gun|pistol|stab|swing"
    $selected = @($glbs | Where-Object { $_.BaseName -match $pattern } | Sort-Object Length -Descending)

    # Some releases use one all-in-one GLB with a generic filename.
    if ($selected.Count -lt 3) {
        $selected = @($glbs | Sort-Object Length -Descending | Select-Object -First 8)
    }
    else {
        $selected = @($selected | Select-Object -First 28)
    }

    foreach ($file in $selected) {
        $safeName = $file.Name
        $target = Join-Path $Destination $safeName
        $counter = 2
        while (Test-Path $target) {
            $safeName = "$($file.BaseName)_$counter$($file.Extension)"
            $target = Join-Path $Destination $safeName
            $counter++
        }
        Copy-Item $file.FullName $target -Force
    }
    Write-Host "Installed $($selected.Count) animation GLB file(s) into $Destination" -ForegroundColor Green
}

Write-Host ""
Write-Host "URBAN BRAWL - VISUAL PACK INSTALLER" -ForegroundColor Yellow
Write-Host "Official assets: Quaternius Standard/free downloads (CC0)"
Write-Host ""

New-Item -ItemType Directory -Path $projectDownloads -Force | Out-Null
Reset-Directory $cacheRoot

$packs = Resolve-Packs
$missing = Missing-Packs $packs
if ($missing.Count -gt 0) {
    Write-Host "Missing official Standard ZIPs: $($missing -join ', ')" -ForegroundColor Yellow
    Write-Host "The official pages will open. Click the free/Standard Download on each page." -ForegroundColor Yellow
    Write-Host "Downloads can stay in your normal Windows Downloads folder." -ForegroundColor Yellow
    Open-MissingPackPages $missing
    Write-Host ""
    Read-Host "Finish the downloads, then press Enter to scan again"
    $packs = Resolve-Packs
    $missing = Missing-Packs $packs
}

if ($missing.Count -gt 0) {
    Write-Host "Still missing: $($missing -join ', ')" -ForegroundColor Red
    Write-Host "You can also place the downloaded ZIPs in: $projectDownloads" -ForegroundColor Yellow
    throw "Visual pack installation stopped because one or more official ZIPs could not be identified."
}

foreach ($key in @("City", "Characters", "UAL1", "UAL2")) {
    Write-Host "$key -> $($packs[$key].FullName)" -ForegroundColor DarkGray
}

$cityExtract = Expand-Pack $packs.City "city"
$characterExtract = Expand-Pack $packs.Characters "characters"
$ual1Extract = Expand-Pack $packs.UAL1 "ual1"
$ual2Extract = Expand-Pack $packs.UAL2 "ual2"

$thirdPartyRoot = Join-Path $projectRoot "assets\third_party"
New-Item -ItemType Directory -Path $thirdPartyRoot -Force | Out-Null
Install-SceneTree $cityExtract (Join-Path $thirdPartyRoot "quaternius_city")
Install-SceneTree $characterExtract (Join-Path $thirdPartyRoot "quaternius_characters")

$ualRoot = Join-Path $thirdPartyRoot "quaternius_ual"
New-Item -ItemType Directory -Path $ualRoot -Force | Out-Null
Install-UalSubset $ual1Extract (Join-Path $ualRoot "ual1")
Install-UalSubset $ual2Extract (Join-Path $ualRoot "ual2")

$noticeRoot = Join-Path $projectRoot "third_party_runtime"
New-Item -ItemType Directory -Path $noticeRoot -Force | Out-Null
@"
Quaternius visual assets used by Urban Brawl prototype
- Downtown City MegaKit
- Universal Base Characters
- Universal Animation Library
- Universal Animation Library 2
License: CC0 1.0 / public domain dedication
Official source: https://quaternius.com/
Downloaded Standard/free editions are intentionally not committed to this repository.
"@ | Set-Content -Path (Join-Path $noticeRoot "Quaternius-CC0-NOTICE.txt") -Encoding UTF8

if (Test-Path $cacheRoot) {
    Remove-Item $cacheRoot -Recurse -Force
}

Write-Host ""
Write-Host "Visual packs installed successfully." -ForegroundColor Green
Write-Host "Godot may spend a while importing the new glTF/GLB files on first reopen." -ForegroundColor Yellow
Write-Host "PoliceBlockA and the player will automatically prefer the imported assets." -ForegroundColor Green
Write-Host "If import/retarget validation fails, Urban Brawl keeps the existing fallback visuals." -ForegroundColor DarkGray
Write-Host ""
Read-Host "Press Enter to close"
