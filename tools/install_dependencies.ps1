$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$cacheRoot = Join-Path $projectRoot ".third_party_cache"
$runtimeRoot = Join-Path $projectRoot "third_party_runtime"

$dependencies = @(
    @{
        Name = "Oen44 Universal Inventory System"
        Repo = "Oen44/Godot-Inventory"
        Tag = "v4.0.1a"
        Zip = "https://codeload.github.com/Oen44/Godot-Inventory/zip/refs/tags/v4.0.1a"
        Folder = "Godot-Inventory-4.0.1a"
        License = "https://raw.githubusercontent.com/Oen44/Godot-Inventory/v4.0.1a/LICENSE"
    },
    @{
        Name = "Beehave"
        Repo = "bitbrain/beehave"
        Tag = "v2.9.3"
        Zip = "https://codeload.github.com/bitbrain/beehave/zip/refs/tags/v2.9.3"
        Folder = "beehave-2.9.3"
        License = "https://raw.githubusercontent.com/bitbrain/beehave/v2.9.3/LICENSE"
    },
    @{
        Name = "Godot Road Generator"
        Repo = "TheDuckCow/godot-road-generator"
        Tag = "0.9.3"
        Zip = "https://codeload.github.com/TheDuckCow/godot-road-generator/zip/refs/tags/0.9.3"
        Folder = "godot-road-generator-0.9.3"
        License = "https://raw.githubusercontent.com/TheDuckCow/godot-road-generator/0.9.3/LICENSE"
    },
    @{
        Name = "CityCrafter 3D"
        Repo = "SpartanDavie/CityCrafter3D-Aug2025"
        Tag = "04aee37b8d0d8279fbfe0b48d29c5aff7e05992e"
        RawBase = "https://raw.githubusercontent.com/SpartanDavie/CityCrafter3D-Aug2025/04aee37b8d0d8279fbfe0b48d29c5aff7e05992e/addons/citycrafter"
        License = "https://raw.githubusercontent.com/SpartanDavie/CityCrafter3D-Aug2025/04aee37b8d0d8279fbfe0b48d29c5aff7e05992e/addons/citycrafter/LICENSE"
    }
)

function Reset-Directory([string]$Path) {
    if (Test-Path $Path) {
        Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
        if (Test-Path $Path) {
            # Windows PowerShell's archive module can leave partially extracted
            # trees in a state Remove-Item dislikes. cmd/rmdir is more tolerant
            # for cleaning our disposable dependency cache.
            cmd /c "rmdir /s /q `"$Path`"" | Out-Null
        }
    }
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function Download-And-Expand($dep) {
    $zipPath = Join-Path $cacheRoot (($dep.Repo -replace '/', '-') + ".zip")
    $extractPath = Join-Path $cacheRoot (($dep.Repo -replace '/', '-') + "-extract")

    Write-Host "Downloading $($dep.Name) $($dep.Tag)..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $dep.Zip -OutFile $zipPath -UseBasicParsing

    Reset-Directory $extractPath
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

    $root = Join-Path $extractPath $dep.Folder
    if (-not (Test-Path $root)) {
        $candidate = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1
        if ($null -eq $candidate) {
            throw "No extracted dependency folder was found under: $extractPath"
        }
        $root = $candidate.FullName
    }

    return $root
}

function Install-License($dep, [string]$destinationName) {
    $destination = Join-Path $runtimeRoot $destinationName
    Write-Host "Installing license for $($dep.Name)..." -ForegroundColor DarkGray
    Invoke-WebRequest -Uri $dep.License -OutFile $destination -UseBasicParsing
}

function Download-File([string]$Url, [string]$Destination) {
    $parent = Split-Path -Parent $Destination
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
    if (-not (Test-Path $Destination)) {
        throw "Download did not create expected file: $Destination"
    }
}

Write-Host ""
Write-Host "URBAN BRAWL - DEPENDENCY INSTALLER" -ForegroundColor Yellow
Write-Host "Project: $projectRoot"
Write-Host ""

Reset-Directory $cacheRoot
New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $projectRoot "addons") -Force | Out-Null

$legacyKaykit = Join-Path $projectRoot "assets\third_party\kaykit_adventurers"
if (Test-Path $legacyKaykit) {
    Write-Host "Removing obsolete KayKit prototype character files..." -ForegroundColor DarkGray
    Remove-Item $legacyKaykit -Recurse -Force
}

# --- Oen44 inventory/itemization ---
$inventoryRoot = Download-And-Expand $dependencies[0]

Write-Host "Installing complete Oen44 runtime script set..." -ForegroundColor Green
foreach ($folder in @("equipment", "inventory", "itemization", "tooltip", "vendor")) {
    $source = Join-Path $inventoryRoot ("scripts\" + $folder)
    $destination = Join-Path $projectRoot ("scripts\" + $folder)

    if (-not (Test-Path $source)) {
        throw "Missing expected inventory dependency folder: $source"
    }

    if (Test-Path $destination) {
        Remove-Item $destination -Recurse -Force
    }
    Copy-Item $source $destination -Recurse -Force
}

$inventoryScenes = @(
    "affix_pool.tscn",
    "equipment_slot.tscn",
    "inventory_slot.tscn",
    "inventory_system.tscn",
    "item_tooltip.tscn",
    "quantity_selector.tscn"
)
foreach ($scene in $inventoryScenes) {
    $sourceScene = Join-Path $inventoryRoot ("scenes\" + $scene)
    if (-not (Test-Path $sourceScene)) {
        throw "Missing expected inventory scene: $sourceScene"
    }
    Copy-Item $sourceScene (Join-Path $projectRoot ("scenes\" + $scene)) -Force
}

$requiredInventoryFiles = @(
    "scripts\inventory\InventoryModel.gd",
    "scripts\vendor\VendorInventory.gd",
    "scripts\vendor\VendorComponent.gd",
    "scripts\itemization\Item.gd",
    "scripts\itemization\ItemBase.gd"
)
foreach ($relativePath in $requiredInventoryFiles) {
    $absolutePath = Join-Path $projectRoot $relativePath
    if (-not (Test-Path $absolutePath)) {
        throw "Oen44 install is incomplete; required runtime file is missing: $absolutePath"
    }
}
Install-License $dependencies[0] "Oen44-Godot-Inventory-LICENSE.txt"

# --- Beehave ---
$beehaveRoot = Download-And-Expand $dependencies[1]
Write-Host "Installing Beehave behavior-tree addon..." -ForegroundColor Green
$beehaveSource = Join-Path $beehaveRoot "addons\beehave"
$beehaveDestination = Join-Path $projectRoot "addons\beehave"
if (-not (Test-Path $beehaveSource)) {
    throw "Missing expected Beehave addon folder: $beehaveSource"
}
if (Test-Path $beehaveDestination) {
    Remove-Item $beehaveDestination -Recurse -Force
}
Copy-Item $beehaveSource $beehaveDestination -Recurse -Force
Install-License $dependencies[1] "Beehave-LICENSE.txt"

# --- Godot Road Generator ---
$roadRoot = Download-And-Expand $dependencies[2]
Write-Host "Installing Godot Road Generator addon..." -ForegroundColor Green
$roadSource = Join-Path $roadRoot "addons\road-generator"
$roadDestination = Join-Path $projectRoot "addons\road-generator"
if (-not (Test-Path $roadSource)) {
    throw "Missing expected Road Generator addon folder: $roadSource"
}
if (Test-Path $roadDestination) {
    Remove-Item $roadDestination -Recurse -Force
}
Copy-Item $roadSource $roadDestination -Recurse -Force

$requiredRoadFiles = @(
    "addons\road-generator\plugin.cfg",
    "addons\road-generator\nodes\road_manager.gd",
    "addons\road-generator\nodes\road_container.gd",
    "addons\road-generator\nodes\road_point.gd",
    "addons\road-generator\resources\road_texture.material"
)
foreach ($relativePath in $requiredRoadFiles) {
    $absolutePath = Join-Path $projectRoot $relativePath
    if (-not (Test-Path $absolutePath)) {
        throw "Road Generator install is incomplete; required file is missing: $absolutePath"
    }
}
Install-License $dependencies[2] "Godot-Road-Generator-LICENSE.txt"

# --- CityCrafter 3D ---
# Do NOT download/extract the full CityCrafter repository. Its example asset
# tree is large and Windows PowerShell 5.1 Expand-Archive can fail while
# traversing it. Urban Brawl only needs the small topology/editor core.
$cityCrafter = $dependencies[3]
$cityCrafterDestination = Join-Path $projectRoot "addons\citycrafter"
Write-Host "Installing CityCrafter topology core directly (no archive extraction)..." -ForegroundColor Green

if (Test-Path $cityCrafterDestination) {
    Remove-Item $cityCrafterDestination -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path $cityCrafterDestination) {
        cmd /c "rmdir /s /q `"$cityCrafterDestination`"" | Out-Null
    }
}
New-Item -ItemType Directory -Path $cityCrafterDestination -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $cityCrafterDestination "assets") -Force | Out-Null

$cityCrafterCoreFiles = @(
    "LICENSE",
    "city_configuration.gd",
    "city_configuration.gd.uid",
    "citycrafter.gd",
    "citycrafter.gd.uid",
    "plugin.cfg",
    "plugin.gd",
    "plugin.gd.uid"
)
foreach ($file in $cityCrafterCoreFiles) {
    $url = "$($cityCrafter.RawBase)/$file"
    $destination = Join-Path $cityCrafterDestination $file
    Write-Host "  $file" -ForegroundColor DarkGray
    Download-File $url $destination
}

Download-File "$($cityCrafter.RawBase)/assets/citycrafter_icon.png" (Join-Path $cityCrafterDestination "assets\citycrafter_icon.png")

$requiredCityCrafterFiles = @(
    "addons\citycrafter\plugin.cfg",
    "addons\citycrafter\city_configuration.gd",
    "addons\citycrafter\citycrafter.gd",
    "addons\citycrafter\assets\citycrafter_icon.png"
)
foreach ($relativePath in $requiredCityCrafterFiles) {
    $absolutePath = Join-Path $projectRoot $relativePath
    if (-not (Test-Path $absolutePath)) {
        throw "CityCrafter install is incomplete; required file is missing: $absolutePath"
    }
}
Install-License $cityCrafter "CityCrafter-LICENSE.txt"

if (Test-Path $cacheRoot) {
    Remove-Item $cacheRoot -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path $cacheRoot) {
        cmd /c "rmdir /s /q `"$cacheRoot`"" | Out-Null
    }
}

Write-Host ""
Write-Host "Code dependencies installed successfully." -ForegroundColor Green
Write-Host "  Oen44/Godot-Inventory @ v4.0.1a"
Write-Host "  bitbrain/beehave @ v2.9.3"
Write-Host "  TheDuckCow/godot-road-generator @ 0.9.3"
Write-Host "  SpartanDavie/CityCrafter3D-Aug2025 @ 04aee37 (core topology only)"
Write-Host ""
Write-Host "Quaternius city/character assets remain installed separately with INSTALL-VISUAL-PACKS.bat." -ForegroundColor DarkGray
Write-Host "Restart Godot after dependency changes." -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to close"
