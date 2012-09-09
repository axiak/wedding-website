package controllers

import play.api._
import play.api.mvc._
import play.api.Play.current
import play.api.libs.json._
import play.api.libs.json.Json._
import play.api.libs.Jsonp

import models._

object Application extends Controller {

  implicit object ItemFormat extends Format[Item] {
    def reads(json: JsValue): Item = null

    def writes(i: Item): JsValue = JsObject(List(
      "id" -> JsNumber(i.id.get),
      "href" -> JsString(i.href),
      "image" -> JsString(i.image),
      "title" -> JsString(i.title),
      "details" -> JsString(i.details),
      "requested" -> JsNumber(i.requested),
      "purchased" -> JsNumber(i.purchased),
      "price" -> JsNumber(i.price)
    ))
  }

  val items = Action {
    Ok(toJson(Map(
      "items" -> Item.all
    )))
  }
}
