import json
import jinjatag


@jinjatag.multibody_block
def mail(subject, body, html='', **kwargs):
    from_ = kwargs.pop('from', None)
    if from_:
        from_ = map(lambda x: x.strip(), from_.split(','))
    else:
        from_ = []
    return json.dumps({
            'subject': subject.strip(),
            'body': body.strip(),
            'html': html.strip(),
            'from': from_
    })
