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
    [bool]$HasChantierModule = $true,
    [Nullable[bool]]$HasProductionModule = $null
)

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------
function Find-AaptTool {
    $cmd = Get-Command aapt -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $cmdExe = Get-Command aapt.exe -ErrorAction SilentlyContinue
    if ($cmdExe) { return $cmdExe.Source }

    $candidates = @()
    if ($env:ANDROID_HOME) { $candidates += "$env:ANDROID_HOME\build-tools" }
    if ($env:ANDROID_SDK_ROOT) { $candidates += "$env:ANDROID_SDK_ROOT\build-tools" }
    if ($env:LOCALAPPDATA) { $candidates += "$env:LOCALAPPDATA\Android\Sdk\build-tools" }

    foreach ($dir in $candidates) {
        if (Test-Path $dir) {
            $found = Get-ChildItem -Path $dir -Filter "aapt.exe" -Recurse -ErrorAction SilentlyContinue |
                Sort-Object FullName -Descending |
                Select-Object -First 1
            if ($found) { return $found.FullName }
        }
    }
    return $null
}

function Verify-ApkPackageId {
    param (
        [string]$ApkPath,
        [string]$ExpectedPackage
    )

    if (-not (Test-Path $ApkPath)) {
        Write-Host "VERIFICATION FAILED: Source APK not found at $ApkPath" -ForegroundColor Red
        return $false
    }

    $aaptTool = Find-AaptTool
    if (-not $aaptTool -or -not (Test-Path $aaptTool)) {
        Write-Host "VERIFICATION FAILED: 'aapt' tool was not found in PATH or Android SDK build-tools." -ForegroundColor Red
        Write-Host "Cannot verify APK package identity without Android SDK tools." -ForegroundColor Red
        return $false
    }

    Write-Host "Running APK verification with: $aaptTool" -ForegroundColor Cyan
    $badging = & $aaptTool dump badging $ApkPath 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "VERIFICATION FAILED: 'aapt dump badging' exited with error code $LASTEXITCODE." -ForegroundColor Red
        return $false
    }

    $actualPackage = $null
    foreach ($line in $badging) {
        if ($line -match "package:\s+name='([^']+)'") {
            $actualPackage = $matches[1]
            break
        }
    }

    if (-not $actualPackage) {
        Write-Host "VERIFICATION FAILED: Could not extract package name from APK badging." -ForegroundColor Red
        return $false
    }

    Write-Host "APK Registered Package ID: $actualPackage" -ForegroundColor Cyan
    Write-Host "Expected Package ID:        $ExpectedPackage" -ForegroundColor Cyan

    if ($actualPackage -ne $ExpectedPackage) {
        Write-Host "VERIFICATION FAILED: Package mismatch! Expected '$ExpectedPackage', found '$actualPackage'." -ForegroundColor Red
        return $false
    }

    Write-Host "VERIFICATION PASSED: Package ID matches expected '$ExpectedPackage'." -ForegroundColor Green
    return $true
}

# -----------------------------------------------------------------------------
# 1. Resolve Flavor Name
# -----------------------------------------------------------------------------
$flavorName = if ($Flavor) { $Flavor } else { $TenantId.Replace('-', '_') }

# -----------------------------------------------------------------------------
# 2. Resolve Tenant Configuration Deterministically
# -----------------------------------------------------------------------------
$activeConfigPath = "assets\tenant_config.json"
$tenantSourceDir = "assets\tenants\$TenantId"
$tenantSourceConfigPath = Join-Path $tenantSourceDir "config.json"

$resolvedSourceConfig = $null

if (Test-Path $tenantSourceConfigPath) {
    $resolvedSourceConfig = $tenantSourceConfigPath
} elseif (Test-Path $activeConfigPath) {
    try {
        $existingActive = Get-Content $activeConfigPath -Raw | ConvertFrom-Json
        if ($existingActive.tenantId -eq $TenantId) {
            $resolvedSourceConfig = $activeConfigPath
        }
    } catch {}
}

# Fail immediately if no configuration can be established for the requested tenant
if (-not $resolvedSourceConfig) {
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "BUILD REJECTED: Configuration Missing" -ForegroundColor Red
    Write-Host "No configuration found for tenant '$TenantId' at:" -ForegroundColor Red
    Write-Host "  $tenantSourceConfigPath" -ForegroundColor Yellow
    Write-Host "Refusing to build to prevent fallback or cross-tenant contamination." -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
    exit 1
}

try {
    $json = Get-Content $resolvedSourceConfig -Raw | ConvertFrom-Json
    if (-not $AppName -and $json.appName) { $AppName = $json.appName }
    if (-not $PrimaryColor -and $json.primaryColor) { $PrimaryColor = $json.primaryColor }
    if (-not $SecondaryColor -and $json.secondaryColor) { $SecondaryColor = $json.secondaryColor }
    if ($json.hasChantierModule -ne $null) {
        $HasChantierModule = [bool]$json.hasChantierModule
    } elseif ($json.hasChantiers -ne $null) {
        $HasChantierModule = [bool]$json.hasChantiers
    } elseif ($json.isManagingConstructions -ne $null) {
        $HasChantierModule = [bool]$json.isManagingConstructions
    }

    if ($HasProductionModule -eq $null) {
        if ($json.hasProductionModule -ne $null) {
            $HasProductionModule = [bool]$json.hasProductionModule
        } elseif ($json.hasProduction -ne $null) {
            $HasProductionModule = [bool]$json.hasProduction
        } elseif ($json.isManagingProduction -ne $null) {
            $HasProductionModule = [bool]$json.isManagingProduction
        } else {
            # Do not silently default missing authoritative production configuration to enabled
            $HasProductionModule = $false
        }
    }
    if ($json.environment -eq "production" -and $Target -eq "lib/main_preprod.dart") {
        $Target = "lib/main_production.dart"
    }
} catch {
    Write-Host "BUILD REJECTED: Could not parse tenant configuration at $resolvedSourceConfig" -ForegroundColor Red
    exit 1
}

# -----------------------------------------------------------------------------
# 3. Apply Defaults with Shared Production Package ID
# -----------------------------------------------------------------------------
if (-not $AppName) { $AppName = $TenantId }

# Derive tenant-specific package ID to allow multi-tenant coexistence and maintain update continuity
$isDevelopment = ($flavorName -eq "development" -or $Target -like "*development*")
if ($isDevelopment) {
    if (-not $PackageName) { $PackageName = "com.example.woodapp" }
} else {
    if (-not $PackageName -and $json.packageName) { $PackageName = $json.packageName }
    if (-not $PackageName) {
        $alphanumericSlug = ($TenantId -replace '[^a-zA-Z0-9]', '').ToLower()
        $PackageName = "com.$alphanumericSlug.woodapp"
    }
}
if (-not $PrimaryColor) { $PrimaryColor = "#1B4332" }
if (-not $SecondaryColor) { $SecondaryColor = "#2D6A4F" }

# Extract pubspec version and build number for artifact naming
$versionName = "1.0.0"
$buildNumber = "1"
if (Test-Path "pubspec.yaml") {
    $pubspecContent = Get-Content "pubspec.yaml" -Raw
    if ($pubspecContent -match "(?m)^version:\s*([0-9.]+)\+?([0-9]*)") {
        if ($matches[1]) { $versionName = $matches[1] }
        if ($matches[2]) { $buildNumber = $matches[2] }
    }
}

# Canonical artifact naming matching CI/CD standard: APP_NAME-VERSION-BUILD_NUMBER.apk
$appNameSafe = ($AppName -replace '[^a-zA-Z0-9_-]', '_').ToUpper()
if (-not $appNameSafe) {
    $appNameSafe = ($TenantId -replace '[^a-zA-Z0-9_-]', '_').ToUpper()
}
$canonicalApkName = "$appNameSafe-$versionName-$buildNumber.apk"

# Expected package ID for post-build verification (strictly derived from tenant configuration)
$expectedPackageId = $PackageName

Write-Host "==========================================" -ForegroundColor Green
Write-Host "Building Multi-Tenant App: $AppName ($TenantId)" -ForegroundColor Green
Write-Host "Gradle Flavor:      $flavorName" -ForegroundColor Yellow
Write-Host "Target Entrypoint:  $Target" -ForegroundColor Yellow
Write-Host "Package ID:         $PackageName" -ForegroundColor Yellow
Write-Host "Version:            $versionName+$buildNumber" -ForegroundColor Yellow
Write-Host "Artifact Target:    $canonicalApkName" -ForegroundColor Yellow
Write-Host "Primary Color:      $PrimaryColor" -ForegroundColor Yellow
Write-Host "Chantier Module:    $HasChantierModule" -ForegroundColor Yellow
Write-Host "Production Module:  $HasProductionModule" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 4. Safe Active Configuration Staging
# -----------------------------------------------------------------------------
$stagedBackupPath = $null
$activeConfigModified = $false

if (Test-Path $activeConfigPath) {
    # Backup existing active config so developer working tree is restored after build
    $stagedBackupPath = [System.IO.Path]::GetTempFileName()
    Copy-Item $activeConfigPath $stagedBackupPath -Force
    Copy-Item $resolvedSourceConfig $activeConfigPath -Force
    $activeConfigModified = $true
    Write-Host "Staged $TenantId config to $activeConfigPath (backed up active config)" -ForegroundColor DarkGray
} else {
    Copy-Item $resolvedSourceConfig $activeConfigPath -Force
    $activeConfigModified = $true
    Write-Host "Staged $TenantId config to $activeConfigPath" -ForegroundColor DarkGray
}

# -----------------------------------------------------------------------------
# 5. Build Execution with Scoped Environment Variables
# -----------------------------------------------------------------------------
# Clean up any pre-existing intermediate APK to prevent stale artifact reuse (REV-03)
$sourceApk = "build\app\outputs\flutter-apk\app-$flavorName-release.apk"
if (Test-Path $sourceApk) {
    Remove-Item $sourceApk -Force -ErrorAction SilentlyContinue
}
$canonicalIntermediateApk = Join-Path "build\app\outputs\flutter-apk" $canonicalApkName
if (Test-Path $canonicalIntermediateApk) {
    Remove-Item $canonicalIntermediateApk -Force -ErrorAction SilentlyContinue
}

# Save prior environment variables to restore them in finally block
$origFlavorEnv = $env:FLAVOR_NAME
$origPackageEnv = $env:PACKAGE_NAME
$origAppNameEnv = $env:APP_NAME

$buildSuccess = $false

try {
    # Export environment variables so Gradle dynamic productFlavors and customAppId resolve correctly
    $env:FLAVOR_NAME = $flavorName
    $env:PACKAGE_NAME = $PackageName
    $env:APP_NAME = $AppName

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
        --dart-define=HAS_CHANTIER_MODULE=$HasChantierModule `
        --dart-define=HAS_PRODUCTION_MODULE=$HasProductionModule

    $buildSuccess = ($LASTEXITCODE -eq 0)
} finally {
    # Restore environment variables
    $env:FLAVOR_NAME = $origFlavorEnv
    $env:PACKAGE_NAME = $origPackageEnv
    $env:APP_NAME = $origAppNameEnv

    # Restore or clean up staged active configuration to preserve working-tree integrity
    if ($stagedBackupPath -and (Test-Path $stagedBackupPath)) {
        Copy-Item $stagedBackupPath $activeConfigPath -Force
        Remove-Item $stagedBackupPath -Force -ErrorAction SilentlyContinue
        Write-Host "Restored previous active configuration to $activeConfigPath" -ForegroundColor DarkGray
    } elseif ($activeConfigModified -and -not $stagedBackupPath -and ($resolvedSourceConfig -ne $activeConfigPath)) {
        Remove-Item $activeConfigPath -Force -ErrorAction SilentlyContinue
    }
}

# -----------------------------------------------------------------------------
# 6. Verification & Artifact Distribution
# -----------------------------------------------------------------------------
if ($buildSuccess) {
    $dateStr = Get-Date -Format "dd_MM_yyyy"
    $sourceApk = "build\app\outputs\flutter-apk\app-$flavorName-release.apk"
    $datedApkName = "app-$TenantId-release-$dateStr.apk"
    $targetDir = "assets\apks_tenants"
    $canonicalTargetApk = Join-Path $targetDir $canonicalApkName
    $datedTargetApk = Join-Path $targetDir $datedApkName

    if (-not (Test-Path $sourceApk)) {
        Write-Host "BUILD FAILED: Expected release APK was not found at: $sourceApk" -ForegroundColor Red
        exit 1
    }

    # Step E: Verify package identity before distribution
    $verificationPassed = Verify-ApkPackageId -ApkPath $sourceApk -ExpectedPackage $expectedPackageId
    if (-not $verificationPassed) {
        Write-Host "BUILD FAILED: APK package verification failed for $TenantId. Artifact will not be distributed." -ForegroundColor Red
        exit 1
    }

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    # Publish both canonical and date-stamped artifacts
    Copy-Item $sourceApk (Join-Path "build\app\outputs\flutter-apk" $canonicalApkName) -Force
    Copy-Item $sourceApk $canonicalTargetApk -Force
    Copy-Item $sourceApk $datedTargetApk -Force

    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "SUCCESS! Verified APK created for $TenantId" -ForegroundColor Green
    Write-Host "Canonical Artifact: $canonicalTargetApk" -ForegroundColor Green
    Write-Host "Dated Artifact:     $datedTargetApk" -ForegroundColor Green
    Write-Host "Package ID:         $expectedPackageId (Verified)" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
} else {
    Write-Host "BUILD FAILED for $TenantId (flutter build exited with error)" -ForegroundColor Red
    exit 1
}
