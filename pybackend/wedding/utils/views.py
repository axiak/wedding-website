import json
import functools
import traceback
import decorator

from flask import request, make_response, abort
import werkzeug.exceptions
from werkzeug.wrappers import BaseResponse
from werkzeug import datastructures

from wedding.app import app
from wedding.utils import modeljson

__all__ = [
    'getparam',
    'json_response',
    'xml_response',
    'ValidationException',
]

class ValidationException(Exception):
    def __init__(self, exc, code=400):
        self.exc = exc
        self.code = code

def getparam(key, default=''):
    return request.args.get(key, request.form.get(key, default))

def _json_view(method, *args, **kwargs):
    force_xhr = method.force_xhr
    if force_xhr and not app.config['DEBUG'] and not request.is_xhr:
        abort(403)
    status_code = 200
    try:
        request.json_params = datastructures.MultiDict((request.json or {}).items())
        data = method(*args, **kwargs)

    except ValidationException as e:
        status_code = e.code
        data = {'validation_errors': e.exc}

    except Exception as e:
        if isinstance(e, werkzeug.exceptions.HTTPException):
            raise
        app.logger.error(str(e), exc_info=True)
        if app.config['DEBUG'] and not request.is_xhr:
            raise
        elif app.config['DEBUG']:
            data = {'error': traceback.format_exc()}
        else:
            raise
        status_code = 500

    if isinstance(data, tuple) and len(data) == 2:
        data, status_code = data

    if not isinstance(data, basestring) and not isinstance(data, BaseResponse):
        data = modeljson.encoder.encode(data)

    if isinstance(data, basestring):
        response = make_response(data)
        response.headers['Content-Type'] = 'application/json'
        response.status_code = status_code
        return response
    else:
        return data



def json_response(force_xhr=True):
    def _decorator(method):
        method.force_xhr = force_xhr
        func = decorator.decorator(_json_view, method)
        func.json_response = True
        return func
    if callable(force_xhr):
        method = force_xhr
        force_xhr = True
        return _decorator(method)
    return _decorator

def xml_response(method):
    @functools.wraps(method)
    def _wrapped(*args, **kwargs):
        response = make_response(method(*args, **kwargs).strip())
        response.headers['Content-Type'] = 'text/xml'
        return response
    return _wrapped
