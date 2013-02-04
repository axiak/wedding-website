import os
import json
import jinjatag

from flaskext.mail import Message

from wedding.app import app

__all__ = (
    'send_confirmation_email',
    'send_certificate_email',
)

mail_env = app.create_jinja_environment()
jinja_tag = jinjatag.JinjaTag()
mail_env.add_extension(jinja_tag)
from .mail import *
jinja_tag.init()


def send_confirmation_email(payment):
    context = {
        'confirm_url': app.construct_url('/other/confirm.html#{0}'.format(payment.token)),
        'payment': payment
    }
    return send_message('confirmation.html', payment.email, **context)


@app.celery.task(name="mail.certificate", ignore_results=True)
def send_certificate_email(payment):
    context = {
        'payment': payment
    }
    return send_message('certificate.html', payment.email, **context)


@app.celery.task(name="mail.send", ignore_results=True)
def send_message(email_template, recipients, sender=None, cc=None, bcc=None, attachments=None, **context):
    from wedding.app import mail
    if not context:
        context = {}
    json_value = mail_env.get_template(os.path.join('email', email_template)).\
        render(**context)
    mail_info = json.loads(json_value)
    if not sender:
        sender = mail_info['from']
    if not isinstance(recipients, list):
        recipients = [recipients]
    if not sender:
        sender = 'Yalu and Mike <couple@yaluandmike.com>'
    msg = Message(mail_info['subject'], recipients,
                  mail_info['body'], mail_info.get('html') or None,
                  sender=sender, cc=cc,
                  bcc=bcc, attachments=attachments)
    try:
        mail.send(msg)
    except Exception as exc:
        send_message.retry(exc=exc)