import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}


val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "org.stawi.chat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "org.stawi.chat"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Required by flutter_appauth (transitive dep of antinvestor_auth_runtime).
        // The OAuth redirect URI must use this scheme; matches applicationId.
        manifestPlaceholders["appAuthRedirectScheme"] = "org.stawi.chat"
    }

    if (keystorePropertiesFile.exists()) {
        signingConfigs {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }

    bundle {
        abi {
            // Exclude x86_64 (emulator-only) from production builds
            // Users will only download the APK for their device architecture
            enableSplit = true
        }
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
    }
}

// Fail loudly if a release build is requested without signing material, instead
// of silently producing an unsigned / debug-signed release artifact (which the
// Play Store rejects or which ships updatable by anyone holding the debug key).
gradle.taskGraph.whenReady {
    val buildingRelease = allTasks.any { it.name.contains("Release", ignoreCase = true) }
    if (buildingRelease && !keystorePropertiesFile.exists()) {
        throw GradleException(
            "Release build requires android/key.properties with the signing keystore. " +
                "Refusing to produce an unsigned/debug-signed release artifact.",
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Import the Firebase BoM
      implementation(platform("com.google.firebase:firebase-bom:34.8.0"))

      // When using the BoM, don't specify versions in Firebase dependencies
      implementation("com.google.firebase:firebase-analytics")


      // Add the dependencies for any other desired Firebase products
      // https://firebase.google.com/docs/android/setup#available-libraries
}
