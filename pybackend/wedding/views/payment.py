import uuid
import flask
import stripe
import datetime

from wedding.app import app, db

from wedding.models import Item, Payment, PaymentItem
from wedding.utils import rest, views, emails

if app.debug:
    stripe.api_key = 'sk_08EBpE8A19np6s3xgJKae9crojn5q'
else:
    stripe.api_key = 'sk_08EBbi1WZIL4TKrzncWTXCVj5gSjk'


@app.route("/api/payment/", methods=['POST'])
@views.json_response
def handle_payment():
    data = flask.request.json
    session = db.session
    session.begin(subtransactions=True)
    try:
        if data.get('payment', {}).get('card'):
            handle_card(data)
        else:
            handle_paper(data)
    except:
        session.rollback()
        raise
    else:
        session.commit()

    return {'success': True}


@app.route("/api/payment/confirm/", methods=['POST'])
@views.json_response
def handle_confirmation():
    data = flask.request.json
    payment = Payment.query.filter(Payment.token == data.get('guid', '')).limit(1).first()

    if not payment:
        return {}, 404

    payment.charge_id = "paper"
    payment.payment_time = datetime.datetime.now()

    db.session.add(payment)
    db.session.commit()

    emails.send_certificate_email(payment)

    return {"name": payment.name}


@app.route("/api/payment/report/", methods=["GET"])
def get_report():
    data = flask.request.args
    if data.get('test') != 'malteaser':
        return 'not allowed'
    from cStringIO import StringIO
    import csv
    tmp = StringIO()
    writer = csv.writer(tmp)
    writer.writerow(['Name', 'Notes', 'Item', 'Qty', 'Amount', 'Paid'])
    previous_name = None
    for payment in Payment.query.order_by('name').all():
        for lineitem in payment.items():
            row = []
            name = payment.name
            if previous_name != name:
                row.extend([name, payment.notes])
                previous_name = name
            else:
                row.extend(['', ''])
            qty = lineitem.num
            item = lineitem.item()
            row.extend([item.title, qty, item.price * qty])
            row.append('No' if payment.charge_id == 'paper' else 'Yes')
            writer.writerow(row)
    response = flask.Response(tmp.getvalue(), mimetype='text/csv')
    return response

def handle_card(data):
    session = db.session
    payment = data['payment']
    details = data['details']
    total = int(sum(item['price'] * item['quantity'] for item in details)) * 100

    charge = stripe.Charge.create(
        amount=total,
        currency="usd",
        card=payment['token'],
        description=payment['email'])

    if not charge['paid']:
        raise Exception("Not paid")

    payment_token = payment['token']

    payment = Payment(token=payment['token'],
                      name=payment['name'],
                      email=payment['email'],
                      notes=payment.get('notes'),
                      total=total / 100.0,
                      charge_id=charge['id'],
                      payment_time=datetime.datetime.fromtimestamp(charge['created']))


    session.add(payment)

    for item in details:
        session.add(PaymentItem(payment_token=payment_token, item_id=item['id'], num=item['quantity']))
        Item.query.filter(Item.id == item['id']).update({Item.purchased: Item.purchased + item['quantity']})

    session.commit()

    emails.send_certificate_email(payment)


def handle_paper(data):
    session = db.session
    payment = data['payment']
    details = data['details']

    gid = uuid.uuid1()

    total = int(sum(item['price'] * item['quantity'] for item in details))

    payment = Payment(token=gid,
                      name=payment['name'],
                      email=payment['email'],
                      notes=payment.get('notes'),
                      total=total)

    session.add(payment)

    for item in details:
        session.add(PaymentItem(payment_token=gid, item_id=item['id'], num=item['quantity']))
        Item.query.filter(Item.id == item['id']).update({Item.purchased: Item.purchased + item['quantity']})
    session.commit()

    emails.send_confirmation_email(payment)
