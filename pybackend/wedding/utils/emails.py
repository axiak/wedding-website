import os
import json
import jinjatag

from flaskext.mail import Message, Attachment

from wedding.app import app
from wedding.utils import certificate

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
    return send_message('confirmation.html', payment.email, bcc=['couple@yaluandmike.com'], **context)


def send_invitation(name, email, rsvp_code):
    context = {
        'name': name,
        'rsvp_code': rsvp_code
    }
    return send_message('invitation.html', email, bcc=['couple@yaluandmike.com'], **context)


@app.celery.task(name="mail.certificate", ignore_results=True)
def send_certificate_email(payment):
    context = {
        'payment': payment
    }
    with certificate.certificate(payment) as pdffile:
        attachments = [
            Attachment(filename='gift-certificate.pdf',
                       content_type='application/pdf',
                       data=pdffile.read())
        ]
        return send_message('certificate.html', payment.email, bcc=['couple@yaluandmike.com'], attachments=attachments, **context)


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
