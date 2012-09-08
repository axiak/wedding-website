import sbt._
import Keys._
import PlayProject._

object ApplicationBuild extends Build {

    val appName         = "weddingBackend"
    val appVersion      = "1.0-SNAPSHOT"

    val appDependencies = Seq(
      // Add your project dependencies here,
      "mysql" % "mysql-connector-java" % "5.1.18",
      "com.stripe" %% "stripe-scala" % "1.1.2"
    )

    val main = PlayProject(appName, appVersion, appDependencies, mainLang = SCALA).settings(
      // Add your own project settings here      
    )

}
