import mill._
import mill.scalalib._

object hello extends ScalaModule {
  def scalaVersion = "3.4.2"

  def mainClass = Some("Main")
}
