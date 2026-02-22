#!/usr/bin/env python3
import json
import math
import re
import sys
import time
import ssl
import html as html_lib
import unicodedata
from dataclasses import dataclass
from html.parser import HTMLParser
from http.cookiejar import CookieJar
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from urllib.parse import urlencode
from urllib.request import Request, build_opener, HTTPCookieProcessor, HTTPSHandler

ROOT = Path(__file__).resolve().parents[1]
CITIES_JSON = ROOT / 'GezGorYe' / 'Resources' / 'cities.json'

UA = (
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
    'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'
)

CULTURE_BASE = 'https://kulturportali.gov.tr'
CULTURE_MAP_PAGE = CULTURE_BASE + '/harita/default.aspx'
CULTURE_GET_POIS = CULTURE_BASE + '/harita/default.aspx/GetirSehirSehberi'
CULTURE_GET_CATS = CULTURE_BASE + '/harita/default.aspx/GetirAltKategoriler'

TURKPATENT_BASE = 'https://ci.turkpatent.gov.tr'
TP_LIST_PAGE = TURKPATENT_BASE + '/cografi-isaretler/liste'
TP_CITY_LIST = TURKPATENT_BASE + '/Generals/CityList'
TP_GET_LIST = TURKPATENT_BASE + '/GeographicalSigns/GetList'

# Keep the manually curated Istanbul POIs from the project unless explicitly overwritten.
MANUAL_POI_LOCK_CITIES = {'İstanbul'}

TURKEY_BOUNDS = {
    'lat_min': 35.0,
    'lat_max': 43.5,
    'lon_min': 25.0,
    'lon_max': 45.0,
}

INFRA_NEGATIVE_KEYWORDS = [
    'köprü', 'kopru', 'baraj', 'tünel', 'tunel', 'viyadük', 'viyaduk', 'otogar',
    'havaalan', 'havalimani', 'hava liman', 'liman', 'terminal', 'sanayi',
    'organize', 'hes', 'hidroelektrik', 'maden', 'fabrika', 'rafineri', 'iskele',
    'viyadug', 'çevre yolu', 'cevre yolu', 'kavşak', 'kavsak', 'karayolu', 'yol',
]

LOW_TOURISM_LOCALITY_KEYWORDS = [
    'mahallesi', 'merkez mahallesi', 'köyü', 'koyu', 'mezra', 'mevkii'
]

RELIGIOUS_STRUCTURE_KEYWORDS = [
    'cami', 'camii', 'kilise', 'manastır', 'manastir', 'türbe', 'turbe'
]

LOCALITY_WORTHY_WHITELIST = [
    'cumalikizik', 'cumalıkızık', 'vakifli', 'vakıflı', 'yoruk koyu', 'yörük köyü'
]

POI_STRONG_POSITIVE = {
    'antik kent': 8,
    'ören yeri': 7,
    'oren yeri': 7,
    'unesco': 7,
    'müze': 6,
    'muze': 6,
    'saray': 6,
    'kale': 6,
    'hisar': 6,
    'cami': 5,
    'camii': 5,
    'kilise': 5,
    'manastır': 5,
    'manastir': 5,
    'medrese': 5,
    'külliye': 5,
    'kulliye': 5,
    'sarnıç': 5,
    'sarnic': 5,
    'çarşı': 4,
    'carsi': 4,
    'han': 4,
    'hamam': 4,
    'türbe': 4,
    'turbe': 4,
    'şelale': 7,
    'selale': 7,
    'kanyon': 6,
    'mağara': 6,
    'magara': 6,
    'milli park': 6,
    'tabiat park': 5,
    'göl': 4,
    'gol': 4,
    'yayla': 5,
    'plaj': 4,
    'koy': 4,
    'tepesi': 3,
    'seyir': 3,
}

POI_CATEGORY_HINTS = {
    'museum': ['müze', 'muze', 'müzeleri', 'arkeoloji müzeleri', 'müzesi'],
    'waterfall': ['şelale', 'selale'],
    'nature': [
        'milli park', 'tabiat', 'doğa', 'doga', 'göl', 'gol', 'yayla', 'kanyon',
        'mağara', 'magara', 'plaj', 'koy', 'sahil', 'koru', 'korusu', 'tepe',
        'vadisi', 'vadi', 'parkı', 'parki', 'orman'
    ],
}

FOOD_GROUP_POSITIVE = [
    'fırıncılık', 'firincilik', 'pastacılık', 'pastacilik', 'hamur işi', 'hamur isi',
    'tatlı', 'tatli', 'şekerleme', 'sekerleme', 'çikolata', 'cikolata', 'yemek',
    'çorba', 'corba', 'et ürün', 'et urun', 'süt ürün', 'sut urun', 'peynir',
    'dondurma', 'içecek', 'icecek', 'bal', 'arı ürün', 'ari urun', 'zeytin',
    'zeytinyağı', 'zeytinyagi'
]

FOOD_GROUP_NEGATIVE = [
    'halı', 'hali', 'kilim', 'dokuma', 'el sanat', 'el sanatı', 'taş', 'tas',
    'maden', 'bakır', 'bakir', 'bıçak', 'bicak', 'çini', 'cini', 'seramik',
    'ahşap', 'ahsap', 'oyası', 'oyasi', 'tekstil'
]

FOOD_DISH_KEYWORDS = {
    'kebap': 8, 'kebabı': 8, 'kebabi': 8, 'köfte': 7, 'kofte': 7, 'etliekmek': 8,
    'etli ekmek': 8, 'mantı': 7, 'manti': 7, 'pide': 7, 'börek': 7, 'borek': 7,
    'çorba': 6, 'corba': 6, 'pilav': 6, 'dolma': 6, 'sarma': 6, 'künefe': 7,
    'kunefe': 7, 'baklava': 7, 'kadayıf': 6, 'kadayif': 6, 'katmer': 6, 'helva': 6,
    'lokum': 6, 'tatlı': 6, 'tatli': 6, 'simit': 6, 'ekmek': 5, 'yoğurt': 5,
    'yogurt': 5, 'peynir': 5, 'sucuk': 6, 'pastırma': 6, 'pastirma': 6, 'ayran': 5,
    'şerbet': 4, 'serbet': 4, 'dondurma': 6, 'şalgam': 4, 'salgam': 4,
    'kahvesi': 5, 'kahve': 4
}

FOOD_RAW_INGREDIENT_PENALTY = [
    'fasulye', 'üzümü', 'uzumu', 'elması', 'elmasi', 'kirazı', 'kirazi', 'biberi',
    'biber', 'pirinci', 'pirinç', 'pirinc', 'cevizi', 'fındığı', 'findigi', 'inciri',
    'üzüm', 'armudu', 'domatesi', 'çileği', 'cilegi', 'patatesi'
]

CITY_FOOD_MUST_INCLUDE = {
    'Konya': ['Etliekmek', 'Fırın Kebabı'],
    'Gaziantep': ['Baklava', 'Katmer', 'Beyran'],
    'Kayseri': ['Mantısı', 'Pastırması'],
    'Hatay': ['Künefe', 'Tepsi Kebabı'],
    'İstanbul': ['Balık Ekmek', 'Sultanahmet Köfte', 'Islak Hamburger'],
}


class OptionParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_option = False
        self.current_value = None
        self.options: List[Tuple[str, str]] = []
        self._text = []

    def handle_starttag(self, tag, attrs):
        if tag.lower() == 'option':
            attrs = dict(attrs)
            self.in_option = True
            self.current_value = attrs.get('value', '')
            self._text = []

    def handle_data(self, data):
        if self.in_option:
            self._text.append(data)

    def handle_endtag(self, tag):
        if tag.lower() == 'option' and self.in_option:
            text = ''.join(self._text).strip()
            value = (self.current_value or '').strip()
            if value:
                self.options.append((value, html_lib.unescape(text)))
            self.in_option = False
            self.current_value = None
            self._text = []


def tr_fold(s: str) -> str:
    mapping = str.maketrans({
        'Ç': 'c', 'ç': 'c', 'Ğ': 'g', 'ğ': 'g', 'İ': 'i', 'I': 'i', 'ı': 'i',
        'Ö': 'o', 'ö': 'o', 'Ş': 's', 'ş': 's', 'Ü': 'u', 'ü': 'u'
    })
    s = s.translate(mapping)
    s = unicodedata.normalize('NFKD', s)
    s = ''.join(ch for ch in s if not unicodedata.combining(ch))
    s = re.sub(r'[^a-zA-Z0-9]+', '', s).lower()
    return s


def norm_ws(s: str) -> str:
    return re.sub(r'\s+', ' ', s or '').strip()


def tr_lower_text(s: str) -> str:
    return s.translate(str.maketrans({'I': 'ı', 'İ': 'i'})).lower()


def tr_upper_char(ch: str) -> str:
    return {'i': 'İ', 'ı': 'I'}.get(ch, ch.upper())


def tr_capitalize_word(word: str) -> str:
    if not word:
        return word
    lowered = tr_lower_text(word)
    for i, ch in enumerate(lowered):
        if ch.isalpha():
            return lowered[:i] + tr_upper_char(ch) + lowered[i + 1:]
    return lowered


def tr_titlecase_preserving_separators(text: str) -> str:
    parts = re.split(r'([\s/()\-]+)', text)
    out = []
    for part in parts:
        if not part or re.fullmatch(r'[\s/()\-]+', part):
            out.append(part)
            continue
        if part.isupper() or sum(1 for c in part if c.isalpha() and c.isupper()) >= max(2, sum(1 for c in part if c.isalpha()) * 0.7):
            out.append(tr_capitalize_word(part))
        else:
            out.append(part)
    return ''.join(out)


def strip_html(s: str) -> str:
    s = html_lib.unescape(s or '')
    s = re.sub(r'<br\s*/?>', ' ', s, flags=re.I)
    s = re.sub(r'<[^>]+>', ' ', s)
    s = norm_ws(s)
    return s


def low_tr(s: str) -> str:
    return tr_fold(s)


def title_quality_name(raw: str) -> str:
    raw = norm_ws(html_lib.unescape(raw or ''))
    if not raw:
        return raw
    letters = [c for c in raw if c.isalpha()]
    if letters:
        upper_ratio = sum(1 for c in letters if c.isupper()) / len(letters)
        if upper_ratio > 0.75:
            return norm_ws(tr_titlecase_preserving_separators(raw))
    return raw


def in_turkey(lat: float, lon: float) -> bool:
    return (TURKEY_BOUNDS['lat_min'] <= lat <= TURKEY_BOUNDS['lat_max'] and
            TURKEY_BOUNDS['lon_min'] <= lon <= TURKEY_BOUNDS['lon_max'])


@dataclass
class CandidatePOI:
    name: str
    lat: float
    lon: float
    desc: str
    url: str
    source_category_name: str
    icon_code: str
    featured: int
    score: float
    app_category: str
    minutes: int


class HttpClient:
    def __init__(self):
        self.opener = build_opener(
            HTTPCookieProcessor(CookieJar()),
            HTTPSHandler(context=self._ssl_context()),
        )

    @staticmethod
    def _ssl_context():
        try:
            import certifi  # type: ignore
            return ssl.create_default_context(cafile=certifi.where())
        except Exception:
            # Fallback for environments where CA bundle is not available.
            return ssl._create_unverified_context()

    def get(self, url: str, headers: Optional[Dict[str, str]] = None, timeout: int = 30) -> str:
        req = Request(url, headers={**({'User-Agent': UA}), **(headers or {})})
        with self.opener.open(req, timeout=timeout) as resp:
            return resp.read().decode('utf-8', errors='replace')

    def post_json(self, url: str, payload: dict, headers: Optional[Dict[str, str]] = None, timeout: int = 30):
        body = json.dumps(payload).encode('utf-8')
        h = {'User-Agent': UA, 'Content-Type': 'application/json; charset=UTF-8'}
        if headers:
            h.update(headers)
        req = Request(url, data=body, headers=h, method='POST')
        with self.opener.open(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode('utf-8', errors='replace'))

    def post_form(self, url: str, data: dict, headers: Optional[Dict[str, str]] = None, timeout: int = 30):
        body = urlencode(data).encode('utf-8')
        h = {'User-Agent': UA, 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'}
        if headers:
            h.update(headers)
        req = Request(url, data=body, headers=h, method='POST')
        with self.opener.open(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode('utf-8', errors='replace'))


def parse_culture_city_options(html: str) -> List[Tuple[str, str]]:
    parser = OptionParser()
    parser.feed(html)
    # The page has multiple select elements; keep only city-slug options (lowercase latin, no hyphens mostly)
    city_opts = []
    for value, text in parser.options:
        if re.fullmatch(r'[a-z]+', value) and text and text[0].isalpha() and value not in {'', 'new'}:
            city_opts.append((value, text))
    # Deduplicate while preserving order
    seen = set()
    out = []
    for v, t in city_opts:
        if v in seen:
            continue
        seen.add(v)
        out.append((v, t))
    return out


def parse_ilgenelbilgiid(html: str) -> Optional[str]:
    m = re.search(r'var\s+ilgenelbilgiid\s*=\s*"(\d+)"', html)
    return m.group(1) if m else None


def fetch_culture_category_map(client: HttpClient) -> Dict[str, str]:
    res = client.post_json(CULTURE_GET_CATS, {'listeAdi': 'GEZILECEK_YER_TURLERI-5'})
    raw = res.get('d', '[]')
    arr = json.loads(raw)
    return {str(x.get('Kod', '')).strip(): norm_ws(x.get('Ad', '')) for x in arr}


def culture_to_candidates(city_name: str, items: List[dict], category_map: Dict[str, str]) -> List[CandidatePOI]:
    out: List[CandidatePOI] = []
    city_fold = tr_fold(city_name)
    for x in items:
        try:
            lat = float(x.get('latitude'))
            lon = float(x.get('longitude'))
        except Exception:
            continue
        if not in_turkey(lat, lon):
            continue

        raw_name = title_quality_name(x.get('title', ''))
        name = norm_ws(raw_name.strip('-–— '))
        if not name or len(name) < 3:
            continue

        desc = strip_html(x.get('description', ''))
        if not desc:
            desc = 'Bu şehirde öne çıkan bir gezi durağı.'

        icon_url = x.get('iconUrl', '') or ''
        m = re.search(r'5-(\d+)\.png', icon_url)
        icon_code = m.group(1) if m else ''
        source_category_name = category_map.get(icon_code, '')

        lf_name = low_tr(name)
        lf_desc = low_tr(desc)
        lf_cat = low_tr(source_category_name)
        text = f'{lf_name} {lf_desc} {lf_cat}'

        # Hard reject obvious infrastructure / non-tourism transport records unless explicitly whitelisted historical engineering sites.
        negative_hits = sum(1 for k in INFRA_NEGATIVE_KEYWORDS if k in text)
        strong_positive_hits = sum(v for k, v in POI_STRONG_POSITIVE.items() if k in text)
        historic_bridge_whitelist = any(k in text for k in [
            'taş köprü', 'tas kopru', 'malabadi', 'uzunköprü', 'uzunkopru',
            'justinianus', 'tarihi köprü', 'tarihi kopru'
        ])
        titus_tunnel_whitelist = 'titus tüneli' in text or 'titus tuneli' in text
        if 'baraj' in text:
            continue
        if ('tünel' in text or 'tunel' in text) and not titus_tunnel_whitelist:
            continue
        if ('köprü' in text or 'kopru' in text) and not historic_bridge_whitelist:
            continue
        if negative_hits and strong_positive_hits < 6:
            continue

        # Reject low-value locality-level religious stops (village/neighborhood mosques etc.)
        has_locality_marker = any(k in text for k in LOW_TOURISM_LOCALITY_KEYWORDS)
        has_religious_marker = any(k in text for k in RELIGIOUS_STRUCTURE_KEYWORDS)
        locality_whitelisted = any(k in text for k in LOCALITY_WORTHY_WHITELIST)
        if has_locality_marker and has_religious_marker and not locality_whitelisted:
            continue

        # Generic city-level placeholders are low quality for POI list.
        if lf_name in {city_fold, city_fold + 'merkez', city_fold + 'ilmerkezi'}:
            continue

        score = 0.0
        score += float(x.get('featured') or 0) * 2.0
        score += strong_positive_hits
        score += min(len(desc) / 220.0, 2.5)

        if 'unesco' in text:
            score += 4
        if 'antik kent' in text or 'ören yeri' in text or 'oren yeri' in text:
            score += 3
        if 'müze' in text or 'muze' in text:
            score += 2
        if 'milli park' in text or 'tabiat park' in text:
            score += 2
        if 'şelale' in text or 'selale' in text:
            score += 2
        if has_locality_marker and not locality_whitelisted:
            score -= 2.5

        if any(k in text for k in POI_CATEGORY_HINTS['waterfall']):
            app_category = 'waterfall'
            score += 1.5
        elif any(k in text for k in POI_CATEGORY_HINTS['museum']) or 'müze' in low_tr(source_category_name) or 'muze' in low_tr(source_category_name):
            app_category = 'museum'
            score += 1.2
        elif any(k in text for k in POI_CATEGORY_HINTS['nature']) or any(k in low_tr(source_category_name) for k in ['park', 'göl', 'gol', 'yayla', 'mağara', 'magara', 'kanyon']):
            app_category = 'nature'
            score += 0.8
        else:
            app_category = 'historical'
            score += 0.8

        if app_category == 'museum':
            minutes = 90
        elif app_category == 'historical':
            minutes = 75
        elif app_category == 'waterfall':
            minutes = 60
        else:
            minutes = 70

        if 'saray' in text:
            minutes += 30
        if 'antik kent' in text or 'ören yeri' in text or 'oren yeri' in text:
            minutes += 30
        if 'milli park' in text:
            minutes += 25
        if 'kale' in text or 'hisar' in text:
            minutes += 15
        if 'şelale' in text or 'selale' in text:
            minutes += 10
        minutes = max(40, min(150, minutes))

        short_desc = desc[:220].rstrip()
        if len(desc) > 220:
            short_desc = short_desc.rsplit(' ', 1)[0] + '...'

        out.append(CandidatePOI(
            name=name,
            lat=lat,
            lon=lon,
            desc=short_desc,
            url=x.get('url', '') or '',
            source_category_name=source_category_name,
            icon_code=icon_code,
            featured=int(x.get('featured') or 0),
            score=score,
            app_category=app_category,
            minutes=minutes,
        ))
    return out


def dedupe_pois(cands: List[CandidatePOI]) -> List[CandidatePOI]:
    seen = set()
    out = []
    for c in sorted(cands, key=lambda x: (-x.score, x.name)):
        key = tr_fold(re.sub(r'\b(muzesi|muzeler|muzeleri|camii|cami|kalesi|kale|sarayi|sarayı)\b', '', low_tr(c.name)))
        key = key[:60]
        key2 = (key, round(c.lat, 3), round(c.lon, 3))
        if key2 in seen or key in seen:
            continue
        seen.add(key2)
        seen.add(key)
        out.append(c)
    return out


def select_pois(city_name: str, cands: List[CandidatePOI], existing_pois: List[dict]) -> List[dict]:
    if city_name in MANUAL_POI_LOCK_CITIES:
        return existing_pois

    cands = dedupe_pois(cands)
    if not cands:
        return existing_pois

    # Soft diversity targets to avoid all-museum / all-generic selections.
    buckets: Dict[str, List[CandidatePOI]] = {'historical': [], 'museum': [], 'nature': [], 'waterfall': []}
    for c in cands:
        buckets.setdefault(c.app_category, []).append(c)

    target = 12
    if len(cands) >= 25:
        target = 14
    if len(cands) <= 8:
        target = len(cands)

    selected: List[CandidatePOI] = []
    selected_names = set()
    subtype_counts: Dict[str, int] = {}

    def subtype_key(c: CandidatePOI) -> str:
        t = low_tr(c.name + ' ' + c.source_category_name)
        if 'cami' in t:
            return 'cami'
        if 'kilise' in t:
            return 'kilise'
        if 'manastir' in t or 'manastır' in t:
            return 'manastir'
        if 'turbe' in t or 'türbe' in t:
            return 'turbe'
        if 'medrese' in t:
            return 'medrese'
        if 'muze' in t or 'müze' in t:
            return 'muze'
        if 'kale' in t or 'hisar' in t:
            return 'kale'
        return 'other'

    def subtype_limit(c: CandidatePOI) -> int:
        key = subtype_key(c)
        if key == 'cami':
            return 3
        if key in {'turbe', 'kilise', 'manastir'}:
            return 2
        if key == 'medrese':
            return 3
        return 99

    # Ensure core diversity where possible.
    for cat in ('historical', 'museum', 'nature', 'waterfall'):
        if buckets.get(cat):
            top = buckets[cat][0]
            if top.name not in selected_names:
                sk = subtype_key(top)
                if subtype_counts.get(sk, 0) >= subtype_limit(top):
                    continue
                selected.append(top)
                selected_names.add(top.name)
                subtype_counts[sk] = subtype_counts.get(sk, 0) + 1

    for c in cands:
        if len(selected) >= target:
            break
        if c.name in selected_names:
            continue

        # Limit overconcentration in one category unless city has few alternatives.
        cat_count = sum(1 for x in selected if x.app_category == c.app_category)
        max_cat = 6 if target >= 14 else 5
        if cat_count >= max_cat and len(buckets.get(c.app_category, [])) > max_cat:
            continue

        sk = subtype_key(c)
        if subtype_counts.get(sk, 0) >= subtype_limit(c) and len(cands) > target + 3:
            continue

        selected.append(c)
        selected_names.add(c.name)
        subtype_counts[sk] = subtype_counts.get(sk, 0) + 1

    if len(selected) < min(6, len(cands)):
        for c in cands:
            if c.name not in selected_names:
                sk = subtype_key(c)
                if subtype_counts.get(sk, 0) >= subtype_limit(c) and len(cands) > 8:
                    continue
                selected.append(c)
                selected_names.add(c.name)
                subtype_counts[sk] = subtype_counts.get(sk, 0) + 1
            if len(selected) >= min(6, len(cands)):
                break

    selected = sorted(selected, key=lambda x: (-x.score, x.name))[:target]

    return [
        {
            'name': c.name,
            'category': c.app_category,
            'coordinate': {'latitude': round(c.lat, 6), 'longitude': round(c.lon, 6)},
            'shortDescription': c.desc,
            'recommendedVisitMinutes': c.minutes,
        }
        for c in selected
    ]


def tp_seed(client: HttpClient):
    client.get(TP_LIST_PAGE)


def tp_fetch_city_list(client: HttpClient) -> List[dict]:
    tp_seed(client)
    return client.post_form(
        TP_CITY_LIST,
        {},
        headers={
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': TP_LIST_PAGE,
            'Origin': TURKPATENT_BASE,
        },
    )


def tp_fetch_city_foods(client: HttpClient, plate_code: str) -> List[dict]:
    page_ref = f'{TP_LIST_PAGE}?il={int(plate_code)}'
    client.get(page_ref)
    rows: List[dict] = []
    page = 1
    total = None
    seen_ids = set()
    while True:
        data = client.post_form(
            TP_GET_LIST,
            {
                'CityId': str(int(plate_code)),
                'TypeId': '',
                'ProductGroupId': '',
                'PageLength': str(page),
                'Name': '',
            },
            headers={
                'X-Requested-With': 'XMLHttpRequest',
                'Referer': page_ref,
                'Origin': TURKPATENT_BASE,
            },
        )
        if not data.get('IsSuccess'):
            break
        batch = data.get('GeographicalSignAttributeList') or []
        if total is None:
            total = int(data.get('FilteredCount') or data.get('TotalCount') or len(batch))
        if not batch:
            break
        for row in batch:
            rid = row.get('Id')
            if rid in seen_ids:
                continue
            seen_ids.add(rid)
            rows.append(row)
        if total is None:
            break
        if len(rows) >= total:
            break
        page += 1
        if page > 60:
            break
        time.sleep(0.05)
    return rows


def food_row_score(city_name: str, row: dict) -> float:
    name = norm_ws(row.get('Name', ''))
    group = norm_ws(row.get('ProductGroupName', ''))
    status = norm_ws(row.get('StatusName', ''))
    city = norm_ws(row.get('CityName', ''))
    t = low_tr(name)
    g = low_tr(group)
    score = 0.0

    if any(k in g for k in FOOD_GROUP_NEGATIVE):
        return -999

    if any(k in g for k in FOOD_GROUP_POSITIVE):
        score += 4
    if any(k in t for k in FOOD_GROUP_POSITIVE):
        score += 2

    for k, w in FOOD_DISH_KEYWORDS.items():
        if k in t:
            score += w

    if any(k in t for k in FOOD_RAW_INGREDIENT_PENALTY):
        score -= 2.5

    if status and 'tescil' in low_tr(status):
        score += 1
    if city and low_tr(city_name) == low_tr(city):
        score += 0.5
    if low_tr(city_name) in t:
        score += 1.5

    # Prefer concise consumer-facing food names over long institutional labels.
    score += max(0, 2.0 - (len(name) / 60.0))
    return score


def is_food_row(row: dict) -> bool:
    name = norm_ws(row.get('Name', ''))
    group = norm_ws(row.get('ProductGroupName', ''))
    t = low_tr(name)
    g = low_tr(group)

    if any(k in g for k in FOOD_GROUP_NEGATIVE):
        return False

    # Strong keep by group or dish-name keyword.
    if any(k in g for k in FOOD_GROUP_POSITIVE):
        return True
    if any(k in t for k in FOOD_DISH_KEYWORDS):
        return True

    # Allow some local agricultural GI entries as fallback only if edible and common in travel context.
    edible_group_hints = ['meyve', 'sebze', 'bakliyat', 'tarım', 'tarim', 'bal', 'peynir']
    return any(k in g for k in edible_group_hints)


def select_foods(city_name: str, rows: List[dict], existing_foods: List[str]) -> List[str]:
    current = [norm_ws(x) for x in existing_foods if norm_ws(x)]
    if not rows:
        return current

    filtered = []
    for row in rows:
        if not is_food_row(row):
            continue
        name = norm_ws(row.get('Name', ''))
        if not name:
            continue
        filtered.append((food_row_score(city_name, row), row))

    filtered.sort(key=lambda x: (-x[0], norm_ws(x[1].get('Name', ''))))

    selected: List[str] = []
    seen = set()
    group_counts: Dict[str, int] = {}

    def add_food(name: str, group: str = ''):
        key = tr_fold(name)
        if key in seen:
            return False
        seen.add(key)
        selected.append(name)
        if group:
            group_counts[group] = group_counts.get(group, 0) + 1
        return True

    # Manual iconic anchors for travel UX (especially where GI lists skew agricultural).
    for city_key, musts in CITY_FOOD_MUST_INCLUDE.items():
        if low_tr(city_name) == low_tr(city_key):
            for m in musts:
                # Prefer exact/partial match from GI; otherwise keep current if user-facing iconic item exists.
                match = None
                for _, row in filtered:
                    n = norm_ws(row.get('Name', ''))
                    if low_tr(m) in low_tr(n) or low_tr(n) in low_tr(m):
                        match = n
                        break
                if match:
                    add_food(match, 'manual')
                else:
                    for cur in current:
                        if low_tr(m) in low_tr(cur) or low_tr(cur) in low_tr(m):
                            add_food(cur, 'manual')
                            break

    for score, row in filtered:
        name = norm_ws(row.get('Name', ''))
        group_name = norm_ws(row.get('ProductGroupName', ''))
        group_key = low_tr(group_name)[:36]
        if group_counts.get(group_key, 0) >= 4:
            continue
        add_food(name, group_key)
        if len(selected) >= 12:
            break

    # Preserve strong current iconic foods if not represented.
    for cur in current:
        if len(selected) >= 12:
            break
        t = low_tr(cur)
        if any(k in t for k in ['balık ekmek', 'balik ekmek', 'ıslak hamburger', 'islak hamburger', 'sultanahmet kofte', 'sultanahmet köfte']):
            add_food(cur, 'current-iconic')

    # Guarantee minimum list size from existing values.
    for cur in current:
        if len(selected) >= max(6, min(12, len(current))):
            break
        add_food(cur, 'fallback')

    if not selected:
        return current
    return selected[:12]


def build_portal_city_map(client: HttpClient) -> Tuple[List[Tuple[str, str]], Dict[str, str], Dict[str, str]]:
    html = client.get(CULTURE_MAP_PAGE + '?il=istanbul')
    options = parse_culture_city_options(html)
    slug_to_name = {slug: name for slug, name in options}
    slug_to_id: Dict[str, str] = {}
    for idx, (slug, _) in enumerate(options, 1):
        page_html = client.get(f'{CULTURE_MAP_PAGE}?il={slug}')
        ilid = parse_ilgenelbilgiid(page_html)
        if ilid:
            slug_to_id[slug] = ilid
        if idx % 10 == 0:
            print(f'[culture] city page ids {idx}/{len(options)}', flush=True)
        time.sleep(0.03)
    return options, slug_to_name, slug_to_id


def fetch_city_pois_from_culture(client: HttpClient, il_id: str) -> List[dict]:
    resp = client.post_json(
        CULTURE_GET_POIS,
        {
            'ilGenelBilgiId': str(il_id),
            'listeAdi': 'GEZILECEK_YER_TURLERI-5',
            'turKod': '',
            'kelime': '',
        },
        headers={'X-Requested-With': 'XMLHttpRequest', 'Referer': CULTURE_MAP_PAGE},
    )
    raw = resp.get('d', '[]')
    try:
        return json.loads(raw)
    except Exception:
        return []


def main():
    cities = json.loads(CITIES_JSON.read_text(encoding='utf-8'))
    city_index = {tr_fold(c['name']): i for i, c in enumerate(cities)}

    culture_client = HttpClient()
    tp_client = HttpClient()

    print('[1/6] Fetching official culture portal city map...', flush=True)
    options, _, slug_to_ilid = build_portal_city_map(culture_client)
    category_map = fetch_culture_category_map(culture_client)
    print(f'[culture] {len(options)} city slugs, {len(slug_to_ilid)} ids, {len(category_map)} categories', flush=True)

    print('[2/6] Refreshing POIs from Kültür Portalı...', flush=True)
    poi_stats = []
    for idx, (slug, portal_name) in enumerate(options, 1):
        key = tr_fold(portal_name)
        if key not in city_index:
            # Fallback for naming differences, e.g. K.Maraş variants if any.
            candidates = [k for k in city_index if key in k or k in key]
            if len(candidates) == 1:
                key = candidates[0]
            else:
                print(f'  [warn] city not matched in app data: {portal_name} ({slug})', flush=True)
                continue
        ilid = slug_to_ilid.get(slug)
        if not ilid:
            print(f'  [warn] missing ilGenelBilgiId for {portal_name}', flush=True)
            continue

        city = cities[city_index[key]]
        try:
            raw_items = fetch_city_pois_from_culture(culture_client, ilid)
            cands = culture_to_candidates(city['name'], raw_items, category_map)
            selected = select_pois(city['name'], cands, city.get('pointsOfInterest', []))
            if selected:
                city['pointsOfInterest'] = selected
            poi_stats.append((city['name'], len(raw_items), len(cands), len(city['pointsOfInterest'])))
        except Exception as e:
            print(f'  [warn] POI refresh failed for {city["name"]}: {e}', flush=True)
        if idx % 5 == 0:
            print(f'  [poi] {idx}/{len(options)} processed', flush=True)
        time.sleep(0.05)

    print('[3/6] Fetching official TÜRKPATENT city list...', flush=True)
    tp_cities = tp_fetch_city_list(tp_client)
    tp_map = {tr_fold(x.get('Name', '')): x.get('PlateCode') for x in tp_cities if x.get('Name') and x.get('PlateCode')}
    print(f'[turkpatent] {len(tp_map)} city mappings', flush=True)

    print('[4/6] Refreshing local foods from TÜRKPATENT GI records...', flush=True)
    food_stats = []
    for idx, city in enumerate(cities, 1):
        key = tr_fold(city['name'])
        plate = tp_map.get(key)
        if not plate:
            # Fallback for naming differences
            for k, v in tp_map.items():
                if k == key or k in key or key in k:
                    plate = v
                    break
        if not plate:
            print(f'  [warn] no plate match for {city["name"]}', flush=True)
            continue
        try:
            rows = tp_fetch_city_foods(tp_client, plate)
            selected_foods = select_foods(city['name'], rows, city.get('localFoods', []))
            if selected_foods:
                city['localFoods'] = selected_foods
            food_stats.append((city['name'], len(rows), len(city['localFoods'])))
        except Exception as e:
            print(f'  [warn] food refresh failed for {city["name"]}: {e}', flush=True)
        if idx % 5 == 0:
            print(f'  [food] {idx}/{len(cities)} processed', flush=True)
        time.sleep(0.08)

    print('[5/6] Writing cities.json...', flush=True)
    CITIES_JSON.write_text(json.dumps(cities, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

    print('[6/6] Summary', flush=True)
    if poi_stats:
        poi_counts = [x[3] for x in poi_stats]
        print(f'  POI cities updated: {len(poi_stats)} | min={min(poi_counts)} max={max(poi_counts)} avg={sum(poi_counts)/len(poi_counts):.2f}', flush=True)
    if food_stats:
        food_counts = [x[2] for x in food_stats]
        print(f'  Food cities updated: {len(food_stats)} | min={min(food_counts)} max={max(food_counts)} avg={sum(food_counts)/len(food_counts):.2f}', flush=True)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
