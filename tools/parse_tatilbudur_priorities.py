#!/usr/bin/env python3
import json, re, sys, unicodedata
from pathlib import Path

CITIES_JSON = Path('/Users/serdarbasar/Desktop/GezGörYe/GezGorYe/Resources/cities.json')
SEPARATOR_RE = re.compile(r'\s+[–-]\s+')

cities = json.loads(CITIES_JSON.read_text(encoding='utf-8'))

def norm(s: str) -> str:
    m = str.maketrans({'Ç':'c','ç':'c','Ğ':'g','ğ':'g','İ':'i','I':'i','ı':'i','Ö':'o','ö':'o','Ş':'s','ş':'s','Ü':'u','ü':'u','â':'a','Â':'a'})
    s = s.translate(m)
    s = unicodedata.normalize('NFKD', s)
    s = ''.join(ch for ch in s if not unicodedata.combining(ch))
    return re.sub(r'[^a-z0-9]+','', s.lower())

city_by_norm = {norm(c['name']): c['name'] for c in cities}

text = sys.stdin.read()
lines = [ln.rstrip() for ln in text.splitlines()]

out = {}
current = None
for raw in lines:
    line = raw.strip()
    if not line:
        continue
    city_match = city_by_norm.get(norm(line))
    if city_match:
        current = city_match
        out.setdefault(current, [])
        continue
    if current is None:
        continue
    if ' – ' in line or ' - ' in line:
        title = SEPARATOR_RE.split(line, maxsplit=1)[0].strip()
        title = re.sub(r'\s+', ' ', title)
        if title and title not in out[current]:
            out[current].append(title)

json.dump(out, sys.stdout, ensure_ascii=False, indent=2)
print()
