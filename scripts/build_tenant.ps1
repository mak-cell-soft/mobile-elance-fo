# PowerShell script to build custom tenant APKs for WoodApp
# Usage: .\scripts\build_tenant.ps1 -TenantId socofeb -AppName socofeb -PackageName com.socofeb.woodapp -PrimaryColor "#1B4332"

param (
    [string]$TenantId = "socofeb",
    [string]$AppName = "socofeb",
    [string]$PackageName = "com.socofeb.woodapp",
    [string]$PrimaryColor = "#1B4332",
    [string]$SecondaryColor = "#2D6A4F",
    [string]$BaseUrl = "https://acya.site/api/",
    [string]$Target = "lib/main_preprod.dart",
    [string]$BuildMode = "apk",
    [bool]$HasChantierModule = $true
)

Write-Host "==========================================" -ForegroundColor Green
Write-Host "Building Multi-Tenant App: $AppName ($TenantId)" -ForegroundColor Green
Write-Host "Target Entrypoint: $Target" -ForegroundColor Yellow
Write-Host "Package ID: $PackageName" -ForegroundColor Yellow
Write-Host "Primary Color: $PrimaryColor" -ForegroundColor Yellow
Write-Host "Chantier Module: $HasChantierModule" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Green

flutter build $BuildMode `
    -t $Target `
    --flavor=$TenantId `
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
    $sourceApk = "build\app\outputs\flutter-apk\app-$TenantId-release.apk"
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
