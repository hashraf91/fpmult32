#!/usr/bin/env python3
"""Summarize the Vivado reports written by HW/scripts/run_synth_one.tcl.

Usage: extract_metrics.py <reports_dir> [--period 5.0] [--csv out.csv] [--filter substr]

For every <reports_dir>/timing_* directory the script reports (post-route):
  LUTs, CARRY8, CLB     from post_impl_utilization.rpt
  CPD (ns)              data-path delay of the worst path (post_impl_timing.rpt)
  WNS (ns), Fmax (MHz)  Fmax = floor(1000 / (period - WNS))
  Power (mW)            dynamic power of the combinational datapath, from
                        post_impl_power.xpe: sum of the unclocked and
                        high-fanout-net logic power of the inst0 hierarchy
                        (excludes static power, clock tree, I/O and the
                        registers of the timing wrapper)
  PDP (pJ)              Power x CPD
"""
import argparse
import csv
import glob
import math
import os
import re
import sys


def util(text, key):
    m = re.search(r'\|\s*' + re.escape(key) + r'\s*\|\s*(\d+)', text)
    return int(m.group(1)) if m else None


def comb_power_mw(xpe):
    total = 0.0
    for m in re.finditer(r'<LOGIC ([^>]*)>', xpe):
        a = dict(re.findall(r'(\w+)="([^"]*)"', m.group(1)))
        if a.get('clock', '').startswith('Unclocked') and a.get('hierName', '').endswith('inst0'):
            total += float(a['power']) * 1e3
    return total


def summarize(d, period):
    def rd(name):
        with open(os.path.join(d, name)) as f:
            return f.read()
    u, t, x = rd('post_impl_utilization.rpt'), rd('post_impl_timing.rpt'), rd('post_impl_power.xpe')
    cpd = float(re.search(r'Data Path Delay:\s*([\d.]+)ns', t).group(1))
    wns = float(re.search(r'Slack \(\w+\)\s*:\s*(-?[\d.]+)ns', t).group(1))
    power = comb_power_mw(x)
    return {'design': os.path.basename(d).replace('timing_', ''),
            'luts': util(u, 'CLB LUTs'), 'carry8': util(u, 'CARRY8'), 'clb': util(u, 'CLB'),
            'cpd_ns': cpd, 'wns_ns': wns, 'fmax_mhz': int(math.floor(1000.0 / (period - wns))),
            'power_mw': round(power, 3), 'pdp_pj': round(power * cpd, 2)}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('reports_dir')
    ap.add_argument('--period', type=float, default=5.0, help='clock constraint in ns (default 5.0)')
    ap.add_argument('--csv', help='also write the table to this CSV file')
    ap.add_argument('--filter', default='', help='only designs whose name contains this string')
    args = ap.parse_args()
    rows = []
    for d in sorted(glob.glob(os.path.join(args.reports_dir, 'timing_*'))):
        if args.filter not in os.path.basename(d):
            continue
        try:
            rows.append(summarize(d, args.period))
        except (OSError, AttributeError) as e:
            print('skipping %s: %s' % (d, e), file=sys.stderr)
    cols = ['design', 'luts', 'carry8', 'clb', 'cpd_ns', 'wns_ns', 'fmax_mhz', 'power_mw', 'pdp_pj']
    print(('%-24s' + ' %8s' * (len(cols) - 1)) % tuple(cols))
    for r in rows:
        print(('%-24s' + ' %8s' * (len(cols) - 1)) % tuple(r[c] for c in cols))
    if args.csv:
        with open(args.csv, 'w', newline='') as f:
            w = csv.DictWriter(f, fieldnames=cols)
            w.writeheader()
            w.writerows(rows)


if __name__ == '__main__':
    main()
