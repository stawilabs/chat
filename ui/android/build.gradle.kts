// Plugin versions are managed in settings.gradle.kts


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

// Fix for older Flutter plugins that don't have namespace defined
subprojects {
    plugins.withId("com.android.library") {
        extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
            if (namespace == null) {
                // Use project name to derive namespace for plugins without one
                namespace = when (project.name) {
                    "flutter_app_badger" -> "io.github.nickcats.flutter_app_badger"
                    else -> "com.example.${project.name.replace("-", "_").replace(".", "_")}"
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
