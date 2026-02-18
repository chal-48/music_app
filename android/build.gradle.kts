buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // ต้องตรงกับเวอร์ชัน Gradle ของคุณ
        classpath("com.android.tools.build:gradle:8.1.0") 
        
        // Firebase
        classpath("com.google.gms:google-services:4.4.1") 
    }
}

// ลบ allprojects ทิ้งไปเลย
// ลบ task clean ทิ้งไปเลยก็ได้ (ถ้าไม่ได้ใช้) หรือจะเก็บไว้ก็ได้ถ้ามันไม่แดง
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}