package models

import java.util.{Date}

import play.api.db._
import play.api.Play.current

import anorm._
import anorm.SqlParser._

case class Item(id: Pk[Long],
                image: String,
                href: String,
                title: String,
                details: String,
                requested: Long,
                purchased: Long,
                price: Double)

object Item {

  val simple = {
    get[Pk[Long]]("item.id") ~
    get[String]("item.image") ~
    get[String]("item.href") ~
    get[String]("item.title") ~
    get[String]("item.details") ~
    get[Long]("item.requested") ~
    get[Long]("item.purchased") ~
    get[Double]("item.price") map {
      case id~image~href~title~details~requested~purchased~price => Item(
        id, image, href, title, details, requested, purchased, price
      )
    }
  }

  def findById(id: Long): Option[Item] = {
    DB.withConnection { implicit connection =>
      SQL("select * from item where id = {id}").on(
        'id -> id
      ).as(Item.simple.singleOpt)
    }
  }

  def all: Seq[Item] = {
    DB.withConnection { implicit connection =>
      SQL("select * from item").as(Item.simple *)
    }
  }
}
