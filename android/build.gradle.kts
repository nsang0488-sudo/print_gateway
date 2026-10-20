allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://repo1.maven.org/maven2/") }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")

    // Fix missing namespace in older Flutter plugins (e.g., flutter_usb_printer) for AGP 8+
    plugins.withId("com.android.library") {
        val androidExt = extensions.findByName("android") as? com.android.build.gradle.LibraryExtension
        if (androidExt != null && androidExt.namespace == null) {
            val manifestFile = file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val manifestXml = manifestFile.readText()
                val pkgMatch = Regex("""package\s*=\s*"([^"]+)"""").find(manifestXml)
                if (pkgMatch != null) {
                    androidExt.namespace = pkgMatch.groupValues[1]
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
