#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fileencoding=utf-8 fileformat=unix
#
# Author:  Iranoan <iranoan+vim@gmail.com>
# License: GPL Ver.3.

from subprocess import run, PIPE
from email import utils
from shutil import which
import re

RE_CRLF = re.compile(r'[\r\n]+')
RE_SPACE = re.compile(r'[\u3000\t ]+')


def asyncomplete_address(kw):
    def goobook(kw):
        ret = run(['goobook', 'query', kw], stdout=PIPE, stderr=PIPE)
        matches = []
        for adr in RE_CRLF.split(ret.stdout.decode()):
            adr = adr.split('\t')
            adr_len = len(adr)
            if adr_len == 2 and adr[1] != 'My Contacts (group)':
                matches.append({'word': adr[0], 'dup': 0, 'icase': 1, 'abbr': adr[1]})
            elif adr_len == 3:
                name = RE_SPACE.sub(' ', utils.unquote(adr[1]))
                if ',' in name:
                    if '"' in name and not (r'\"') in name:
                        name = utils.quote(name)
                    matches.append({'word': '"' + name + '" <' + adr[0] + '>',
                                    'dup': 0, 'icase': 1, 'menu': '[goobook]'})
                else:
                    matches.append({'word': name + ' <' + adr[0] + '>',
                                    'dup': 0, 'icase': 1, 'menu': '[goobook]'})
        return matches

    if which('goobook') is not None:
        return goobook(kw)
    elif which('notmuch'):
        ret = run(['notmuch', 'address', '--deduplicate=address',
                   'from:' + kw, 'or', 'to:' + kw, 'or', 'cc:' + kw, 'or', 'bcc:' + kw],
                  stdout=PIPE, stderr=PIPE)
        return [{'word': RE_SPACE.sub(' ', x), 'dup': 0, 'icase': 1, 'menu': '[notmuch]'}
                for x in RE_CRLF.split(ret.stdout.decode())]
