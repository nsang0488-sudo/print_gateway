allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://repo1.maven.org/maven2/") }
    }
    buildscript {
        configurations.all {
            resolutionStrategy {
                force("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
            }
        }
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
}

subprojects {
    plugins.withId("com.android.library") {
        val android = extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
        if (android != null && android.namespace == null) {
            val manifestFile = file("src/main/AndroidManifest.xml")
            var pkgName: String? = null
            if (manifestFile.exists()) {
                val match = Regex("""package="([^"]+)"""").find(manifestFile.readText())
                if (match != null) {
                    pkgName = match.groupValues[1]
                }
            }
            android.namespace = pkgName ?: "com.example.${project.name.replace('-', '_')}"
        }
    }
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        val target = try { android?.compileOptions?.sourceCompatibility?.toString() } catch (_: Exception) { null } ?: "17"
        kotlinOptions {
            jvmTarget = target
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
