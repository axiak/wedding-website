import json
import datetime

from wedding.app import db

from sqlalchemy.orm.attributes import InstrumentedAttribute

__all__ = [
    'jsonify',
    'jsonfield',
    'encoder',
]


def jsonify(excludes=(), only=None):
    outer_excludes = set() if isinstance(excludes, type) else set(excludes)
    outer_only = set() if not only else set(only)
    def _wrapper(cls):
        if getattr(getattr(cls, 'to_json', None), 'cls_name', None) == cls.__name__:
            return cls
        attributes = set(name for name, obj in
                      ((name, getattr(cls, name)) for name
                       in dir(cls) if not name.startswith('__'))
                      if isinstance(obj, InstrumentedAttribute) or getattr(obj, '_json_export', False))
        def to_json(self, excludes=(), only=()):
            excludes = set(excludes) | outer_excludes
            only = set(only) | outer_only
            if only:
                result = dict((name, getattr(self, name, None))
                              for name in attributes
                              if name in only)
            else:
                result = dict((name, getattr(self, name, None))
                              for name in attributes
                              if name not in excludes)
            for key, value in result.items():
                if isinstance(value, db.Model) and not hasattr(value, 'to_json'):
                    del result[key]
                elif callable(value):
                    result[key] = value()
            if hasattr(self, 'json_handler'):
                result = self.json_handler(result)
            return result
        cls.to_json = to_json
        to_json.cls_name = cls.__name__
        return cls
    if isinstance(excludes, type):
        cls = excludes
        return _wrapper(cls)
    return _wrapper

def jsonfield(obj):
    if isinstance(obj, property):
        prop_dict = dict((key, getattr(obj, key))
                         for key in ('fget', 'fset', 'fdel')
                         if not key.startswith('__'))
        obj = jsonproperty(**prop_dict)
    else:
        obj._json_export = True
    return obj


class jsonproperty(property):
    _json_export = True

class ModelJsonEncoder(json.JSONEncoder):
    def default(self, o):
        if hasattr(o, 'isoformat'):
            return o.isoformat()
        elif hasattr(o, 'to_json'):
            return o.to_json()
        return json.JSONEncoder.default(self, o)


encoder = ModelJsonEncoder()
