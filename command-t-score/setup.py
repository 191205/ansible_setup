# Build with:
#
#       python3 setup.py build
#
# For more info, see: https://docs.python.org/3/extending/building.html
from distutils.core import setup, Extension

setup (name = 'commandt-score',
       version = '0.1',
       description = 'Command-T fuzzy match scoring algorithm',
       author = 'Greg Hurrell',
       author_email = 'greg@hurrell.net',
       url = 'https://github.com/wincent/command-t/tree/python/commandt/score',
       packages = ['commandt.score'],
       long_description = '''
This is the fuzzy match scoring algorithm, extracted from the Command-T (vim
plugin)project.
''',
       ext_package = 'commandt',
       ext_modules = [Extension('score', ['commandt/score/score.c'])])
