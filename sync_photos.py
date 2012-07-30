#!/usr/bin/python
import os
from datetime import datetime, timedelta
import boto
import mimetypes

from boto.s3.connection import S3Connection, Bucket, Key

BUCKET = 'yaluandmike'
AWS_ACCESS_KEY = 'AKIAJHKYVIJRLI3T3VIQ'
AWS_SECRET_KEY = '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'
IMG_PATH = 'base/img'


def main():
    conn = S3Connection(AWS_ACCESS_KEY, AWS_SECRET_KEY)

    for root, dirs, files in os.walk(os.path.join(os.path.dirname(__file__), IMG_PATH)):
        for filename in files:
            full_path = os.path.join(root, filename)
            try:
                upload_file(conn, full_path)
            except Exception as e:
                print "Error: {}".format(e)


def upload_file(conn, full_path):
    b = Bucket(conn, BUCKET)
    k = Key(b)
    k.key = full_path
    expires = datetime.utcnow() + timedelta(days=(25 * 365))
    expires = expires.strftime("%a, %d %b %Y %H:%M:%S GMT")
    k.set_metadata("Content-Type", mimetypes.guess_type(full_path)[0])
    k.set_metadata("Expires", expires)
    k.set_contents_from_filename(full_path)
    k.set_acl('public-read')
    print "{} -> http://s3.amazonaws.com/yaluandmike/{}".format(full_path, full_path)


if __name__ == '__main__':
    main()
