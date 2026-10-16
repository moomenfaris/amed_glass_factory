import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun prop(name: String): String = keystoreProperties.getProperty(name)?.trim().orEmpty()

val releaseStoreFilePath = prop("storeFile")
val releaseStoreFile = if (releaseStoreFilePath.isNotEmpty()) rootProject.file(releaseStoreFilePath) else null
val hasReleaseSigning =
    prop("keyAlias").isNotEmpty() &&
        prop("keyPassword").isNotEmpty() &&
        prop("storePassword").isNotEmpty() &&
        releaseStoreFile?.exists() == true

if (!hasReleaseSigning) {
    logger.warn(
        "Release signing is not fully configured. Falling back to debug signing. " +
            "Create android/key.properties and provide a valid keystore for production builds.",
    )
}

android {
    namespace = "com.moomen.glassamed"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.moomen.glassamed"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                keyAlias = prop("keyAlias")
                keyPassword = prop("keyPassword")
                storeFile = releaseStoreFile
                storePassword = prop("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // For store submission, release must be signed with a real release keystore.
            signingConfig =
                if (hasReleaseSigning) signingConfigs.getByName("release")
                else signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
