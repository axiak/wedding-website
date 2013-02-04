from sqlalchemy.schema import ColumnDefault
from sqlalchemy.orm import aliased

from wedding.app import db, app
from wedding.utils import modeljson

from wedding.models.items import Item

__all__ = (
    'Payment',
    'PaymentItem',
)


@modeljson.jsonify
class Payment(db.Model):
    __tablename__ = 'payment'
    token = db.Column(db.String(255), primary_key=True)
    name = db.Column(db.Unicode(255))
    email = db.Column(db.Unicode(255))
    notes = db.Column(db.UnicodeText())
    total = db.Column(db.Float())
    #payment_items = db.relationship('PaymentItem', backref='payment', lazy='dynamic')
    charge_id = db.Column(db.String(255))
    payment_time = db.Column(db.DateTime())

    def items(self):
        return PaymentItem.query.filter(PaymentItem.payment_token == self.token).all()


@modeljson.jsonify
class PaymentItem(db.Model):
    __tablename__ = 'payment_item'
    payment_token = db.Column('payment_token', db.String(255), db.ForeignKey('payment.token'), primary_key=True)
    item_id = db.Column('item_id', db.Integer, db.ForeignKey('item.id'), primary_key=True)
    num = db.Column(db.Integer())

    def item(self):
        return Item.query.filter(Item.id == self.item_id).limit(1).first()
