allprojects {
    repositories {
        google()
        mavenLocal()
        mavenCentral()
        // Resolve vendor AARs published by the wise_apartment plugin to its local maven-repo.
        // The plugin's $projectDir lives in pub-cache; we resolve it dynamically so the path
        // is correct regardless of the pub-cache hash suffix.
        maven {
            val wiseDir = rootProject.findProject(":wise_apartment")?.projectDir
            url = uri(wiseDir?.resolve("maven-repo")?.absolutePath ?: "$rootDir/maven-repo")
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Automatically publish wise_apartment vendor AARs into its local maven-repo
// before every app build. Runs on every machine, CI, and after flutter pub get.
gradle.projectsEvaluated {
    val publishTask = tasks.findByPath(":wise_apartment:publish")
    listOf("preBuild", "preDebugBuild", "preReleaseBuild").forEach { taskName ->
        tasks.findByPath(":app:$taskName")?.dependsOn(publishTask)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
