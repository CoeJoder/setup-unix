# usage: pygterminize [-h] -s STYLE [-u URL | -f FILE]
#
# A simple, terminal-only alternative to `pygmentize` with enhanced lexer guessing. Input: stdin. Output: stdout.
#
# options:
#   -h, --help            show this help message and exit
#   -s STYLE, --style STYLE
#                         The format style. Check available styles with `pygmentize -L styles`
#   -u URL, --url URL     The URL source (optional lexer hint)
#   -f FILE, --file FILE  The file name or path source (optional lexer hint)

# !IMPORTANT this should be run in the Pygments venv
# TODO move this to its own project
# TODO submit PR to Pygments for flushing/closing stdout & stderr on exit

import sys
import os
import argparse
from urllib.parse import urlparse
from pathlib import Path
from pygments import highlight
from pygments.lexers import get_lexer_for_filename, guess_lexer_for_filename, guess_lexer
from pygments.lexers.special import TextLexer
from pygments.formatters import TerminalTrueColorFormatter, Terminal256Formatter, TerminalFormatter
from pygments.util import ClassNotFound, guess_decode, guess_decode_from_terminal, terminal_encoding


def get_formatter(style):
    if os.environ.get('COLORTERM', '') in ('truecolor', '24bit'):
        return TerminalTrueColorFormatter(style=style)
    elif '256' in os.environ.get('TERM', ''):
        return Terminal256Formatter(style=style)
    return TerminalFormatter(style=style)


def get_lexer(encodedText, name=None):
    if name is None:
        decodedText, inencoding = guess_decode_from_terminal(encodedText, sys.stdin)
        try: lexer = guess_lexer(decodedText, inencoding=inencoding)
        except ClassNotFound:
            lexer = TextLexer(inencoding=inencoding)
    else:
        try: lexer = get_lexer_for_filename(name)
        except ClassNotFound:
            try:
                decodedText, inencoding = guess_decode_from_terminal(encodedText, sys.stdin)
                lexer = guess_lexer_for_filename(name, decodedText)
            except ClassNotFound:
                try: lexer = guess_lexer(decodedText, inencoding=inencoding)
                except ClassNotFound:
                    lexer = TextLexer(inencoding=inencoding)
    return lexer


def parse_args():
    parser = argparse.ArgumentParser(
        prog='pygterminize',
        description='A simple, terminal-only alternative to `pygmentize` with enhanced lexer guessing.  Input: stdin.  Output: stdout.'
    )
    parser.add_argument('-s', '--style', help='The format style.  Check available styles with `pygmentize -L styles`', required=True)
    group = parser.add_mutually_exclusive_group()
    group.add_argument('-u', '--url', help='The URL source (optional lexer hint)')
    group.add_argument('-f', '--file', help='The file name or path source (optional lexer hint)')
    return parser.parse_args()


def main():
    args = parse_args()
    if args.url is not None:
        name = Path(urlparse(args.url).path).name
    elif args.file is not None:
        name = Path(args.file).name
    else:
        name = None
    encodedText = sys.stdin.buffer.read()
    formatter = get_formatter(args.style)
    formatter.encoding = terminal_encoding(sys.stdout)
    lexer = get_lexer(encodedText, name)
    highlight(encodedText, lexer, formatter, sys.stdout.buffer)
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(1)
    finally:
        # see: https://github.com/python/cpython/issues/55589
        try: sys.stdout.flush()
        finally:
            try: sys.stdout.close()
            finally:
                try: sys.stderr.flush()
                finally: sys.stderr.close()
