# Snowball Smash - uploads the icon for every game pass and developer product.
#
# HOW TO RUN (Windows):
#   1. Put this script and the "shop-icons" folder (VIP.png, Turbo5.png, ...) in the same folder.
#   2. You need an Open Cloud API key with WRITE access to "game-passes" and
#      "developer-products" for your game (the same kind of key as for create-shop-items.ps1).
#      If you deleted the old one, make a new one: create.roblox.com/dashboard/credentials
#   3. Right-click this file -> "Run with PowerShell"
#      (or: powershell -ExecutionPolicy Bypass -File .\upload-shop-icons.ps1 )
#   4. Paste the API key when asked.
#
# New images are checked by Roblox moderation first, so they can show as "pending" for a few minutes.

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$universeId = "10770520658"

# Key (= icon file name) -> ID on Roblox
$passes = [ordered]@{
    VIP         = "2027211169"
    DoubleCoins = "2025405231"
    PerfectPush = "2025975197"
    MegaStart   = "2025675230"
    LuckyCharm  = "2026497223"
    RainbowBall = "2025657163"
}
$products = [ordered]@{
    Turbo5      = "3718165483"
    Turbo20     = "3718165489"
    CoinsSmall  = "3718165495"
    CoinsMedium = "3718165497"
    CoinsLarge  = "3718165503"
    CoinsHuge   = "3718165507"
    Boost15     = "3718165511"
    Boost60     = "3718165517"
    ServerStorm = "3718165522"
}

$iconDir = Join-Path $PSScriptRoot "shop-icons"
if (-not (Test-Path $iconDir)) { throw "Can't find the 'shop-icons' folder next to this script ($iconDir)." }

$apiKey = (Read-Host "Open Cloud API key").Trim()
$client = New-Object System.Net.Http.HttpClient
$client.DefaultRequestHeaders.Add("x-api-key", $apiKey)

function Send-Icon($url, $file) {
    for ($attempt = 1; $attempt -le 4; $attempt++) {
        $form = New-Object System.Net.Http.MultipartFormDataContent
        $bytes = [System.IO.File]::ReadAllBytes($file)
        $image = New-Object System.Net.Http.ByteArrayContent(, $bytes)
        $image.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("image/png")
        $form.Add($image, "imageFile", [System.IO.Path]::GetFileName($file))
        $request = New-Object System.Net.Http.HttpRequestMessage((New-Object System.Net.Http.HttpMethod("PATCH")), $url)
        $request.Content = $form
        $response = $client.SendAsync($request).Result
        if ($response.IsSuccessStatusCode) { return }
        $body = $response.Content.ReadAsStringAsync().Result
        if ([int]$response.StatusCode -eq 429) {
            Write-Host "   rate limited, waiting..." -ForegroundColor DarkYellow
            Start-Sleep -Seconds (5 * $attempt)
            continue
        }
        throw "Roblox said $([int]$response.StatusCode): $body"
    }
    throw "Still rate limited, try again in a minute."
}

$failed = 0
function Upload-All($items, $urlBase) {
    foreach ($key in $items.Keys) {
        $file = Join-Path $iconDir "$key.png"
        if (-not (Test-Path $file)) { Write-Host " MISSING $key.png" -ForegroundColor Red; $script:failed++; continue }
        try {
            Send-Icon "$urlBase/$($items[$key])" $file
            Write-Host " OK  $key" -ForegroundColor Green
        } catch {
            Write-Host " FAIL $key : $($_.Exception.Message)" -ForegroundColor Red
            $script:failed++
        }
        Start-Sleep -Milliseconds 800
    }
}

Write-Host "`nGame passes..." -ForegroundColor Cyan
Upload-All $passes "https://apis.roblox.com/game-passes/v1/universes/$universeId/game-passes"
Write-Host "`nDeveloper products..." -ForegroundColor Cyan
Upload-All $products "https://apis.roblox.com/developer-products/v2/universes/$universeId/developer-products"

if ($failed -eq 0) {
    Write-Host "`nAll icons uploaded! They may show as pending until Roblox moderation approves them." -ForegroundColor Green
} else {
    Write-Host "`n$failed icon(s) failed - see the messages above, fix and run again (uploading twice is fine)." -ForegroundColor Yellow
}
Read-Host "`nPress Enter to close"
