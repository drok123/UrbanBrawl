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

# --- Oen44 inventory/itemization ---
$inventoryRoot = Download-And-Expand $dependencies[0]

Write-Host "Installing inventory / itemization source..." -ForegroundColor Green
foreach ($folder in @("equipment", "inventory", "itemization", "tooltip")) {
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
