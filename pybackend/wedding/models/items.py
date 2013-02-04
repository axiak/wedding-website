
from sqlalchemy.schema import ColumnDefault
from sqlalchemy.orm import aliased

from wedding.app import db, app
from wedding.utils import modeljson

__all__ = (
    'Item',
)

@modeljson.jsonify
class Item(db.Model):
    __tablename__ = 'item'
    id = db.Column(db.Integer, primary_key=True)
    href = db.Column(db.Unicode(length=255))
    title = db.Column(db.Unicode(length=255))
    image = db.Column(db.Unicode(length=255))
    details = db.Column(db.UnicodeText())
    requested = db.Column(db.Integer())
    purchased = db.Column(db.Integer())
    price = db.Column(db.Float())

    def __repr__(self):
        return '<Item: {0}>'.format(self.title)

