# Crawl CYB Conf site pages: status, broken images/links, leftover SWC text
import re, requests
from urllib.parse import urljoin, urlparse
from html.parser import HTMLParser

BASE = open('/app/frontend/.env').read().split('REACT_APP_BACKEND_URL=')[1].split('\n')[0].rstrip('/')
PAGES = ['/', '/call-for-papers/', '/call-for-special-sessions/', '/program/', '/committee/', '/discover-calabria/', '/social-event/',
         '/registration', '/contact', '/sponsors', '/venue/unical_congress_center/',
         '/travel/getting-there/', '/travel/accommodation/', '/travel/visa-information']
LEFT = re.compile(r'SWC\s*2026|Smart World Congress|SWC-IEEE|smartworld|\bSWC\b', re.I)

class P(HTMLParser):
    def __init__(s):
        super().__init__(); s.imgs=[]; s.links=[]
    def handle_starttag(s, t, a):
        a=dict(a)
        if t=='img' and a.get('src'): s.imgs.append(a['src'])
        if t=='a' and a.get('href'): s.links.append(a['href'])
        if t=='link' and a.get('href') and a.get('rel') in ('stylesheet','icon'): s.imgs.append(a['href'])
        if t=='script' and a.get('src'): s.imgs.append(a['src'])
        st=a.get('style') or ''
        for u in re.findall(r"url\(['\"]?([^'\")]+)", st): s.imgs.append(u)

checked={}
def chk(u):
    if u in checked: return checked[u]
    try:
        r=requests.get(u,timeout=20,allow_redirects=True); checked[u]=r.status_code
    except Exception as e: checked[u]=str(e)
    return checked[u]

for p in PAGES:
    r=requests.get(BASE+p,timeout=20)
    print(f"\n== {p} -> {r.status_code}")
    txt=r.text
    hits=set(m.group(0) for m in LEFT.finditer(txt))
    if hits:
        for m in LEFT.finditer(txt):
            print("  LEFTOVER:", repr(txt[max(0,m.start()-80):m.end()+40].replace('\n',' ')))
    pr=P(); pr.feed(txt)
    for s in set(pr.imgs):
        u=urljoin(BASE+p,s)
        if urlparse(u).netloc!=urlparse(BASE).netloc: continue
        c=chk(u)
        if c!=200: print("  BROKEN ASSET:", s, c)
    for h in set(pr.links):
        if h.startswith(('mailto:','tel:','javascript:','#')): continue
        u=urljoin(BASE+p,h).split('#')[0]
        if urlparse(u).netloc!=urlparse(BASE).netloc: continue
        c=chk(u)
        if c!=200: print("  BROKEN LINK:", h, c)
