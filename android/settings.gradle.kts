pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        properties.getProperty("flutter.sdk")
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    // PREFER_SETTINGS ensures google() and mavenCentral() take priority
    // over Flutter plugin's mirror repo for AndroidX/Kotlin dependencies.
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)

    repositories {
        google()
        mavenCentral()
        // Official Flutter engine artifacts (fallback if FLUTTER_STORAGE_BASE_URL mirror fails)
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        // Chinese Flutter mirror (for Flutter engine artifacts if using mirror)
        maven { url = uri("https://storage.flutter-io.cn/download.flutter.io") }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.2" apply false
    id("org.jetbrains.kotlin.android") version "2.3.21" apply false
}

rootProject.name = "LuckySpin"
include(":app")