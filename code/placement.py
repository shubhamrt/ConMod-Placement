# Placement rules for restoration structures.
# Each rule takes a plot's canopy gap lengths (m) and a number of structures N,
# and returns the gap lengths after placement and the number actually placed.
# Shubham Tiwari, 2026

import heapq
import math

MIN_SUBGAP = 0.25      # m
CAP_PER_GAP = 3        # N is capped at CAP_PER_GAP * number of gaps


def n_structures(density_ha, transect_m, n_gaps):
    """Structures intersected along a transect for an areal density (structures/ha)."""
    n = max(1, int(round(math.sqrt(density_ha) * transect_m / 100.0)))
    return min(n, CAP_PER_GAP * n_gaps)


def bordering_heights(gap_lengths, field_lengths, field_heights, default_h):
    """Bordering height for each gap, taken from the field gap record of the same length."""
    if not field_lengths:
        return [default_h] * len(gap_lengths)
    return [field_heights[nearest(L, field_lengths)] for L in gap_lengths]


def largest_gap(gaps, n):
    h = [-g for g in gaps]; heapq.heapify(h); placed = 0
    for _ in range(n):
        if not h or -h[0] < 2*MIN_SUBGAP:          # largest remaining gap too small to split
            break
        g = -heapq.heappop(h)
        heapq.heappush(h, -g/2.0); heapq.heappush(h, -g/2.0); placed += 1
    return sorted((-x for x in h), reverse=True), placed


def scaled_gap(pairs, n):
    h = [(-(L/H), L, H) for L, H in pairs]; heapq.heapify(h)
    done = []; placed = 0
    while placed < n and h:
        _, L, H = heapq.heappop(h)
        if L < 2*MIN_SUBGAP:                        # too short to split; keep it in the output
            done.append(L); continue
        heapq.heappush(h, (-((L/2.0)/H), L/2.0, H))
        heapq.heappush(h, (-((L/2.0)/H), L/2.0, H)); placed += 1
    return sorted([L for _, L, _ in h] + done, reverse=True), placed


def proportional(gaps, n):
    total = float(sum(gaps))
    if total <= 0 or n <= 0: return list(gaps), 0
    cap = [max(0, int(g/MIN_SUBGAP) - 1) for g in gaps]     # max splits keeping pieces >= MIN_SUBGAP
    raw = [g/total*n for g in gaps]
    base = [min(int(x), cap[i]) for i, x in enumerate(raw)]
    order = sorted(range(len(gaps)), key=lambda i: raw[i]-base[i], reverse=True)
    remaining = n - sum(base)
    while remaining > 0:                                    # distribute the rest, respecting caps
        prog = False
        for i in order:
            if remaining <= 0: break
            if base[i] < cap[i]: base[i] += 1; remaining -= 1; prog = True
        if not prog: break
    out = []
    for g, k in zip(gaps, base): out.extend([g/(k+1)]*(k+1))
    return out, sum(base)


def cell_grid(gaps, n, transect):
    if n <= 0 or not gaps:
        return list(gaps), 0
    w = float(transect) / n
    cap = [max(1, math.ceil(g / w)) for g in gaps]
    cnt = [0] * len(gaps)
    h = [(-g, i) for i, g in enumerate(gaps)]
    heapq.heapify(h)
    placed = 0
    while placed < n and h:
        _, i = heapq.heappop(h)
        if cnt[i] >= cap[i]:
            continue                      # gap is full - it spans no more cells
        if gaps[i] / (cnt[i] + 2) < MIN_SUBGAP:
            continue                      # next split would make a sub-gap too small
        cnt[i] += 1
        placed += 1
        heapq.heappush(h, (-(gaps[i] / (cnt[i] + 1)), i))
    out = []
    for g, k in zip(gaps, cnt):
        out.extend([g / (k + 1)] * (k + 1))
    return out, placed


def nearest(x, xs):
    return min(range(len(xs)), key=lambda i: abs(xs[i]-x))
