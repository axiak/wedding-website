import jinja2
import boto
from PIL import Image
import os
import json
from email.utils import parsedate
import pyexiv2
import datetime
from boto.utils import parse_ts
from boto.s3.connection import S3Connection, Bucket, Key
import mimetypes

BUCKET = 'yaluandmike'
AWS_ACCESS_KEY = 'AKIAJHKYVIJRLI3T3VIQ'
AWS_SECRET_KEY = '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'

GALLERY_DIR = os.path.join(os.environ['HOME'], "Dropbox", "Wedding Gallery")

print GALLERY_DIR

def add_photos(obj):
    if not isinstance(obj, jinja2.Template):
        return
    if not '/pictures/' in obj.filename:
        return

    if not os.path.exists(GALLERY_DIR):
        return

    image_data = {}

    aws_conn = S3Connection(AWS_ACCESS_KEY, AWS_SECRET_KEY)

    for root, dirs, files in os.walk(GALLERY_DIR):
        for file in files:
            if '-rsd.' in file:
                continue
            gallery_name = os.path.basename(root).strip('/')
            filepath = os.path.join(root, file)
            if gallery_name not in image_data:
                image_data[gallery_name] = []
            image_data[gallery_name].append(process_file(aws_conn, filepath))

    for key in image_data:
        values = filter(None, [image for _, image in sorted(filter(None, image_data[key]))])
        if values:
            image_data[key] = values

    if 'Wedding Gallery' in image_data:
        del image_data['Wedding Gallery']

    obj.globals['photos'] = image_data

def process_file(aws_conn, filepath):
    mtime = get_mtime(filepath)

    name_200 = add_size_name(filepath, '200')
    name_800 = add_size_name(filepath, '800')

    mtime_200 = get_mtime(name_200)
    mtime_800 = get_mtime(name_800)

    im = None
    if mtime_200 is None or mtime_200 < mtime:
        try:
            im = Image.open(filepath)
        except:
            return None
        generate_200(im, name_200)

    if mtime_800 is None or mtime_800 < mtime:
        if im is None:
            try:
                im = Image.open(filepath)
            except:
                return None
        generate_800(im, name_800)

    names = {
        'original': filepath,
        'thumbnail': name_200,
        'display': name_800,
        }


    b = Bucket(aws_conn, BUCKET)

    image_result = {}

    for image_type, name in names.items():
        aws_tag_path = add_size_name(name, 's3t') + '.meta'
        aws_key_path = name[len(GALLERY_DIR):].strip('/')

        image_result[image_type] = {
            'url': 'http://s3.amazonaws.com/{}/{}'.format(
            BUCKET,
            aws_key_path)
            }

        if not is_newer(name, aws_tag_path):
            try:
                resolution = load_data(aws_tag_path)
                resolution['width']
            except:
                resolution = get_resolution(name)
                save_data(aws_tag_path, resolution)
            image_result[image_type].update(resolution)
            continue


        resolution = get_resolution(name)
        image_result.update(resolution)
        save_data(aws_tag_path, resolution)

        s3key = b.get_key(aws_key_path)
        mtime = get_mtime(name)

        if s3key and s3key.last_modified:
            print datetime.datetime(*parsedate(s3key.last_modified)[:6])
            print mtime
            if datetime.datetime(*parsedate(s3key.last_modified)[:6]) > mtime:
                with open(aws_tag_path, 'a'):
                    os.utime(aws_tag_path, None)
                continue
        print 'Sending {} to S3'.format(name)
        k = Key(b)
        k.key = aws_key_path
        expires = datetime.datetime.utcnow() + datetime.timedelta(days=25 * 365)
        expires = expires.strftime("%a, %d %b %Y %H:%M:%S GMT")
        k.set_metadata("Content-Type", mimetypes.guess_type(name)[0])
        k.set_metadata("Expires", expires)
        k.set_metadata("Cache-Control", "max-age={0}, public".format(86400 * 365 * 25))
        k.set_contents_from_filename(name)
        k.set_acl('public-read')

        with open(aws_tag_path, 'a'):
            os.utime(aws_tag_path, None)

    photo_age = get_photo_age(filepath)

    image_result['caption'] = get_caption(filepath)

    return photo_age, image_result

def get_caption(name):
    try:
        exif = pyexiv2.ImageMetadata(name)
        exif.read()
        return exif['Xmp.dc.title'].value.values()[0]
    except:
        return None


def get_resolution(name):
    im = Image.open(name)
    size = im.size
    return {'width': size[0], 'height': size[1]}

def load_data(fname):
    with open(fname, 'r') as f:
        return json.loads(f.read().strip())

def save_data(fname, data):
    with open(fname, 'w+') as f:
        f.write(json.dumps(data))

def get_200_size(im):
    w, h = im.size
    col_width = 176
    real_w = col_width - 10

    if h <= w:
        w, h = int(real_w / float(h) * w), real_w
    else:
        w, h = real_w, int(real_w / float(w) * h)
    for i in (2, 3):
        if (i - 1) * col_width  < w < col_width * i:
            ratio = (col_width * i - 10) / float(w)
            w = col_width * i - 10
            h = int(ratio * h)
    return (w, h)


def generate_200(im, target_path):
    w, h = get_200_size(im)
    im = im.resize((w, h), Image.ANTIALIAS)
    im.save(target_path)

def generate_800(im, target_path):
    im.thumbnail((800, 800), Image.ANTIALIAS)
    im.save(target_path)

def get_photo_age(photo_file):
    try:
        exif = pyexiv2.ImageMetadata(photo_file)
        exif.read()
    except:
        pass
    else:
        if 'Exif.Image.DateTime' in exif:
            return exif['Exif.Image.DateTime'].value
    return datetime.datetime.fromtimestamp(int(os.stat(photo_file).st_ctime))

def get_mtime(filepath):
    if not os.path.exists(filepath):
        return None
    else:
        return datetime.datetime.fromtimestamp(int(os.stat(filepath).st_mtime)) + datetime.timedelta(hours=4)

def is_newer(old_file, new_file):
    if not os.path.exists(new_file):
        return True
    old_mtime = os.stat(old_file).st_mtime
    new_mtime = os.stat(old_file).st_mtime
    return old_mtime > new_mtime


def add_size_name(filepath, name):
    filepath, ext = filepath.rsplit('.', 1)
    return "{}-{}-rsd.{}".format(filepath, name, ext)
