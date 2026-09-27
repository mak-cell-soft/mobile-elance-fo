plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.woodapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        val customAppId = (project.findProperty("APPLICATION_ID") as? String) ?: System.getenv("PACKAGE_NAME")
        val customAppName = (project.findProperty("APP_NAME") as? String) ?: System.getenv("APP_NAME")

        applicationId = customAppId ?: "com.example.woodapp"
        resValue("string", "app_name", customAppName ?: "WoodApp")
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keystorePath = System.getenv("KEYSTORE_PATH") ?: (project.findProperty("KEYSTORE_PATH") as? String)
            if (!keystorePath.isNullOrBlank() && file(keystorePath).exists()) {
                storeFile = file(keystorePath)
                storePassword = System.getenv("KEYSTORE_PASSWORD") ?: (project.findProperty("KEYSTORE_PASSWORD") as? String)
                keyAlias = System.getenv("KEY_ALIAS") ?: (project.findProperty("KEY_ALIAS") as? String)
                keyPassword = System.getenv("KEY_PASSWORD") ?: (project.findProperty("KEY_PASSWORD") as? String)
            }
        }
    }

    flavorDimensions += "tenant"

    val customFlavor = (project.findProperty("FLAVOR_NAME") as? String) ?: System.getenv("FLAVOR_NAME")
    val customAppId = (project.findProperty("APPLICATION_ID") as? String) ?: System.getenv("PACKAGE_NAME")
    val customAppName = (project.findProperty("APP_NAME") as? String) ?: System.getenv("APP_NAME")

    productFlavors {
        create("development") {
            dimension = "tenant"
            applicationId = "com.example.woodapp"
            resValue("string", "app_name", "WoodApp")
        }
        create("socofeb") {
            dimension = "tenant"
            applicationId = if (!customAppId.isNullOrBlank() && (customFlavor == "socofeb" || customFlavor.isNullOrBlank())) customAppId else "com.socofeb.woodapp"
            resValue("string", "app_name", if (!customAppName.isNullOrBlank() && (customFlavor == "socofeb" || customFlavor.isNullOrBlank())) customAppName else "socofeb")
        }
        create("mansour_construction") {
            dimension = "tenant"
            applicationId = if (!customAppId.isNullOrBlank() && customFlavor == "mansour_construction") customAppId else "com.mansourconstruction.woodapp"
            resValue("string", "app_name", if (!customAppName.isNullOrBlank() && customFlavor == "mansour_construction") customAppName else "Mansour Construction")
        }

        if (!customFlavor.isNullOrBlank() && customFlavor != "development" && customFlavor != "socofeb" && customFlavor != "mansour_construction") {
            create(customFlavor) {
                dimension = "tenant"
                applicationId = customAppId ?: "com.$customFlavor.woodapp"
                resValue("string", "app_name", customAppName ?: customFlavor)
            }
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.getByName("release")
            val isCi = System.getenv("CI") == "true" || System.getenv("GITHUB_ACTIONS") == "true"

            if (releaseSigning.storeFile != null && releaseSigning.storeFile!!.exists()) {
                signingConfig = releaseSigning
            } else if (isCi) {
                throw org.gradle.api.GradleException(
                    "Release signing keystore is missing in CI environment. Release builds in CI must be signed with a production keystore and cannot fall back to debug signing."
                )
            } else {
                // Local developer workstation fallback: allow running flutter run --release locally without production keys
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
