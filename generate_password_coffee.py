#!/usr/bin/env python
import os
import sys
import csv
import hashlib
from collections import defaultdict


def main():
    iter(sys.stdin).next()
    read = csv.reader(sys.stdin)

    site_names = defaultdict(lambda: [])
    individual_names = {}
    for row in read:
        if not row[10].strip():
            continue
        encoded = digest(row[10])
        site_names[encoded].append(row[0])
        names = filter(None, row[11:])
        individual_names[row[0]] = names
    for key, value in site_names.items():
        name = ','.join(value)
        site_names[key] = name
        if len(value) > 1 and name in individual_names:
            del individual_names[name]

    print_dict('mainPw', site_names)
    print_dict('individuals', individual_names)


def digest(pw):
    return hashlib.sha1(pw.lower()).hexdigest()


def print_dict(name, dict):
    lines = []
    for key, value in dict.items():
        lines.append('  {0!r}: {1!r}'.format(key, value))

    print '{0} =\n{1}\n'.format(name, '\n'.join(lines))



if __name__ == '__main__':
    main()
