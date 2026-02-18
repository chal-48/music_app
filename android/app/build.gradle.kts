plugins {
    id("com.android.application")
    id("kotlin-android") // หรือ org.jetbrains.kotlin.android
    id("dev.flutter.flutter-gradle-plugin")
    // ✅ Plugin ของ Google Services (ต้องมี)
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.music_app" // หรือชื่อที่คุณตั้งใหม่
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8 // แนะนำให้ใช้ 1.8 สำหรับ Flutter ทั่วไป
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        // ⚠️ ต้องตรงกับใน Firebase Console เป๊ะๆ
        applicationId = "com.example.music_app" 
        
        // กำหนด minSdk เป็น 21 หรือ 23 เพื่อรองรับ Google Sign In
        minSdk = 23 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// ✅ ส่วน dependencies (วางไว้ล่างสุดแบบนี้ถูกต้องแล้วใน Kotlin DSL)
dependencies {
    // Import Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.9.0"))
    
    // ใส่ Firebase Authentication เพิ่ม (แนะนำให้ใส่)
    implementation("com.google.firebase:firebase-auth")
}