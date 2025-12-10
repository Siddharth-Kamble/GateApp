import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete

allprojects {
    // KEEP EMPTY – required because FAIL_ON_PROJECT_REPOS is enabled
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// -------------------------
// Buildscript FIX
// -------------------------
buildscript {

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.google.gms:google-services:4.4.1")
    }
}
