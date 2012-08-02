import jinja2
import boto
from PIL import Image
import os
from email.utils import parsedate
import pyexiv2
import datetime
from boto.utils import parse_ts
from boto.s3.connection import S3Connection, Bucket, Key
import mimetypes

BUCKET = 'yaluandmike'
AWS_ACCESS_KEY = 'AKIAJHKYVIJRLI3T3VIQ'
AWS_SECRET_KEY = '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'

GALLERY_DIR = "/home/axiak/BigDocuments/Dropbox/Wedding Gallery"

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
        image_data[key] = [image for _, image in sorted(image_data[key])]

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
        aws_key_path = name[len(GALLERY_DIR):].strip('/')
        s3key = b.get_key(aws_key_path)
        mtime = get_mtime(name)
        image_result[image_type] = 'http://s3.amazonaws.com/{}/{}'.format(
            BUCKET,
            aws_key_path)

        if s3key and s3key.last_modified:
            if datetime.datetime(*parsedate(s3key.last_modified)[:6]) > mtime:
                continue
        print 'Sending {} to S3'.format(name)
        k = Key(b)
        k.key = aws_key_path
        expires = datetime.datetime.utcnow() + datetime.timedelta(days=25 * 365)
        expires = expires.strftime("%a, %d %b %Y %H:%M:%S GMT")
        k.set_metadata("Content-Type", mimetypes.guess_type(name)[0])
        k.set_metadata("Expires", expires)
        k.set_contents_from_filename(name)
        k.set_acl('public-read')


    photo_age = get_photo_age(filepath)

    return photo_age, image_result



def generate_200(im, target_path):
    w, h = im.size
    h = int(200.0 / float(w) * h)
    im = im.resize((200, h), Image.ANTIALIAS)
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
        return datetime.datetime.fromtimestamp(int(os.stat(filepath).st_mtime))


def add_size_name(filepath, name):
    filepath, ext = filepath.rsplit('.', 1)
    return "{}-{}-rsd.{}".format(filepath, name, ext)
