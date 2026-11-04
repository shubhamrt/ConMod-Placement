# Basic checks on the placement rules in placement.py.
# Run: python test_placement.py

import sys
from collections import Counter
from placement import largest_gap, scaled_gap, proportional, cell_grid, MIN_SUBGAP

GAPS = [12.0, 5.58, 3.2, 2.0, 0.8, 0.15]
H = [0.20, 0.35, 0.15, 0.50, 0.25, 0.30]
PAIRS = list(zip(GAPS, H))
TRANSECT = 75.0
NS = [0, 1, 3, 5, 10, 50]
fails = []


def check(ok, msg):
    if not ok:
        fails.append(msg)


def no_new_short_gaps(out, gin):
    short = Counter(round(g, 6) for g in gin if g < MIN_SUBGAP - 1e-9)
    for g in out:
        if g < MIN_SUBGAP - 1e-9:
            k = round(g, 6)
            if short.get(k, 0) <= 0:
                return False
            short[k] -= 1
    return True


def run(name, fn, *extra):
    for n in NS:
        gin = list(PAIRS) if fn is scaled_gap else list(GAPS)
        out, placed = fn(gin, n, *extra)
        tag = f'{name} N={n}'
        check(abs(sum(out) - sum(GAPS)) < 1e-6, f'{tag}: total gap length changed')
        check(len(out) == len(GAPS) + placed, f'{tag}: gap count does not match placements')
        check(no_new_short_gaps(out, GAPS), f'{tag}: sub-gap shorter than {MIN_SUBGAP} m')
        check(placed <= n, f'{tag}: more structures placed than prescribed')
        check(all(g > 0 for g in out), f'{tag}: non-positive gap')
        check(fn(gin, n, *extra) == (out, placed), f'{tag}: not deterministic')


run('largest_gap', largest_gap)
run('scaled_gap', scaled_gap)
run('proportional', proportional)
run('cell_grid', cell_grid, TRANSECT)

for fn, extra in [(largest_gap, ()), (proportional, ()), (cell_grid, (10.0,))]:
    for gin in [[], [5.0], [1.0, 1.0, 1.0, 1.0]]:
        try:
            o, p = fn(list(gin), 5, *extra)
            check(abs(sum(o) - sum(gin)) < 1e-6 and len(o) == len(gin) + p, f'{fn.__name__} {gin}')
        except Exception as e:
            fails.append(f'{fn.__name__} {gin}: {e!r}')
try:
    check(scaled_gap([], 5) == ([], 0), 'scaled_gap empty')
    check(abs(sum(scaled_gap([(5.0, 0.3)], 3)[0]) - 5.0) < 1e-6, 'scaled_gap single')
except Exception as e:
    fails.append(f'scaled_gap: {e!r}')

if fails:
    print(f'{len(fails)} check(s) failed:')
    for f in fails:
        print('  -', f)
    sys.exit(1)
print('all placement checks passed')
