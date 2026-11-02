import java.util.Base64

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// Debug builds stay out of production analytics unless explicitly opted in.
val unioDartDefines = (project.findProperty("dart-defines") as? String)
    ?.split(',')?.mapNotNull {
        runCatching { String(Base64.getDecoder().decode(it)) }.getOrNull()
    }.orEmpty()

android {
    namespace = "com.example.vgspu_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    buildFeatures { buildConfig = true }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.example.vgspu_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        buildConfigField("boolean", "MYTRACKER_DEBUG", ("MYTRACKER_DEBUG=true" in unioDartDefines).toString())
        buildConfigField("boolean", "MYTRACKER_ENABLED", ("MYTRACKER_ENABLED=false" !in unioDartDefines).toString())
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Pinned version from the supplied androidsdk; no files under build/ required.
    implementation("com.my.tracker:mytracker-sdk:3.5.0") {
        exclude(group = "com.android.billingclient", module = "billing")
        exclude(group = "com.google.android.gms", module = "play-services-ads-identifier")
    }
}

flutter {
    source = "../.."
}
