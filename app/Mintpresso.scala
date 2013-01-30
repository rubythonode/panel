package com.mintpresso

import play.api._
import play.api.i18n.Messages
import play.api.data.Forms._
import play.api.data._
import play.api.Play.current
import play.api.libs._
import play.api.libs.ws._
import play.api.cache._
import play.api.libs.json._
import play.api.libs.iteratee._
import scala.concurrent.stm._
import scala.concurrent._

object MintpressoCore {
  val server = "http://localhost:9001"
  val versionPrefix = "/v1"
  val urls: Map[String, String] = Map(
    "authenticate" -> (versionPrefix + "/account/authenticate"),
    "addAccount" -> (versionPrefix + "/account"),
    "getAccount" -> (versionPrefix + "/v1")
  )
  val Type: Map[String, Long] = Map(
      "user" -> 10,
      "page" -> 20,
      "post" -> 30
    )
  val TypeString: Map[Long, String] = Map(
      10L -> "user",
      20L -> "page",
      30L -> "post"
    )

  val Types: List[String] = List("user", "page", "post")

  def addAccount(email: String, password: String, name: String): Future[Response] = {
    WS.url(server + urls("addAccount"))
      .withQueryString(("email", email), ("password", password), ("name", name))
      .post(Map("key" -> Seq("value")))
  }
  def authenticate(email: String, password: String): Future[Response] = {
    WS.url(server + urls("authenticate"))
      .withQueryString(("email", email), ("password", password))
      .post(Map("key" -> Seq("value")))
  }
}

object MintpressoAPI {
  var connections: Map[String, Mintpresso] = Map()
  def apply(label: String, accountId: Int): Mintpresso = {
    if(!connections.contains(label)){
      val m: Mintpresso = new Mintpresso(accountId)
      connections += ((label, m))
    }
    connections(label)
  }
}
class Mintpresso(accId: Int) {
  val server = "http://localhost:9001"
  val versionPrefix = "/v1"
  val urls: Map[String, String] = Map(
    "getPoint" -> (versionPrefix + "/account/%d/point/%d"),
    "getPointType" -> (versionPrefix + "/account/%d/points/type"),
    "getLatestPoint" -> (versionPrefix + "/account/%d/points/latest"),
    "getPointByTypeOrIdentifier" -> (versionPrefix + "/account/%d/point")
  )

  def getPoint(id: Int): Future[Response] = {
    WS.url(server + urls("getPoint").format(accId, id))
      .get()
  }
  def getPointTypes(): Future[Response] = {
    WS.url(server + urls("getPointType").format(accId))
      .get() 
  }
  def getLatestPoints(): Future[Response] = {
    WS.url(server + urls("getLatestPoint").format(accId))
      .get()  
  }
  def findByType(typeString: String, limit: Int = 30, offset: Int = 0): Future[Response] = {
    WS.url(server + urls("getPointByTypeOrIdentifier").format(accId))
      .withQueryString(("type", typeString), ("limit", limit.toString), ("offset", offset.toString))
      .get()
  }
  def findByIdentifier(identifier: String, limit: Int = 30, offset: Int = 0): Future[Response] = {
    WS.url(server + urls("getPointByTypeOrIdentifier").format(accId))
      .withQueryString(("identifier", identifier), ("limit", limit.toString), ("offset", offset.toString))
      .get()
  }
  def findByTypeAndIdentifier(typeString: String, identifier: String, limit: Int = 30, offset: Int = 0): Future[Response] = {
    WS.url(server + urls("getPointByTypeOrIdentifier").format(accId))
      .withQueryString(("type", typeString), ("identifier", identifier), ("limit", limit.toString), ("offset", offset.toString))
      .get()
  }
}