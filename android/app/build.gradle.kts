plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val astroReleaseSigning = listOf(
    "ASTRO_ANDROID_KEYSTORE",
    "ASTRO_ANDROID_STORE_PASSWORD",
    "ASTRO_ANDROID_KEY_ALIAS",
    "ASTRO_ANDROID_KEY_PASSWORD",
).associateWith { providers.environmentVariable(it).orNull?.takeIf(String::isNotBlank) }
val astroReleaseSigningConfigured = astroReleaseSigning.values.all { it != null }
if (!astroReleaseSigningConfigured && astroReleaseSigning.values.any { it != null }) {
    throw GradleException("Set all four ASTRO_ANDROID_* signing variables for a signed release.")
}

android {
    namespace = "com.sisterswithmirrors.astro_worker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sisterswithmirrors.astroworker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (astroReleaseSigningConfigured) {
            create("astroRelease") {
                storeFile = file(astroReleaseSigning.getValue("ASTRO_ANDROID_KEYSTORE")!!)
                storePassword = astroReleaseSigning.getValue("ASTRO_ANDROID_STORE_PASSWORD")
                keyAlias = astroReleaseSigning.getValue("ASTRO_ANDROID_KEY_ALIAS")
                keyPassword = astroReleaseSigning.getValue("ASTRO_ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (astroReleaseSigningConfigured) "astroRelease" else "debug"
            )
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
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20250517")
}
