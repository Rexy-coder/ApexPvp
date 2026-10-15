# Snowball Smash - ONE script for the whole shop:
#   1. creates every game pass / developer product that doesn't exist yet
#      (regional pricing and managed pricing OFF)
#   2. uploads the icon for every pass and product
#   3. saves all IDs to shop-ids.txt (send that file to Claude to put into the game)
#
# HOW TO RUN (Windows):
#   1. Unzip everything into one folder: setup-shop.ps1, shop-ids.txt and the "shop-icons" folder.
#   2. You need an Open Cloud API key (create.roblox.com/dashboard/credentials -> Create API Key):
#        - Add API System "game-passes"         -> select your game -> Read + Write
#        - Add API System "developer-products"  -> select your game -> Read + Write
#        - Accepted IP addresses: 0.0.0.0/0
#      You can reuse the key from last time if you still have it. Never share the key with anyone.
#   3. Right-click setup-shop.ps1 -> "Run with PowerShell"
#      (or in PowerShell:  powershell -ExecutionPolicy Bypass -File .\setup-shop.ps1 )
#   4. Paste the API key when asked.
#
# Safe to run again: items that already have an ID are never created twice,
# and uploading an icon again just replaces it.

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$universeId = "10770520658"

# Id = "" means "not created yet" -> the script creates it
$passes = @(
    @{ Key = "VIP";         Id = "2027211169"; Name = "VIP";          Price = 349; Desc = "[VIP] chat tag, VIP name tag and +25% coins forever!" },
    @{ Key = "DoubleCoins"; Id = "2025405231"; Name = "2x Coins";     Price = 399; Desc = "Double the coins from every run, forever." },
    @{ Key = "PerfectPush"; Id = "2025975197"; Name = "Perfect Push"; Price = 199; Desc = "The power bar fills super fast, every time." },
    @{ Key = "MegaStart";   Id = "2025675230"; Name = "Mega Start";   Price = 249; Desc = "Start every run with a bigger snowball." },
    @{ Key = "LuckyCharm";  Id = "2026497223"; Name = "Lucky Charm";  Price = 179; Desc = "+10% chance for CRITICAL smashes (double coins)." },
    @{ Key = "RainbowBall"; Id = "2025657163"; Name = "Rainbow Ball"; Price = 149; Desc = "Exclusive colour-shifting snowball skin, +50% coins." },
    @{ Key = "TripleHatch"; Id = "";           Name = "Triple Hatch"; Price = 249; Desc = "Hatch 3 eggs at once!" },
    @{ Key = "AutoHatch";   Id = "";           Name = "Auto Hatch";   Price = 299; Desc = "Keep hatching eggs automatically." },
    @{ Key = "LuckyEggs";   Id = "";           Name = "Lucky Eggs";   Price = 399; Desc = "x1.5 chance for Rare, Epic, Legendary and Secret pets." },
    @{ Key = "ExtraPets";   Id = "";           Name = "+2 Pet Slots"; Price = 199; Desc = "Equip 2 more pets at the same time." }
)

$products = @(
    @{ Key = "Turbo5";       Id = "3718165483"; Name = "Turbo Boost x5";    Price = 99;  Desc = "5 Turbos! Press T mid-run: huge speed + unstoppable smashing." },
    @{ Key = "Turbo20";      Id = "3718165489"; Name = "Turbo Boost x20";   Price = 299; Desc = "20 Turbos for the price of 15!" },
    @{ Key = "CoinsSmall";   Id = "3718165495"; Name = "Pile of Coins";     Price = 25;  Desc = "+2,500 coins" },
    @{ Key = "CoinsMedium";  Id = "3718165497"; Name = "Bag of Coins";      Price = 99;  Desc = "+15,000 coins" },
    @{ Key = "CoinsLarge";   Id = "3718165503"; Name = "Chest of Coins";    Price = 299; Desc = "+60,000 coins" },
    @{ Key = "CoinsHuge";    Id = "3718165507"; Name = "Vault of Coins";    Price = 799; Desc = "+250,000 coins" },
    @{ Key = "Boost15";      Id = "3718165511"; Name = "x2 Coins (15 min)"; Price = 49;  Desc = "Your coins are doubled for 15 minutes." },
    @{ Key = "Boost60";      Id = "3718165517"; Name = "x2 Coins (1 hour)"; Price = 149; Desc = "Your coins are doubled for a whole hour." },
    @{ Key = "ServerStorm";  Id = "3718165522"; Name = "Server Coin Storm"; Price = 199; Desc = "x2 coins for EVERYONE in the server for 10 minutes!" },
    @{ Key = "LegendaryPet"; Id = "";           Name = "Legendary Pet";     Price = 299; Desc = "Get a random Legendary pet (5% chance: SECRET)!" },
    @{ Key = "CandySmall";   Id = "";           Name = "Bag of Candy";      Price = 49;  Desc = "+250 Halloween candy" },
    @{ Key = "CandyLarge";   Id = "";           Name = "Cauldron of Candy"; Price = 149; Desc = "+1,000 Halloween candy" }
)

$passUrl = "https://apis.roblox.com/game-passes/v1/universes/$universeId/game-passes"
$productUrl = "https://apis.roblox.com/developer-products/v2/universes/$universeId/developer-products"

# IDs saved by an earlier run (shop-ids.txt) win over the list above
$idFile = Join-Path $PSScriptRoot "shop-ids.txt"
$saved = @{}
if (Test-Path $idFile) {
    foreach ($line in Get-Content $idFile) {
        if ($line -match '^(\w+)\s*=\s*(\d+)') { $saved[$Matches[1]] = $Matches[2] }
    }
}
foreach ($item in $passes + $products) {
    if ($saved.ContainsKey($item.Key)) { $item.Id = $saved[$item.Key] }
}

$iconDir = Join-Path $PSScriptRoot "shop-icons"
if (-not (Test-Path $iconDir)) { throw "Can't find the 'shop-icons' folder next to this script ($iconDir). Unzip everything into one folder first." }

$apiKey = (Read-Host "Open Cloud API key").Trim()
if (-not $apiKey) { throw "No API key entered." }
$client = New-Object System.Net.Http.HttpClient
$client.DefaultRequestHeaders.Add("x-api-key", $apiKey)

# Sends a request built by $makeRequest (a fresh one per attempt), retries when rate limited.
function Send-WithRetry($makeRequest) {
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        $response = $client.SendAsync((& $makeRequest)).Result
        $body = $response.Content.ReadAsStringAsync().Result
        if ($response.IsSuccessStatusCode) { return $body }
        if ([int]$response.StatusCode -eq 429) {
            Write-Host "   rate limited, waiting..." -ForegroundColor DarkYellow
            Start-Sleep -Seconds (5 * $attempt)
            continue
        }
        throw "Roblox said $([int]$response.StatusCode): $body"
    }
    throw "Still rate limited, try again in a minute."
}

function New-ShopItem($url, $item, $idField) {
    $fields = [ordered]@{
        name                     = $item.Name
        description              = $item.Desc
        price                    = [string]$item.Price
        isForSale                = "true"
        isRegionalPricingEnabled = "false"
        isManagedPricingEnabled  = "false"
    }
    $body = Send-WithRetry {
        $form = New-Object System.Net.Http.MultipartFormDataContent
        foreach ($k in $fields.Keys) {
            $form.Add((New-Object System.Net.Http.StringContent($fields[$k])), $k)
        }
        $request = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Post, $url)
        $request.Content = $form
        $request
    }
    return [string](($body | ConvertFrom-Json).$idField)
}

function Send-Icon($url, $file) {
    $null = Send-WithRetry {
        $form = New-Object System.Net.Http.MultipartFormDataContent
        $bytes = [System.IO.File]::ReadAllBytes($file)
        $image = New-Object System.Net.Http.ByteArrayContent(, $bytes)
        $image.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("image/png")
        $form.Add($image, "imageFile", [System.IO.Path]::GetFileName($file))
        $request = New-Object System.Net.Http.HttpRequestMessage((New-Object System.Net.Http.HttpMethod("PATCH")), $url)
        $request.Content = $form
        $request
    }
}

$failed = 0

# ---------------------------------------------------------------- 1. create
function Create-Missing($items, $url, $idField, $label) {
    Write-Host "`nCreating $label..." -ForegroundColor Cyan
    foreach ($item in $items) {
        if ($item.Id) { Write-Host " have $($item.Name) ($($item.Id))" -ForegroundColor DarkGray; continue }
        try {
            $id = New-ShopItem $url $item $idField
            if (-not ($id -match '^\d+$')) { throw "Roblox didn't send back an ID" }
            $item.Id = $id
            Add-Content $idFile "$($item.Key) = $id"
            Write-Host " NEW  $($item.Name)  ->  $id" -ForegroundColor Green
        } catch {
            Write-Host " FAIL $($item.Name): $($_.Exception.Message)" -ForegroundColor Red
            $script:failed++
        }
        Start-Sleep -Milliseconds 800
    }
}
Create-Missing $passes $passUrl "gamePassId" "game passes"
Create-Missing $products $productUrl "productId" "developer products"

# ---------------------------------------------------------------- 2. icons
function Upload-Icons($items, $url, $label) {
    Write-Host "`nUploading $label icons..." -ForegroundColor Cyan
    foreach ($item in $items) {
        if (-not $item.Id) { Write-Host " skip $($item.Name) (not created)" -ForegroundColor DarkYellow; continue }
        $file = Join-Path $iconDir "$($item.Key).png"
        if (-not (Test-Path $file)) { Write-Host " MISSING $($item.Key).png" -ForegroundColor Red; $script:failed++; continue }
        try {
            Send-Icon "$url/$($item.Id)" $file
            Write-Host " OK   $($item.Name)" -ForegroundColor Green
        } catch {
            Write-Host " FAIL $($item.Name): $($_.Exception.Message)" -ForegroundColor Red
            $script:failed++
        }
        Start-Sleep -Milliseconds 800
    }
}
Upload-Icons $passes $passUrl "game pass"
Upload-Icons $products $productUrl "developer product"

# ---------------------------------------------------------------- 3. save
$lines = @()
foreach ($item in $passes + $products) {
    if ($item.Id) { $lines += "$($item.Key) = $($item.Id)" }
}
Set-Content $idFile $lines

Write-Host "`n===== All IDs (saved to $idFile) =====" -ForegroundColor Cyan
$lines | ForEach-Object { Write-Host $_ }
if ($failed -eq 0) {
    Write-Host "`nDone! Icons can show as 'pending' for a few minutes while Roblox moderation checks them." -ForegroundColor Green
} else {
    Write-Host "`n$failed thing(s) failed - see the red lines above. Fix the problem and run the script again (it won't create anything twice)." -ForegroundColor Yellow
}
Write-Host "Next: send shop-ids.txt (or the list above) to Claude so the IDs go into the game."
Read-Host "`nPress Enter to close"
