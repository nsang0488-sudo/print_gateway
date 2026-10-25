allprojects {
    repositories {
        google()
        mavenCentral()
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
    val configureNamespace: (Project) -> Unit = { p ->
        if (p.plugins.hasPlugin("com.android.library") || p.plugins.hasPlugin("com.android.application")) {
            val androidExt = p.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            if (androidExt != null && androidExt.namespace == null) {
                androidExt.namespace = "com.example.plugin.${p.name.replace('-', '_')}"
            }
        }
    }

    if (state.executed) {
        configureNamespace(this)
    } else {
        afterEvaluate {
            configureNamespace(this)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
