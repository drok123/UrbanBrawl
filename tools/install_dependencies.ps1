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
    },
    @{
        Name = "Beehave"
        Repo = "bitbrain/beehave"
        Tag = "v2.9.3"
        Zip = "https://codeload.github.com/bitbrain/beehave/zip/refs/tags/v2.9.3"
        Folder = "beehave-2.9.3"
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
        throw "Expected extracted folder was not found: $root"
    }
    return $root
}

Write-Host ""
Write-Host "URBAN BRAWL - DEPENDENCY INSTALLER" -ForegroundColor Yellow
Write-Host "Project: $projectRoot"
Write-Host ""

Reset-Directory $cacheRoot
New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $projectRoot "addons") -Force | Out-Null

# --- Oen44 inventory/itemization ---
$inventoryRoot = Download-And-Expand $dependencies[0]

Write-Host "Installing inventory / itemization source..." -ForegroundColor Green
foreach ($folder in @("equipment", "inventory", "itemization", "tooltip")) {
    $source = Join-Path $inventoryRoot ("scripts\" + $folder)
    $destination = Join-Path $projectRoot ("scripts\" + $folder)
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
    Copy-Item (Join-Path $inventoryRoot ("scenes\" + $scene)) (Join-Path $projectRoot ("scenes\" + $scene)) -Force
}
Copy-Item (Join-Path $inventoryRoot "LICENSE") (Join-Path $runtimeRoot "Oen44-Godot-Inventory-LICENSE.txt") -Force

# --- Beehave ---
$beehaveRoot = Download-And-Expand $dependencies[1]

Write-Host "Installing Beehave behavior-tree addon..." -ForegroundColor Green
$beehaveDestination = Join-Path $projectRoot "addons\beehave"
if (Test-Path $beehaveDestination) {
    Remove-Item $beehaveDestination -Recurse -Force
}
Copy-Item (Join-Path $beehaveRoot "addons\beehave") $beehaveDestination -Recurse -Force
Copy-Item (Join-Path $beehaveRoot "LICENSE") (Join-Path $runtimeRoot "Beehave-LICENSE.txt") -Force

# Clean temporary downloads after successful install.
Remove-Item $cacheRoot -Recurse -Force

Write-Host ""
Write-Host "Dependencies installed successfully." -ForegroundColor Green
Write-Host "  Oen44/Godot-Inventory @ v4.0.1a"
Write-Host "  bitbrain/beehave @ v2.9.3"
Write-Host ""
Write-Host "Restart Godot after installation." -ForegroundColor Yellow
Write-Host "The project will wire these systems into gameplay in subsequent Urban Brawl commits."
Write-Host ""
Read-Host "Press Enter to close"
