# Table S5: share of cases in which each strategy gave the greatest reduction,
# for the seven AERO parameter sets (90-plot subsample).
# Reads data/flux_sensitivity.csv, writes output/table_S5.csv.

import os
import numpy as np
import pandas as pd

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
OUT = os.path.join(ROOT, 'output')
os.makedirs(OUT, exist_ok=True)

MODES = ['targeted', 'scaled', 'proportional', 'cellgrid']
PSETS = ['median', 'rlo_philo', 'rhi_philo', 'rlo_phihi', 'rhi_phihi', 'gamma_lo', 'gamma_hi']

d = pd.read_csv(os.path.join(ROOT, 'data', 'flux_sensitivity.csv'))
base = d[d['mode'] == 'baseline'][['pset', 'plot_id', 'wind_speed', 'Q']].rename(columns={'Q': 'base'})
m = d[d['mode'].isin(MODES)].merge(base, on=['pset', 'plot_id', 'wind_speed'])
m = m[m['base'] > 0].copy()
m['Qav'] = m['base'] - np.minimum(m['Q'], m['base'])

key = ['pset', 'plot_id', 'wind_speed', 'density']
m['is_best'] = m['Qav'] >= m.groupby(key)['Qav'].transform('max') - 1e-9
m['win'] = m['is_best'] / m.groupby(key)['is_best'].transform('sum')

tab = (m[m['wind_speed'].isin([12, 16, 20])]
       .groupby(['pset', 'mode'])['win'].mean().mul(100).unstack()
       .reindex(index=PSETS, columns=MODES).round(1))
tab.to_csv(os.path.join(OUT, 'table_S5.csv'))
print(tab.to_string())
print('plots:', m['plot_id'].nunique())
