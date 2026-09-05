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
        Name = "KayKit Character Pack - Adventurers"
        Repo = "KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0"
        Tag = "672074b73ba276876a19e8816ecdc5241817ab47"
        License = "https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0/672074b73ba276876a19e8816ecdc5241817ab47/LICENSE.txt"
        Rogue = "https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0/672074b73ba276876a19e8816ecdc5241817ab47/addons/kaykit_character_pack_adventures/Characters/gltf/Rogue.glb"
        RogueTexture = "https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0/672074b73ba276876a19e8816ecdc5241817ab47/addons/kaykit_character_pack_adventures/Characters/gltf/rogue_texture.png"
    }
)

function Reset-Directory([string]$Path) {
    if (Test-Path $Path) {
        Remove-Item $Path -Recurse -Force
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

Write-Host ""
Write-Host "URBAN BRAWL - DEPENDENCY INSTALLER" -ForegroundColor Yellow
Write-Host "Project: $projectRoot"
Write-Host ""

Reset-Directory $cacheRoot
New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $projectRoot "addons") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $projectRoot "assets\third_party") -Force | Out-Null

# --- Oen44 inventory/itemization ---
$inventoryRoot = Download-And-Expand $dependencies[0]

Write-Host "Installing complete Oen44 runtime script set..." -ForegroundColor Green
# InventoryModel directly references VendorInventory, so vendor/ is a required runtime
# dependency even before Urban Brawl exposes vendor UI/gameplay.
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

# Validate cross-folder class dependencies that GDScript resolves at parse time.
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

# Beehave deliberately export-ignores the repository-root LICENSE from release ZIPs,
# so retrieve the license separately from the exact pinned tag.
Install-License $dependencies[1] "Beehave-LICENSE.txt"

# --- KayKit temporary animated character prototype rig ---
# Use the empty-handed Rogue instead of the Barbarian. The Barbarian model bakes axes
# into the character visual, which conflicts with Urban Brawl's runtime equipment system.
# This remains a temporary test rig while Quaternius Universal Base Characters becomes
# the long-term neutral humanoid/retargeting foundation.
Write-Host "Installing KayKit empty-handed humanoid test rig..." -ForegroundColor Green
$kaykitDestination = Join-Path $projectRoot "assets\third_party\kaykit_adventurers"
Reset-Directory $kaykitDestination

$kaykitRogue = Join-Path $kaykitDestination "Rogue.glb"
$kaykitTexture = Join-Path $kaykitDestination "rogue_texture.png"

Write-Host "Downloading KayKit Rogue.glb..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $dependencies[2].Rogue -OutFile $kaykitRogue -UseBasicParsing
Write-Host "Downloading KayKit rogue_texture.png..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $dependencies[2].RogueTexture -OutFile $kaykitTexture -UseBasicParsing

if (-not (Test-Path $kaykitRogue) -or (Get-Item $kaykitRogue).Length -lt 100000) {
    throw "KayKit install is incomplete or invalid; Rogue.glb was not downloaded correctly: $kaykitRogue"
}
if (-not (Test-Path $kaykitTexture) -or (Get-Item $kaykitTexture).Length -lt 1000) {
    throw "KayKit install is incomplete or invalid; rogue_texture.png was not downloaded correctly: $kaykitTexture"
}
Install-License $dependencies[2] "KayKit-Adventurers-LICENSE.txt"

# Clean temporary downloads after successful install.
if (Test-Path $cacheRoot) {
    Remove-Item $cacheRoot -Recurse -Force
}

Write-Host ""
Write-Host "Dependencies installed successfully." -ForegroundColor Green
Write-Host "  Oen44/Godot-Inventory @ v4.0.1a (equipment/inventory/itemization/tooltip/vendor)"
Write-Host "  bitbrain/beehave @ v2.9.3"
Write-Host "  KayKit Adventurers @ 672074b (Rogue.glb + texture, temporary neutral rig)"
Write-Host ""
Write-Host "Restart Godot after installation." -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to close"
