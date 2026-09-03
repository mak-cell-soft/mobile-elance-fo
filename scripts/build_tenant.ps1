# PowerShell script to build custom tenant APKs for WoodApp
# Usage: .\scripts\build_tenant.ps1 -TenantId mansour-construction
#        .\scripts\build_tenant.ps1 -TenantId socofeb

param (
    [string]$TenantId = "socofeb",
    [string]$Flavor = "",
    [string]$AppName = "",
    [string]$PackageName = "",
    [string]$PrimaryColor = "",
    [string]$SecondaryColor = "",
    [string]$BaseUrl = "https://acya.site/api/",
    [string]$Target = "lib/main_preprod.dart",
    [string]$BuildMode = "apk",
    [bool]$HasChantierModule = $true
)

# 1. Resolve flavor name (replace hyphens with underscores for Android Gradle compatibility)
$flavorName = if ($Flavor) { $Flavor } else { $TenantId.Replace('-', '_') }

# 2. Automatically load defaults from tenant config.json if available
$tenantConfigPath = "assets\tenants\$TenantId\config.json"
if (Test-Path $tenantConfigPath) {
    try {
        $json = Get-Content $tenantConfigPath -Raw | ConvertFrom-Json
        if (-not $AppName -and $json.appName) { $AppName = $json.appName }
        if (-not $PackageName -and $json.packageName) { $PackageName = $json.packageName }
        if (-not $PrimaryColor -and $json.primaryColor) { $PrimaryColor = $json.primaryColor }
        if (-not $SecondaryColor -and $json.secondaryColor) { $SecondaryColor = $json.secondaryColor }
        if ($json.hasChantierModule -ne $null) { $HasChantierModule = [bool]$json.hasChantierModule }
    } catch {
        Write-Warning "Could not parse tenant config at $tenantConfigPath"
    }
}

# 3. Fallback defaults
if (-not $AppName) { $AppName = $TenantId }
if (-not $PackageName) { $PackageName = "com.$($TenantId.Replace('-', '')).woodapp" }
if (-not $PrimaryColor) { $PrimaryColor = "#1B4332" }
if (-not $SecondaryColor) { $SecondaryColor = "#2D6A4F" }

Write-Host "==========================================" -ForegroundColor Green
Write-Host "Building Multi-Tenant App: $AppName ($TenantId)" -ForegroundColor Green
Write-Host "Gradle Flavor: $flavorName" -ForegroundColor Yellow
Write-Host "Target Entrypoint: $Target" -ForegroundColor Yellow
Write-Host "Package ID: $PackageName" -ForegroundColor Yellow
Write-Host "Primary Color: $PrimaryColor" -ForegroundColor Yellow
Write-Host "Chantier Module: $HasChantierModule" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Green

flutter build $BuildMode `
    -t $Target `
    --flavor=$flavorName `
    --dart-define=TENANT_ID=$TenantId `
    --dart-define=APP_NAME=$AppName `
    --dart-define=PACKAGE_NAME=$PackageName `
    --dart-define=PRIMARY_COLOR=$PrimaryColor `
    --dart-define=SECONDARY_COLOR=$SecondaryColor `
    --dart-define=BASE_URL=$BaseUrl `
    --dart-define=ASSETS_PATH="assets/tenants/$TenantId/" `
    --dart-define=HAS_CHANTIER_MODULE=$HasChantierModule

if ($LASTEXITCODE -eq 0) {
    $dateStr = Get-Date -Format "dd_MM_yyyy"
    $sourceApk = "build\app\outputs\flutter-apk\app-$flavorName-release.apk"
    $datedApk = "build\app\outputs\flutter-apk\app-$TenantId-release-$dateStr.apk"
    
    if (Test-Path $sourceApk) {
        Copy-Item $sourceApk $datedApk -Force
        Write-Host "SUCCESS! Created date-stamped release APK: $datedApk" -ForegroundColor Green
    } else {
        Write-Host "SUCCESS! Built APK for $TenantId at build/app/outputs/flutter-apk/" -ForegroundColor Green
    }
} else {
    Write-Host "BUILD FAILED for $TenantId" -ForegroundColor Red
}
