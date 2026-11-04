# Flux reductions and summary tables for the placement analysis.
# Reads data/flux_baseline.csv and data/flux_placement.csv, writes to output/.
# Shubham Tiwari, 2026

import os
import numpy as np
import pandas as pd

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
DATA = os.path.join(ROOT, 'data')
OUT = os.path.join(ROOT, 'output')
os.makedirs(OUT, exist_ok=True)

MODES = ['targeted', 'scaled', 'proportional', 'cellgrid']
DENS = [100, 250, 500, 1000, 2000, 4000]
NCELL = len(MODES) * len(DENS)
rng = np.random.default_rng(7)
B = 2000

place = pd.read_csv(os.path.join(DATA, 'flux_placement.csv'))
base = pd.read_csv(os.path.join(DATA, 'flux_baseline.csv'))[['plot_id', 'wind_speed', 'Q']]
base = base.rename(columns={'Q': 'base_gmd'})

m = place.merge(base, on=['plot_id', 'wind_speed'], how='inner')
m = m[m['base_gmd'] > 0].dropna(subset=['Q']).copy()

# reductions are bounded at zero
m['treated_gmd'] = np.minimum(m['Q'], m['base_gmd'])
m['Q_avoided'] = m['base_gmd'] - m['treated_gmd']
m['pct'] = 100.0 * m['Q_avoided'] / m['base_gmd']
m['Q_residual'] = m['treated_gmd']
m['per_avoided'] = m['Q_avoided'] / m['n_placed'].clip(lower=1)
m['ach_frac'] = m['n_placed'] / m['n_structures'].clip(lower=1)
m['ach_density'] = m['density'] * m['ach_frac'] ** 2
m['perha_avoided'] = m['Q_avoided'] / m['ach_density'].clip(lower=1e-9)

ncell = m.groupby(['plot_id', 'wind_speed']).size().rename('ncell').reset_index()
m = m.merge(ncell, on=['plot_id', 'wind_speed'])
m['complete_case'] = m['ncell'] == NCELL

cols = ['plot_id', 'site_type', 'mode', 'density', 'wind_speed', 'n_structures', 'n_placed',
        'ach_frac', 'ach_density', 'base_gmd', 'treated_gmd', 'pct', 'Q_avoided', 'Q_residual',
        'per_avoided', 'perha_avoided', 'complete_case']
m[cols].to_csv(os.path.join(OUT, 'master_results.csv'), index=False)
cc = m[m['complete_case']].copy()
print(f'{len(m)} rows, {len(cc)} complete-case rows')

# share of plots reaching 50/75/90% reduction
for t in (50, 75, 90):
    cc[f'g{t}'] = cc['pct'] >= t
rel = cc.groupby(['site_type', 'wind_speed', 'density', 'mode']).agg(
    N=('pct', 'size'), p50=('g50', 'mean'), p75=('g75', 'mean'), p90=('g90', 'mean'),
    mean_pct=('pct', 'mean'), median_pct=('pct', 'median')).reset_index()
rel.to_csv(os.path.join(OUT, 'reliability.csv'), index=False)

# best strategy per plot, wind and density (ties split equally)
key = ['plot_id', 'wind_speed', 'density']
cc['best'] = cc.groupby(key)['Q_avoided'].transform('max')
cc['regret'] = cc['best'] - cc['Q_avoided']
cc['is_best'] = cc['regret'] <= 1e-9
cc['win_frac'] = cc['is_best'] / cc.groupby(key)['is_best'].transform('sum')
reg = cc.groupby(['site_type', 'wind_speed', 'density', 'mode']).agg(
    N=('regret', 'size'), median_regret=('regret', 'median'),
    mean_regret=('regret', 'mean'), win_rate=('win_frac', 'mean')).reset_index()
reg.to_csv(os.path.join(OUT, 'regret.csv'), index=False)

win = cc[cc['wind_speed'].isin([12, 16, 20])].groupby('mode')['win_frac'].mean()
win.rename('win_rate').reset_index().to_csv(os.path.join(OUT, 'winrate.csv'), index=False)
print('win share (12-20 m/s):', (100 * win).round(1).to_dict())

# marginal benefit between consecutive densities
ms = cc.groupby(['site_type', 'wind_speed', 'mode', 'density']).agg(
    Qav=('Q_avoided', 'mean'), Npl=('n_placed', 'mean'), Dach=('ach_density', 'mean')).reset_index()
rows = []
for (st, w, md), g in ms.groupby(['site_type', 'wind_speed', 'mode']):
    g = g.sort_values('density')
    q, n, d, da = g['Qav'].values, g['Npl'].values, g['density'].values, g['Dach'].values
    for i in range(1, len(d)):
        dn, dd = n[i] - n[i - 1], da[i] - da[i - 1]
        rows.append({'site_type': st, 'wind_speed': w, 'mode': md,
                     'from_density': d[i - 1], 'to_density': d[i],
                     'dQ_avoided': q[i] - q[i - 1], 'dN_placed': dn,
                     'marg_per_structure': (q[i] - q[i - 1]) / dn if dn != 0 else np.nan,
                     'marg_perha': (q[i] - q[i - 1]) / dd if dd != 0 else np.nan})
pd.DataFrame(rows).to_csv(os.path.join(OUT, 'marginal_benefit.csv'), index=False)


def paired_boot(a, b):
    d = b - a
    n = len(d)
    if n < 3:
        return np.nan, np.nan, np.nan, np.nan
    idx = rng.integers(0, n, size=(B, n))
    meds = np.median(d[idx], axis=1)
    return np.median(d), np.percentile(meds, 2.5), np.percentile(meds, 97.5), (d > 0).mean()


# paired differences in % reduction relative to largest-gap placement
wide = cc.pivot_table(index=['plot_id', 'site_type', 'wind_speed', 'density'], columns='mode', values='pct')
rows = []
for other in ['scaled', 'proportional', 'cellgrid']:
    sub = wide.dropna(subset=['targeted', other])
    for (st, w, d), g in sub.groupby(['site_type', 'wind_speed', 'density']):
        md, lo, hi, fp = paired_boot(g['targeted'].values, g[other].values)
        rows.append({'site_type': st, 'wind_speed': w, 'density': d,
                     'contrast': f'{other}_minus_largest', 'N': len(g),
                     'median_diff': md, 'ci_lo': lo, 'ci_hi': hi, 'frac_positive': fp,
                     'sig': (lo is not np.nan) and (lo > 0 or hi < 0)})
pd.DataFrame(rows).to_csv(os.path.join(OUT, 'contrasts_bootstrap.csv'), index=False)

# Table S3
lab = {'targeted': 'Largest-gap', 'scaled': 'Scaled gap', 'proportional': 'Proportional', 'cellgrid': 'Cell-grid'}
rows = []
for (t, w, md, d), v in cc.groupby(['site_type', 'wind_speed', 'mode', 'density']):
    p = v['pct']
    rows.append([t.capitalize(), w, lab[md], d, len(v), round(p.mean(), 1), round(p.median(), 1),
                 round(p.std(), 1), round(p.quantile(.75) - p.quantile(.25), 1),
                 round(v['perha_avoided'].mean(), 2), int(round(v['ach_density'].median()))])
pd.DataFrame(rows, columns=['VegType', 'WindSpeed', 'Strategy', 'Density_n_ha', 'N', 'Mean_pct',
                            'Median_pct', 'SD_pct', 'IQR_pct', 'ReductionEfficiency_mean',
                            'AchievedDensity_med']).to_csv(os.path.join(OUT, 'table_S3.csv'), index=False)
print('done')
