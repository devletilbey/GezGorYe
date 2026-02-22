#!/usr/bin/env python3
import json, re, unicodedata
from pathlib import Path

ROOT = Path('/Users/serdarbasar/Desktop/GezGörYe')
CITIES = ROOT / 'GezGorYe/Resources/cities.json'
PRIOR = ROOT / 'GezGorYe/Resources/tatilbudur_priorities.json'

STOP = {'ve','ile','veya','the','of','da','de','ve','bir','antik','kenti','muzesi','müzesi','camii','camii','cami','kalesi','kale','plaji','plajı','milli','parki','parkı'}


def norm(s: str) -> str:
    m = str.maketrans({'Ç':'c','ç':'c','Ğ':'g','ğ':'g','İ':'i','I':'i','ı':'i','Ö':'o','ö':'o','Ş':'s','ş':'s','Ü':'u','ü':'u','â':'a','Â':'a','ê':'e','Ê':'e','î':'i','Î':'i','û':'u','Û':'u'})
    s = s.translate(m)
    s = unicodedata.normalize('NFKD', s)
    s = ''.join(ch for ch in s if not unicodedata.combining(ch))
    s = s.lower()
    s = re.sub(r'[^a-z0-9 ]+', ' ', s)
    s = re.sub(r'\s+', ' ', s).strip()
    return s


def toks(s: str):
    return [t for t in norm(s).split() if len(t) >= 3 and t not in STOP]


def match_rank(poi, priorities):
    name = poi['name']
    desc = poi.get('shortDescription','')
    name_n = norm(name)
    desc_n = norm(desc)
    name_tokens = set(toks(name))
    desc_tokens = set(toks(desc))
    combined_tokens = name_tokens | desc_tokens

    best = (999, 0.0)
    for idx, title in enumerate(priorities):
        title_n = norm(title)
        title_tokens = set(toks(title))
        # Strong exact/substring on name first
        if title_n and (title_n in name_n or name_n in title_n):
            return (idx, 3.0)
        # Parenthetical/compound titles: any side exact in name
        parts = [p.strip() for p in re.split(r'[/,&()]', title_n) if p.strip()]
        for p in parts:
            if len(p) >= 4 and p in name_n:
                return (idx, 2.8)
        if title_tokens:
            overlap_name = len(title_tokens & name_tokens) / len(title_tokens)
            overlap_all = len(title_tokens & combined_tokens) / len(title_tokens)
            score = max(overlap_name * 2.2, overlap_all * 1.6)
            if overlap_name >= 0.6:
                score += 0.7
            if overlap_all >= 0.8:
                score += 0.4
            if score > best[1]:
                best = (idx, score)
    return best


def main():
    cities = json.loads(CITIES.read_text(encoding='utf-8'))
    priorities = json.loads(PRIOR.read_text(encoding='utf-8'))
    changed = 0
    for city in cities:
        plist = priorities.get(city['name'])
        if not plist:
            continue
        ranked = []
        for i, poi in enumerate(city['pointsOfInterest']):
            idx, strength = match_rank(poi, plist)
            ranked.append((idx, -strength, i, poi))
        new_pois = [poi for *_rest, poi in sorted(ranked, key=lambda x: (x[0], x[1], x[2]))]
        if new_pois != city['pointsOfInterest']:
            city['pointsOfInterest'] = new_pois
            changed += 1
    CITIES.write_text(json.dumps(cities, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('cities_reordered', changed)

if __name__ == '__main__':
    main()
