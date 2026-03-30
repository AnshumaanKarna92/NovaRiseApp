plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    kotlin("android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    layout.buildDirectory.set(file("C:/Users/ANSHUM~1/nova_rise_app/build/app"))
    
    namespace = "com.example.nova_rise_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"
    
    // Debug task to verify redirection
    tasks.register("printBuildDir") {
        doFirst {
            println("Build dir is: ${project.layout.buildDirectory.get()}")
        }
    }
    
    // Redirect build outputs to a space-free public folder
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.nova_rise_app"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    dependencies {
        implementation("androidx.appcompat:appcompat:1.6.1")
    }
}

flutter {
    source = "S:/"
}
