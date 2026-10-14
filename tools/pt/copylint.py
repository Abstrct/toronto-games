#!/usr/bin/env python3
"""Inventory and lint every player-facing string in the ROM source.

    python3 tools/pt/copylint.py            # lint summary
    python3 tools/pt/copylint.py --all      # every string, grouped by file
    python3 tools/pt/copylint.py --md FILE  # write the inventory as Markdown

Strings are `.byte "..."` literals (with $0A line breaks and $22 quotes) in src/*.s.
Checks: card/HUD lines wider than their budget, stale event counts, developer
jargon, and gag lines reused across events.
"""
import argparse
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))

WIDTH = 26                 # intro-card / popup line budget (characters)
JARGON = ['PX', 'EV_', 'TODO', 'DEBUG', 'NULL', 'FRAME', 'SPR', 'OAM', 'VRAM']
STALE = [r'\bFIVE\b', r'\b5 EVENTS\b']


def strings():
    """Yield (file, line number, label, text lines) for each string literal."""
    for fn in sorted(os.listdir(os.path.join(ROOT, 'src'))):
        if not fn.endswith('.s') and not fn.endswith('.inc'):
            continue
        for i, line in enumerate(open(os.path.join(ROOT, 'src', fn), encoding='latin1'), 1):
            code = line.split(';')[0]
            if '.byte' not in code or '"' not in code:
                continue
            m = re.match(r'\s*(\w+):', code)
            label = m.group(1) if m else ''
            body = code.split('.byte', 1)[1]
            text = ''
            for part in re.findall(r'"[^"]*"|\$[0-9A-Fa-f]{2}|\d+', body):
                if part.startswith('"'):
                    text += part[1:-1]
                elif part.upper() == '$0A':
                    text += '\n'
                elif part.upper() == '$22':
                    text += '"'
                elif part == '0':
                    break
            if not text.strip():
                continue
            yield fn, i, label, text.split('\n')


def lint(rows):
    issues = []
    seen = collections.defaultdict(list)
    for fn, i, label, lines in rows:
        for ln in lines:
            if len(ln) > WIDTH and (label[:2] in ('eb', 'ec', 'ef') or 'pop' in label or 'msg' in label):
                issues.append((fn, i, label, 'long', '%d chars > %d: %r' % (len(ln), WIDTH, ln)))
            for pat in STALE:
                if re.search(pat, ln):
                    issues.append((fn, i, label, 'stale', repr(ln)))
            for j in JARGON:
                if re.search(r'\b%s\b' % re.escape(j), ln):
                    issues.append((fn, i, label, 'jargon', repr(ln)))
            if len(ln.strip()) >= 8:
                seen[ln.strip()].append((fn, label))
    for text, where in seen.items():
        files = {f for f, _ in where}
        if len(files) > 1 and '!' in text:
            issues.append(('*', 0, '', 'reused', '%r in %s' % (text, ', '.join(sorted(files)))))
    return issues


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--all', action='store_true')
    ap.add_argument('--md')
    a = ap.parse_args()
    rows = list(strings())
    if a.all or a.md:
        out = []
        cur = None
        for fn, i, label, lines in rows:
            if fn != cur:
                out.append('\n## %s\n' % fn)
                cur = fn
            out.append('- `%s` (line %d): %s' % (label or '-', i, ' / '.join(l for l in lines if l)))
        text = '# Toronto Games copy inventory\n' + '\n'.join(out) + '\n'
        if a.md:
            open(a.md, 'w').write(text)
            print('wrote %s (%d strings)' % (a.md, len(rows)))
        else:
            print(text)
    issues = lint(rows)
    print('%d strings, %d issue(s)' % (len(rows), len(issues)))
    for fn, i, label, kind, msg in issues:
        print('  %-7s %s:%s %s %s' % (kind, fn, i, label, msg))
    sys.exit(0)


if __name__ == '__main__':
    main()
