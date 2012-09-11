package models

import java.util.{Date}

import play.api.db._
import play.api.Play.current

import anorm._
import anorm.SqlParser._

case class Customer(id: Pk[Long],
                image: String,
                href: String,
                title: String,
                details: String,
                requested: Long,
                purchased: Long,
                price: Double)

object Customer {

  val simple = {
    get[Pk[Long]]("customer.id") ~
      get[String]("customer.name") ~
      get[String]("customer.email") ~
      get[String]("customer.token") ~
      get[String]("customer.email_token") ~
      get[Long]("Customer.requested") ~
      get[Long]("Customer.purchased") ~
      get[Double]("Customer.price") map {
      case id~image~href~title~details~requested~purchased~price => Customer(
        id, image, href, title, details, requested, purchased, price
      )
    }
  }

  def findById(id: Long): Option[Customer] = {
    DB.withConnection { implicit connection =>
      SQL("select * from Customer where id = {id}").on(
        'id -> id
      ).as(Customer.simple.singleOpt)
    }
  }

  def all: Seq[Customer] = {
    DB.withConnection { implicit connection =>
      SQL("select * from Customer").as(Customer.simple *)
    }
  }
}
