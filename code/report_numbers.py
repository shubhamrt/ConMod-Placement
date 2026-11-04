# Prints the numbers reported in the manuscript.
# Run build_results.py first.

import os
import numpy as np
import pandas as pd

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
DATA = os.path.join(ROOT, 'data')
OUT = os.path.join(ROOT, 'output')


def rd(folder, f):
    return pd.read_csv(os.path.join(folder, f))


base = rd(DATA, 'flux_baseline.csv')
place = rd(DATA, 'flux_placement.csv')
M = rd(OUT, 'master_results.csv')
rel = rd(OUT, 'reliability.csv')
con = rd(OUT, 'contrasts_bootstrap.csv')
marg = rd(OUT, 'marginal_benefit.csv')
win = rd(OUT, 'winrate.csv')
cc = M[M['complete_case']]
c16 = cc[cc['wind_speed'] == 16]

TYPES = ['grass', 'mixed', 'shrub']
MODES = ['targeted', 'scaled', 'proportional', 'cellgrid']
DENS = [100, 250, 500, 1000, 2000, 4000]

print('--- Initial flux (all 1,500 plots) ---')
b16 = base[base['wind_speed'] == 16]
print('median Q at 16 m/s by type:', b16.groupby('site_type')['Q'].median().round(1).to_dict())
for w in [8, 12, 16, 20]:
    v = base[base['wind_speed'] == w]['Q']
    print(f'U={w}: median {v.median():.1f}, Q=0 in {100 * (v <= 0).mean():.1f}% of plots')
q = np.sort(b16.groupby('plot_id')['Q'].mean().values)[::-1]
n = len(q)
print(f'top 10% share {100 * q[:int(0.1 * n)].sum() / q.sum():.1f}%, '
      f'top 20% share {100 * q[:int(0.2 * n)].sum() / q.sum():.1f}%')

print('\n--- Exclusions at 16 m/s ---')
p16 = place[place['wind_speed'] == 16]
expected = base['plot_id'].nunique() * 24
print('failed runs:', expected - p16['Q'].notna().sum(), 'of', expected)
print('plots retained by type:', c16.groupby('site_type')['plot_id'].nunique().to_dict())

print('\n--- Mean % reduction, all types, 16 m/s ---')
t = c16.groupby(['density', 'mode'])['pct'].mean().unstack()[MODES].round(1)
print(t.to_string())

print('\n--- 100 structures/ha, largest-gap, by type ---')
s = c16[(c16['density'] == 100) & (c16['mode'] == 'targeted')]
print('mean %:', s.groupby('site_type')['pct'].mean().round(1).to_dict())
print('mean absolute reduction:', s.groupby('site_type')['Q_avoided'].mean().round(0).to_dict())
print('remaining flux, shrub:', round(s[s['site_type'] == 'shrub']['Q_residual'].mean()),
      '| initial flux, grass:', round(s[s['site_type'] == 'grass']['base_gmd'].mean()))

print('\n--- Mean absolute reduction by strategy, 100 and 250 structures/ha ---')
for d in [100, 250]:
    t = c16[c16['density'] == d].groupby(['site_type', 'mode'])['Q_avoided'].mean().unstack()[MODES]
    print(d, '\n', t.round(0).to_string())

print('\n--- Reduction efficiency at 100 structures/ha (g/m/d per structure/ha) ---')
print(c16[c16['density'] == 100].groupby(['site_type', 'mode'])['perha_avoided'].mean()
      .unstack()[MODES].round(2).to_string())

print('\n--- Win share, 12-20 m/s (%) ---')
print((100 * win.set_index('mode')['win_rate']).round(1).to_dict())

print('\n--- Scaled gap minus largest-gap, shrub (percentage points) ---')
S = con[(con['contrast'] == 'scaled_minus_largest') & (con['site_type'] == 'shrub')]
print(S.pivot(index='wind_speed', columns='density', values='median_diff').round(1).to_string())
for c in ['proportional_minus_largest', 'cellgrid_minus_largest']:
    x = con[(con['contrast'] == c) & (con['wind_speed'] == 16)]
    print(c, 'range at 16 m/s:', round(x['median_diff'].min(), 1), 'to', round(x['median_diff'].max(), 1))

print('\n--- Largest-gap, 16 m/s: median % and density reaching targets ---')
for st in TYPES:
    r = rel[(rel['site_type'] == st) & (rel['mode'] == 'targeted') & (rel['wind_speed'] == 16)].sort_values('density')
    hit = {tg: int(r[r['median_pct'] >= tg]['density'].min()) for tg in [50, 75, 90]}
    print(st, 'median at 100:', round(r['median_pct'].iloc[0], 1), '| first density reaching', hit)

print('\n--- Marginal reduction efficiency, largest-gap, 16 m/s ---')
for st in TYPES:
    r = marg[(marg['site_type'] == st) & (marg['mode'] == 'targeted') & (marg['wind_speed'] == 16)]
    print(st, r.sort_values('from_density')['marg_perha'].round(3).tolist())

print('\n--- Prioritization, largest-gap, 16 m/s ---')
for d in [250, 500, 1000]:
    s = c16[(c16['mode'] == 'targeted') & (c16['density'] == d)].sort_values('base_gmd', ascending=False)
    cum = 100 * np.cumsum(s['Q_avoided'].values) / s['base_gmd'].sum()
    n = len(s)
    at = {f: cum[max(1, round(f / 100 * n)) - 1] for f in [25, 50]}
    print(f'{d}/ha: all plots {cum[-1]:.1f}% | top 25% {at[25]:.1f}% (expected {0.25 * cum[-1]:.1f}%) '
          f'| top 50% {at[50]:.1f}% | share of all-plot reduction {100 * at[25] / cum[-1]:.1f}% and {100 * at[50] / cum[-1]:.1f}%')
