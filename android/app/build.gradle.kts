// android/app/build.gradle.kts

import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // ✅ same as google-services.json ka package_name?
    namespace = "onedlfs.com"

    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        // ✅ yahi value google-services.json me "package_name" hai
        applicationId = "onedlfs.com"

        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
        freeCompilerArgs += "-Xjvm-default=all"
    }

    buildTypes {
        // 🔹 DEBUG build (jo tum flutter run se chalate ho)
        getByName("debug") {
            // Yahi important hai: resource shrinking OFF
            isMinifyEnabled = false
            isShrinkResources = false
        }

        // 🔹 RELEASE build
        getByName("release") {
            // Abhi ke liye release me bhi shrinking band
            isMinifyEnabled = false
            isShrinkResources = false

            // Test purpose ke liye debug ke signature se sign
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

flutter {
    source = "../.."
}
