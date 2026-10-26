buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    configurations.all {
        resolutionStrategy {
            force("org.jetbrains.kotlin:kotlin-stdlib:1.9.24")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.24")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.24")
            force("org.jetbrains.kotlin:kotlin-stdlib-common:1.9.24")
            eachDependency {
                if (requested.group == "org.jetbrains.kotlin") {
                    useVersion("1.9.24")
                }
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
        val androidExt = extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
        if (androidExt != null && androidExt.namespace == null) {
            androidExt.namespace = "com.example.plugin.${project.name.replace('-', '_')}"
        }
    }
    plugins.withId("com.android.application") {
        val androidExt = extensions.findByType(com.android.build.gradle.AppExtension::class.java)
        if (androidExt != null && androidExt.namespace == null) {
            androidExt.namespace = "com.example.plugin.${project.name.replace('-', '_')}"
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
