import jinja2

def add_photos(obj):
    if not isinstance(obj, jinja2.Template):
        return
    if not '/pictures/' in obj.filename:
        return
    print 'foo'
    print obj.environment
    print obj.filename

