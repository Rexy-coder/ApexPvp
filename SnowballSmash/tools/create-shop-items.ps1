# Snowball Smash - creates all game passes and developer products on Roblox
# with regional pricing (and managed pricing) turned OFF, then prints the IDs.
#
# HOW TO RUN (Windows):
#   1. Get your Universe ID: Creator Dashboard -> your game -> the "..." menu -> Copy Universe ID.
#   2. Make an API key: create.roblox.com -> Open Cloud -> API Keys -> Create API Key
#        - Add API System "game-passes"         -> select your game -> Write
#        - Add API System "developer-products"  -> select your game -> Write
#        - Accepted IP addresses: 0.0.0.0/0 (or your own IP)
#      Copy the key. Keep it secret, never share it.
#   3. Right-click this file -> "Run with PowerShell"
#      (or in PowerShell:  powershell -ExecutionPolicy Bypass -File .\create-shop-items.ps1 )
#   4. Paste the Universe ID and API key when asked.
#
# The IDs are printed at the end and saved to shop-ids.txt next to this script.
# Copy each ID into ReplicatedStorage.Shared.Monetization (Id = 0 -> Id = <number>).
# Running it again skips items already listed in shop-ids.txt, so nothing is created twice.

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$passes = @(
    @{ Key = "VIP";         Name = "VIP";          Price = 349; Desc = "[VIP] chat tag, VIP name tag and +25% coins forever!" },
    @{ Key = "DoubleCoins"; Name = "2x Coins";     Price = 399; Desc = "Double the coins from every run, forever." },
    @{ Key = "PerfectPush"; Name = "Perfect Push"; Price = 199; Desc = "The power bar fills to MAX instantly, every time." },
    @{ Key = "MegaStart";   Name = "Mega Start";   Price = 249; Desc = "Start every run with a bigger snowball." },
    @{ Key = "LuckyCharm";  Name = "Lucky Charm";  Price = 179; Desc = "+10% chance for CRITICAL smashes (double coins)." },
    @{ Key = "RainbowBall"; Name = "Rainbow Ball"; Price = 149; Desc = "Exclusive colour-shifting snowball skin, +50% coins." },
    @{ Key = "TripleHatch"; Name = "Triple Hatch"; Price = 249; Desc = "Hatch 3 eggs at once!" },
    @{ Key = "AutoHatch";   Name = "Auto Hatch";   Price = 299; Desc = "Keep hatching eggs automatically." },
    @{ Key = "LuckyEggs";   Name = "Lucky Eggs";   Price = 399; Desc = "x1.5 chance for Rare, Epic, Legendary and Secret pets." },
    @{ Key = "ExtraPets";   Name = "+2 Pet Slots"; Price = 199; Desc = "Equip 2 more pets at the same time." }
)

$products = @(
    @{ Key = "Turbo5";      Name = "Turbo Boost x5";     Price = 99;  Desc = "5 Turbos! Press T mid-run: huge speed + unstoppable smashing." },
    @{ Key = "Turbo20";     Name = "Turbo Boost x20";    Price = 299; Desc = "20 Turbos for the price of 15!" },
    @{ Key = "CoinsSmall";  Name = "Pile of Coins";      Price = 25;  Desc = "+2,500 coins" },
    @{ Key = "CoinsMedium"; Name = "Bag of Coins";       Price = 99;  Desc = "+15,000 coins" },
    @{ Key = "CoinsLarge";  Name = "Chest of Coins";     Price = 299; Desc = "+60,000 coins" },
    @{ Key = "CoinsHuge";   Name = "Vault of Coins";     Price = 799; Desc = "+250,000 coins" },
    @{ Key = "Boost15";     Name = "x2 Coins (15 min)";  Price = 49;  Desc = "Your coins are doubled for 15 minutes." },
    @{ Key = "Boost60";     Name = "x2 Coins (1 hour)";  Price = 149; Desc = "Your coins are doubled for a whole hour." },
    @{ Key = "ServerStorm"; Name = "Server Coin Storm";  Price = 199; Desc = "x2 coins for EVERYONE in the server for 10 minutes!" },
    @{ Key = "LegendaryPet"; Name = "Legendary Pet";     Price = 299; Desc = "Get a random Legendary pet (5% chance: SECRET)!" },
    @{ Key = "CandySmall";  Name = "Bag of Candy";       Price = 49;  Desc = "+250 Halloween candy" },
    @{ Key = "CandyLarge";  Name = "Cauldron of Candy";  Price = 149; Desc = "+1,000 Halloween candy" }
)

$universeId = (Read-Host "Universe ID").Trim()
$apiKey = (Read-Host "Open Cloud API key").Trim()
if (-not ($universeId -match '^\d+$')) { throw "The Universe ID should be a number." }

$idFile = Join-Path $PSScriptRoot "shop-ids.txt"
$existing = @{}
if (Test-Path $idFile) {
    foreach ($line in Get-Content $idFile) {
        if ($line -match '^(\w+)\s*=\s*(\d+)') { $existing[$Matches[1]] = $Matches[2] }
    }
}

$client = New-Object System.Net.Http.HttpClient
$client.DefaultRequestHeaders.Add("x-api-key", $apiKey)

function New-Item-OnRoblox($url, $item, $idField) {
    $fields = [ordered]@{
        name                     = $item.Name
        description              = $item.Desc
        price                    = [string]$item.Price
        isForSale                = "true"
        isRegionalPricingEnabled = "false"
        isManagedPricingEnabled  = "false"
    }
    for ($attempt = 1; $attempt -le 4; $attempt++) {
        # the form is consumed by each send, so build a fresh one per attempt
        $form = New-Object System.Net.Http.MultipartFormDataContent
        foreach ($k in $fields.Keys) {
            $form.Add((New-Object System.Net.Http.StringContent($fields[$k])), $k)
        }
        $response = $client.PostAsync($url, $form).Result
        $body = $response.Content.ReadAsStringAsync().Result
        if ($response.IsSuccessStatusCode) {
            return ($body | ConvertFrom-Json).$idField
        }
        if ([int]$response.StatusCode -eq 429) {
            Write-Host "   rate limited, waiting..." -ForegroundColor DarkYellow
            Start-Sleep -Seconds (5 * $attempt)
            continue
        }
        throw "Roblox said $([int]$response.StatusCode): $body"
    }
    throw "Still rate limited, try again in a minute."
}

$results = [ordered]@{}
$failed = 0

Write-Host "`nCreating game passes..." -ForegroundColor Cyan
foreach ($p in $passes) {
    if ($existing.ContainsKey($p.Key)) { Write-Host " skip $($p.Name) (already $($existing[$p.Key]))"; $results[$p.Key] = $existing[$p.Key]; continue }
    try {
        $id = New-Item-OnRoblox "https://apis.roblox.com/game-passes/v1/universes/$universeId/game-passes" $p "gamePassId"
        Write-Host " OK  $($p.Name)  ->  $id" -ForegroundColor Green
        $results[$p.Key] = $id
        Add-Content $idFile "$($p.Key) = $id"
    } catch {
        Write-Host " FAIL $($p.Name): $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
    Start-Sleep -Milliseconds 800
}

Write-Host "`nCreating developer products..." -ForegroundColor Cyan
foreach ($p in $products) {
    if ($existing.ContainsKey($p.Key)) { Write-Host " skip $($p.Name) (already $($existing[$p.Key]))"; $results[$p.Key] = $existing[$p.Key]; continue }
    try {
        $id = New-Item-OnRoblox "https://apis.roblox.com/developer-products/v2/universes/$universeId/developer-products" $p "productId"
        Write-Host " OK  $($p.Name)  ->  $id" -ForegroundColor Green
        $results[$p.Key] = $id
        Add-Content $idFile "$($p.Key) = $id"
    } catch {
        Write-Host " FAIL $($p.Name): $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
    Start-Sleep -Milliseconds 800
}

Write-Host "`n===== IDs (also saved to $idFile) =====" -ForegroundColor Cyan
foreach ($k in $results.Keys) { Write-Host ("{0,-12} = {1}" -f $k, $results[$k]) }
if ($failed -gt 0) {
    Write-Host "`n$failed item(s) failed. Fix the problem shown above and run the script again; finished items are skipped." -ForegroundColor Yellow
}
Write-Host "`nNext: copy these IDs into ReplicatedStorage.Shared.Monetization and publish the game."
Write-Host "Tip: add icons for each item on the Creator Dashboard (Monetization -> Passes / Developer Products)."
Read-Host "`nPress Enter to close"
