import os
import sys

from flask import Flask
from flaskext.sqlalchemy import SQLAlchemy
from flaskext.script import Manager
from flask.ext.celery import install_commands, Celery
from flaskext.mail import Mail

__all__ = [
    'app',
    'db',
    'mail',
]

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

if 'INSTANCE_PATH' in os.environ:
    instance_path = os.environ['INSTANCE_PATH']
    cwd = os.get_cwd()
    if not instance_path.startswith('/'):
        instance_path = os.path.abspath(os.path.join(cwd, instance_path))
else:
    instance_path = os.path.abspath(os.path.join(os.path.dirname(__file__)))


app = Flask(__name__, instance_relative_config=True, instance_path=instance_path)

app.config.from_pyfile('application.cfg')
db = SQLAlchemy(app)


from wedding.utils import debug

debug.log_queries(app)

mail = Mail(app)
manager = Manager(app)
celery = Celery(__name__)
celery.conf.add_defaults(app.config)
install_commands(manager)
app.celery = celery

def construct_url(path):
    import flask
    try:
        host = request.headers['Host']
    except:
        beginning = app.config['ABSOLUTE_HOST']
    else:
        beginning = ('https://' if request.is_secure else 'http://') + host
    return beginning.rstrip('/') + '/' + path.lstrip('/')

app.construct_url = construct_url
