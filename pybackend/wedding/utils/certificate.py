import os

import cStringIO as StringIO
import ho.pisa as pisa
import subprocess
import tempfile
import pipes
import contextlib
import shutil
from wedding.app import app

from wedding.models import *

jinja_env = app.create_jinja_environment()

__all__ = (
    'certificate',
)

@contextlib.contextmanager
def certificate(payment):
    context = {
        'pagesize': "letter",
        'name': payment.name,
        'items': payment.items()
    }
    content = jinja_env.get_template('certificate.tex').render(**context)
    tmpdir = None
    try:
        tmpdir = tempfile.mkdtemp('certificate')
        yield _run_latex(content, tmpdir)
    finally:
        if tmpdir is not None:
            shutil.rmtree(tmpdir)


def _run_latex(content, tmpdir):
    shutil.copyfile(os.path.join(os.path.dirname(__file__),
                                 'border.png'),
                    os.path.join(tmpdir, 'border.png'))
    shutil.copyfile(os.path.join(os.path.dirname(__file__),
                                 'us.jpg'),
                    os.path.join(tmpdir, 'us.jpg'))
    texfile = tempfile.NamedTemporaryFile(suffix='.tex', dir=tmpdir)
    src = StringIO.StringIO(content)
    src.reset()
    shutil.copyfileobj(src, texfile)
    texfile.flush()
    p = subprocess.Popen('yes "" | pdflatex {0}'.format(pipes.quote(texfile.name)),
                         shell=True,
                         cwd=tmpdir)
    p.wait()
    pdffile = texfile.name.rsplit('.', 1)[0] + ".pdf"
    return open(pdffile, "rb")
