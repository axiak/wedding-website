import flask

from wedding.app import app, db

from wedding.models import Item
from wedding.utils import rest

@app.route('/api/items/', methods=['GET'])
@rest.get_many
def get_items():
    return Item.query.order_by(Item.purchased - Item.requested).all()
