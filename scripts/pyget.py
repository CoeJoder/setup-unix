# this should be run in the Pygments venv
# reads stdin, writes stdout
# params: url, style

# TODO move this to its own project
# TODO submit PR to Pygments for flushing/closing stdout & stderr on exit

import sys
import os
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


def main():
    url = sys.argv[1]
    style = sys.argv[2]
    encodedText = sys.stdin.buffer.read()
    name = Path(urlparse(url).path).name
    formatter = get_formatter(style)
    formatter.encoding = terminal_encoding(sys.stdout)
    try: lexer = get_lexer_for_filename(name)
    except ClassNotFound:
        try:
            decodedText, inencoding = guess_decode_from_terminal(encodedText, sys.stdin)
            lexer = guess_lexer_for_filename(name, decodedText)
        except ClassNotFound:
            try: lexer = guess_lexer(decodedText, inencoding=inencoding)
            except ClassNotFound:
                lexer = TextLexer(inencoding=inencoding)
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
