import os
import glob


def sub_modules(prefix, file_path):
    for fname in glob.glob(os.path.join(os.path.dirname(file_path), prefix.strip('.'), '*')):
        basename = os.path.basename(fname)
        if not basename.startswith('__') and fname.endswith('.py'):
            yield prefix.strip('.') + '.' + basename[:-3]
        elif not basename.startswith('__') and os.path.isdir(fname) and os.path.exists(os.path.join(fname, '__init__.py')):
            yield prefix.strip('.') + '.' + basename
