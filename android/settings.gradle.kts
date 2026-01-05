pluginManagement {

    val localPropertiesFile = settingsDir.resolve("local.properties")

    val flutterSdkPath: String = run {
        val properties = java.util.Properties()
        localPropertiesFile.inputStream().use { properties.load(it) }

        val flutterSdk = properties.getProperty("flutter.sdk")
        requireNotNull(flutterSdk) { "flutter.sdk not set in local.properties" }
        flutterSdk
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()

        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        maven { url = uri("$flutterSdkPath/bin/cache/artifacts/engine") }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.1" apply false
}

include(":app")

dependencyResolutionManagement {
    // FIXED: Required by Flutter plugin (prevents crashes)
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)

    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }

        val props = java.util.Properties()
        settingsDir.resolve("local.properties").inputStream().use { props.load(it) }
        val flutterSdk = props.getProperty("flutter.sdk")
        if (flutterSdk != null) {
            maven { url = uri("$flutterSdk/bin/cache/artifacts/engine") }
        }
    }
}
