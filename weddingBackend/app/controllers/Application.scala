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

  val payment = Action(parse.json) { request =>
    Ok(toJson(Map("test" -> "foo")))
  /*
    val badRequest = BadRequest("Invalid Request")
    //       {"payment":
    //          {"card":true,"token":"tok_0L3Du26fgb12u2","name":"asdfasdf","email":"mike@axiak.net"},
    //        "details":[{"id":19,"price":50,"quantity":1}]}
    ((request.body \ "payment") \ "card").asOpt[Boolean].map { isCard =>

      if (isCard) {
        val token = (request.body \ "payment" \ "token").as[String]

      } else {
        Ok("NO card")
      }
    }.getOrElse {
      badRequest
    }
  */
  }
}
