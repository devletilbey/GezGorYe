#!/usr/bin/env python3
import json, math, re, unicodedata
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


def infer_category(title: str) -> str:
    t = norm(title)
    if any(k in t for k in ['selale', 'şelale']):
        return 'waterfall'
    if any(k in t for k in ['muze', 'müze', 'muzesi', 'müzesi']):
        return 'museum'
    if any(k in t for k in ['gol', 'göl', 'kanyon', 'magara', 'mağara', 'yayla', 'plaj', 'koy', 'koyu', 'sahil', 'orman', 'park']):
        return 'nature'
    return 'historical'


def default_minutes(category: str, title: str) -> int:
    t = norm(title)
    base = {'museum': 90, 'historical': 75, 'waterfall': 70, 'nature': 80}.get(category, 75)
    if any(k in t for k in ['antik kent', 'oren yeri', 'ören yeri']):
        base += 30
    if 'milli park' in t:
        base += 20
    if 'kale' in t or 'hisar' in t:
        base += 15
    return min(150, max(45, base))


def jitter_coord(center_lat, center_lon, slot):
    # Small deterministic ring around city center for fallback entries lacking exact source match.
    angle = (slot * 37) % 360
    rad = math.radians(angle)
    r_lat = 0.045 + (slot % 4) * 0.015
    r_lon = 0.055 + (slot % 5) * 0.018
    return round(center_lat + math.sin(rad) * r_lat, 6), round(center_lon + math.cos(rad) * r_lon, 6)


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


def best_match_for_title(title, pois, used_indexes):
    title_n = norm(title)
    title_tokens = set(toks(title))
    best = None
    for i, poi in enumerate(pois):
        if i in used_indexes:
            continue
        name = poi.get('name', '')
        desc = poi.get('shortDescription', '')
        name_n = norm(name)
        desc_n = norm(desc)
        score = 0.0
        if title_n and (title_n in name_n or name_n in title_n):
            score = 6.0
        else:
            parts = [p.strip() for p in re.split(r'[/,&()]', title_n) if p.strip()]
            for p in parts:
                if len(p) >= 4 and p in name_n:
                    score = max(score, 4.8)
            if title_tokens:
                nt = set(toks(name))
                dt = set(toks(desc))
                overlap_name = len(title_tokens & nt) / len(title_tokens)
                overlap_all = len(title_tokens & (nt | dt)) / len(title_tokens)
                score = max(score, overlap_name * 4.0, overlap_all * 2.6)
                if overlap_name >= 0.6:
                    score += 0.8
        if best is None or score > best[1]:
            best = (i, score)
    if best and best[1] >= 1.8:
        return best
    return None


def make_fallback_poi(city, title, slot):
    category = infer_category(title)
    clat = float(city['center']['latitude'])
    clon = float(city['center']['longitude'])
    lat, lon = jitter_coord(clat, clon, slot)
    return {
        'name': title,
        'category': category,
        'coordinate': {'latitude': lat, 'longitude': lon},
        'shortDescription': 'Bu durak Tatilbudur oncelik listesine gore eklendi. Konum kesinlestirme iyilestirilecektir.',
        'recommendedVisitMinutes': default_minutes(category, title),
    }


def main():
    cities = json.loads(CITIES.read_text(encoding='utf-8'))
    priorities = json.loads(PRIOR.read_text(encoding='utf-8'))
    changed = 0
    for city in cities:
        plist = priorities.get(city['name'])
        if not plist:
            continue
        pois = list(city.get('pointsOfInterest', []))
        used = set()
        forced_head = []
        for slot, title in enumerate(plist):
            m = best_match_for_title(title, pois, used)
            if m:
                idx, _score = m
                poi = dict(pois[idx])
                poi['name'] = title
                forced_head.append(poi)
                used.add(idx)
            else:
                forced_head.append(make_fallback_poi(city, title, slot))

        ranked_tail = []
        for i, poi in enumerate(pois):
            if i in used:
                continue
            idx, strength = match_rank(poi, plist)
            ranked_tail.append((idx, -strength, i, poi))
        new_pois = forced_head + [poi for *_rest, poi in sorted(ranked_tail, key=lambda x: (x[0], x[1], x[2]))]
        if new_pois != city['pointsOfInterest']:
            city['pointsOfInterest'] = new_pois
            changed += 1
    CITIES.write_text(json.dumps(cities, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('cities_reordered', changed)

if __name__ == '__main__':
    main()
