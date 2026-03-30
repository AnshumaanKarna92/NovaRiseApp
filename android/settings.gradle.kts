pluginManagement {
    val flutterSdkPath = "C:/Users/ANSHUM~1/flutter"

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.3" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
project(":app").projectDir = file("C:/Users/ANSHUM~1/nova_rise_app/android/app")
