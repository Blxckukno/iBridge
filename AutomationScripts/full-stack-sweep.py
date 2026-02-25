#!/usr/bin/env python3
import os
import re
import json
from datetime import datetime, timezone

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
WEBSITE = os.path.join(ROOT, 'Website')
APP = os.path.join(ROOT, 'BackendServices', 'backend', 'app.py')


def collect_html_files():
    html = []
    for dp, _, fs in os.walk(WEBSITE):
        for f in fs:
            if f.lower().endswith('.html'):
                html.append(os.path.join(dp, f))
    return sorted(html)


def local_ref(u):
    return not re.match(r'^(https?:|mailto:|tel:|javascript:|data:|#)', u, re.I)


def check_links(files):
    missing = []
    for path in files:
        text = open(path, 'r', encoding='utf-8', errors='ignore').read()
        refs = re.findall(r'href\s*=\s*"([^"]+)"', text, re.I)
        refs += re.findall(r"href\s*=\s*'([^']+)'", text, re.I)
        refs += re.findall(r'src\s*=\s*"([^"]+)"', text, re.I)
        refs += re.findall(r"src\s*=\s*'([^']+)'", text, re.I)
        base = os.path.dirname(path)
        for ref in refs:
            if not ref or not local_ref(ref):
                continue
            clean = ref.split('?')[0].split('#')[0]
            target = os.path.normpath(os.path.join(base, clean.replace('/', os.sep)))
            if not os.path.exists(target):
                missing.append({'file': os.path.relpath(path, ROOT), 'ref': ref, 'resolved': os.path.relpath(target, ROOT)})
    return missing


def check_onclick(files):
    missing = []
    for path in files:
        text = open(path, 'r', encoding='utf-8', errors='ignore').read()
        called = set(re.findall(r'onclick\s*=\s*"\s*([A-Za-z_][A-Za-z0-9_]*)\s*\(', text))
        called |= set(re.findall(r"onclick\s*=\s*'\s*([A-Za-z_][A-Za-z0-9_]*)\s*\(", text))
        declared = set(re.findall(r'function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(', text))
        for fn in sorted(called):
            if fn not in declared:
                missing.append({'file': os.path.relpath(path, ROOT), 'function': fn})
    return missing


def backend_routes():
    text = open(APP, 'r', encoding='utf-8', errors='ignore').read()
    return sorted(set(re.findall(r"@app\.route\(\s*['\"]([^'\"]+)['\"]", text)))


def frontend_api_calls():
    calls = []
    for dp, _, fs in os.walk(WEBSITE):
        for f in fs:
            if f.endswith(('.html', '.js')):
                p = os.path.join(dp, f)
                t = open(p, 'r', encoding='utf-8', errors='ignore').read()
                for m in re.finditer(r"fetch\(\s*['\"]([^'\"]+)['\"]", t):
                    u = m.group(1)
                    if u.startswith('/api/'):
                        calls.append({'file': os.path.relpath(p, ROOT), 'api': u.split('?')[0]})
    return calls


def main():
    files = collect_html_files()
    routes = backend_routes()
    calls = frontend_api_calls()
    missing_apis = [c for c in calls if c['api'] not in routes and '/api/courses/' not in c['api']]

    report = {
        'generated_at': datetime.now(timezone.utc).isoformat(),
        'html_files': len(files),
        'backend_routes': len(routes),
        'frontend_api_calls': len(calls),
        'missing_links_count': 0,
        'missing_onclick_count': 0,
        'missing_api_count': len(missing_apis),
        'missing_links': [],
        'missing_onclick': [],
        'missing_api_calls': missing_apis[:100],
        'status': 'pass'
    }

    missing_links = check_links(files)
    missing_onclick = check_onclick(files)

    report['missing_links_count'] = len(missing_links)
    report['missing_onclick_count'] = len(missing_onclick)
    report['missing_links'] = missing_links[:200]
    report['missing_onclick'] = missing_onclick[:200]

    if report['missing_links_count'] or report['missing_onclick_count'] or report['missing_api_count']:
        report['status'] = 'fail'

    stamp = datetime.now().strftime('%Y%m%d-%H%M%S')
    out = os.path.join(ROOT, 'Documentation', 'reports', f'full-sweep-{stamp}.json')
    with open(out, 'w', encoding='utf-8') as fp:
        json.dump(report, fp, indent=2)
    print(out)
    print(json.dumps({'status': report['status'], 'missing_links': report['missing_links_count'], 'missing_onclick': report['missing_onclick_count'], 'missing_api': report['missing_api_count']}, indent=2))


if __name__ == '__main__':
    main()
