buildscript {
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin" && requested.name == "kotlin-gradle-plugin") {
                useVersion("1.8.22")
            }
        }
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion("1.8.22")
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
    project.plugins.withId("com.android.library") {
        val androidExtension = project.extensions.findByName("android")
        if (androidExtension != null) {
            val getNamespace = androidExtension.javaClass.getMethod("getNamespace")
            val setNamespace = androidExtension.javaClass.getMethod("setNamespace", String::class.java)
            if (getNamespace.invoke(androidExtension) == null) {
                val manifestFile = project.file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val manifestText = manifestFile.readText()
                    val matcher = java.util.regex.Pattern.compile("""package="([^"]+)"""").matcher(manifestText)
                    if (matcher.find()) {
                        setNamespace.invoke(androidExtension, matcher.group(1))
                    } else {
                        setNamespace.invoke(androidExtension, "com.example.${project.name.replace("-", "_")}")
                    }
                } else {
                    setNamespace.invoke(androidExtension, "com.example.${project.name.replace("-", "_")}")
                }
            }
        }
    }
}

subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "17"
        }
    }

    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
