plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ Firebase support
}

android {
    namespace = "com.example.zero"
    compileSdk = 35
    ndkVersion = "27.0.12077973" // ✅ Required by Firebase and other plugins

    defaultConfig {
        applicationId = "com.example.zero"
        minSdk = 23 // ✅ Firebase requires at least 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            // ✅ Keep debug signing for testing (replace with real keystore for production)
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // ✅ Ensure Java and Kotlin use the same JVM version
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    // ✅ Avoid duplicate meta-data errors
    packaging {
        resources.excludes.add("META-INF/*")
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib")

    // ✅ Firebase dependencies (use BOM for version management)
    implementation(platform("com.google.firebase:firebase-bom:33.4.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-storage")
}