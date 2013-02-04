import json
import functools
import traceback

from flask import request, make_response
import werkzeug.exceptions

from wedding.app import app
from wedding.utils import views as viewutils

ValidationException = viewutils.ValidationException

__all__ = [
    'get_one',
    'get_many',
    'delete',
    'create',
    'delete',
    'update',
    'ValidationException',
]


def get_one(method):
    @viewutils.json_response
    @functools.wraps(method)
    def _wrapped(*args, **kwargs):
        obj = method(*args, **kwargs)
        return obj, 200
    return _wrapped

def get_many(method):
    @viewutils.json_response
    @functools.wraps(method)
    def _wrapped(*args, **kwargs):
        obj = method(*args, **kwargs)
        return {'items': list(obj)}, 200
    return _wrapped

def create(method):
    @viewutils.json_response
    @functools.wraps(method)
    def _wrapped(*args, **kwargs):
        obj = method(*args, **kwargs)
        if not hasattr(obj, 'primary_key'):
            app.logger.error("Please add @modelpk.with_model_pk to the '{0}' model class. Object: {1}".format(obj.__class__.__name__, obj))
            primary_key = {'id': obj.id}
        else:
            primary_key = obj.primary_key
        return primary_key, 201
    return _wrapped

def delete(method):
    @viewutils.json_response
    @functools.wraps(method)
    def _wrapped(*args, **kwargs):
        deleted = method(*args, **kwargs)
        if deleted:
            return '', 204
        return '', 404
    return _wrapped

def update(method):
    @viewutils.json_response
    @functools.wraps(method)
    def _wrapped(*args, **kwargs):
        num_modified = method(*args, **kwargs)
        if isinstance(num_modified, int):
            return {'num_modified': num_modified}, 201
        else:
            return {'num_modified': 0}, 200
    return _wrapped
