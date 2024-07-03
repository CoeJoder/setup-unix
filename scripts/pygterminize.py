"""
usage: pygterminize [-h] [-s STYLE] [-u URL | -f FILE]

A simple, terminal-only alternative to `pygmentize` with enhanced lexer guessing. Input: stdin. Output: stdout.

options:
  -h, --help            show this help message and exit
  -s STYLE, --style STYLE
                        the format style. Check available styles with `pygmentize -L styles`. Can be ommitted if PYGMENTIZE_STYLE env var is set
  -u URL, --url URL     the URL source (optional lexer hint)
  -f FILE, --file FILE  the file name or path source (optional lexer hint)
"""
# NOTE This should be run in the Pygments venv.
# TODO move this to its own project
# TODO submit PR to Pygments for flushing/closing stdout & stderr on exit

import sys
import os
import argparse
from urllib.parse import urlparse
from pathlib import Path
from pygments import highlight
from pygments.lexers import get_lexer_for_filename, guess_lexer_for_filename, guess_lexer
from pygments.lexers.shell import BashLexer, TcshLexer
from pygments.lexers.special import TextLexer
from pygments.formatters import TerminalTrueColorFormatter, Terminal256Formatter, TerminalFormatter
from pygments.util import ClassNotFound, guess_decode, guess_decode_from_terminal, terminal_encoding


ENV_VAR_STYLE = 'PYGMENTIZE_STYLE'
"""--style param can be omitted if this env var is set"""

# below are some known shell config files which are syntax highlightable,
# but maybe not recognizable by the Pygments lexer-guesser, per the docs,
# so we assign them manually as a fall-back during the lexer search

# BashLexer: bash, sh, ksh, zsh, shell, openrc
KNOWN_BASH_LEXABLE_SHELL_CONFIGS = {
    ".profile",

    # bash
    "bash.bashrc",
    ".bashrc",
    ".bash_aliases",
    ".bash_completion",
    ".bash_environment",
    ".bash_history",
    ".bash_login",
    ".bash_logout",
    ".bash_profile",

    # zsh
    "zlogin",
    "zlogout",
    "zprofile",
    "zshrc",
    ".zlogin",
    ".zlogout",
    ".zprofile",
    ".zshrc",
    ".zshenv",

    # ksh
    "ksh.kshrc"
    ".kshrc",
}

# TcshLexer: tcsh, csh
KNOWN_TCSH_LEXABLE_SHELL_CONFIGS = {
    # csh
    "csh.cshrc",
    "csh.login",
    "csh.logout",
    ".cshdirs",
    ".cshrc",

    # tcsh
    ".tcshrc",
}


def get_formatter(style):
    if os.environ.get('COLORTERM', '') in ('truecolor', '24bit'):
        formatter = TerminalTrueColorFormatter(style=style)
    elif '256' in os.environ.get('TERM', ''):
        formatter = Terminal256Formatter(style=style)
    else: formatter = TerminalFormatter(style=style)
    formatter.encoding = terminal_encoding(sys.stdout)
    return formatter


def get_lexer(encodedText, name=None):
    if name is None:
        decodedText, inencoding = guess_decode_from_terminal(encodedText, sys.stdin)
        try: lexer = guess_lexer(decodedText, inencoding=inencoding)
        except ClassNotFound:
            lexer = TextLexer(inencoding=inencoding)
    else:
        try: lexer = get_lexer_for_filename(name)
        except ClassNotFound:
            if name in KNOWN_BASH_LEXABLE_SHELL_CONFIGS:
                lexer = BashLexer()
            elif name in KNOWN_TCSH_LEXABLE_SHELL_CONFIGS:
                lexer = TcshLexer()
            else:
                try:
                    decodedText, inencoding = guess_decode_from_terminal(encodedText, sys.stdin)
                    lexer = guess_lexer_for_filename(name, decodedText)
                except ClassNotFound:
                    try: lexer = guess_lexer(decodedText, inencoding=inencoding)
                    except ClassNotFound:
                        lexer = TextLexer(inencoding=inencoding)
    return lexer


def env_var_or_required(key):
    val = os.environ.get(key)
    return ({'default': val} if val is not None else {'required': True})


def parse_args():
    parser = argparse.ArgumentParser(prog='pygterminize',
        description='A simple, terminal-only alternative to `pygmentize` with enhanced lexer guessing.  Input: stdin.  Output: stdout.')
    parser.add_argument('-s', '--style', **env_var_or_required(ENV_VAR_STYLE),
                        help=f'the format style.  Check available styles with `pygmentize -L styles`.  Can be ommitted if {ENV_VAR_STYLE} env var is set')
    group = parser.add_mutually_exclusive_group()
    group.add_argument('-u', '--url', type=urlparse, help='the URL source (optional lexer hint)')
    group.add_argument('-f', '--file', type=Path, help='the file name or path source (optional lexer hint)')
    args = parser.parse_args()
    if args.url is not None:
        args.name = Path(args.url.path).name
    elif args.file is not None:
        args.name = args.file.name
    else: args.name = None
    return args


def main():
    args = parse_args()
    encodedText = sys.stdin.buffer.read()
    formatter = get_formatter(args.style)
    lexer = get_lexer(encodedText, args.name)
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
