import os
import glob
import importlib

from .utils import subpackages

from .app import *

here = os.path.dirname(__file__)

for package in subpackages.sub_modules('views', __file__):
    importlib.import_module('wedding.' + package)
