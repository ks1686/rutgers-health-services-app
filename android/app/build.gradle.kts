import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. The keystore and key.properties stay out of the repo
// (the repo is public). CI has no key, so a CI release build stays
// debug-signed and is not the file anyone installs. A local release build
// without the key fails rather than silently using the debug key.
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}
val hasReleaseKey = keyPropertiesFile.exists()

android {
    namespace = "org.rutgers.cwc.cwc_health_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
                storePassword = keyProperties.getProperty("storePassword")
                storeFile = file(keyProperties.getProperty("storeFile"))
            }
        }
    }

    defaultConfig {
        applicationId = "org.rutgers.cwc.cwc_health_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // local_auth needs Android SDK 24+. Flutter 3.47 already defaults to 24.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Maps SDK key for FIND-4. Empty → Dart uses OSM. Never commit a real key.
        val mapsApiKey =
            (project.findProperty("GOOGLE_MAPS_API_KEY") as String?)
                ?: System.getenv("GOOGLE_MAPS_API_KEY")
                ?: ""
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            if (hasReleaseKey) {
                signingConfig = signingConfigs.getByName("release")
            } else if (System.getenv("CI") == "true") {
                // GitHub Actions has no upload key. The artifact it uploads is
                // a demo compile, not the installable v1 file.
                signingConfig = signingConfigs.getByName("debug")
            } else {
                throw GradleException(
                    "Release signing key missing. android/key.properties is " +
                        "gitignored. See docs/engineering/release-signing.md.",
                )
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // LaunchTheme parents Theme.AppCompat so the biometric prompt can show.
    implementation("androidx.appcompat:appcompat:1.8.0")
}
