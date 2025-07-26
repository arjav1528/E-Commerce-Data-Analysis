"""Run all SQL analyses, save CSVs + plot PNGs to outputs/."""
import re
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
from sqlalchemy import text

from db import get_engine

sns.set_theme(style="whitegrid")

ROOT = Path(__file__).resolve().parent.parent
SQL_DIR = ROOT / "sql"
OUT_DIR = ROOT / "outputs"
SHOT_DIR = OUT_DIR / "screenshots"
OUT_DIR.mkdir(exist_ok=True)
SHOT_DIR.mkdir(exist_ok=True)


def split_statements(sql_text):
    cleaned = re.sub(r"--[^\n]*", "", sql_text)
    return [p.strip() for p in cleaned.split(";") if p.strip()]


def run_file(engine, path):
    sql = Path(path).read_text()
    return [pd.read_sql(text(s), engine) for s in split_statements(sql)]


def funnel(engine):
    overall, monthly = run_file(engine, SQL_DIR / "02_funnel_analysis.sql")
    overall.to_csv(OUT_DIR / "funnel.csv", index=False)
    monthly.to_csv(OUT_DIR / "funnel_monthly.csv", index=False)

    stages = ["purchased", "approved", "shipped", "delivered"]
    vals = [int(overall.iloc[0][s]) for s in stages]
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.bar(stages, vals, color="steelblue")
    for i, v in enumerate(vals):
        ax.text(i, v, f"{v:,}", ha="center", va="bottom")
    ax.set_title("Order Funnel"); ax.set_ylabel("Orders")
    fig.tight_layout(); fig.savefig(SHOT_DIR / "funnel.png", dpi=120); plt.close(fig)


def cohort(engine):
    df = run_file(engine, SQL_DIR / "03_cohort_retention.sql")[0]
    df.to_csv(OUT_DIR / "cohort_retention.csv", index=False)

    pivot = df.pivot(index="cohort_month", columns="month_number", values="retention_pct")
    fig, ax = plt.subplots(figsize=(14, 8))
    sns.heatmap(pivot, annot=True, fmt=".1f", cmap="Blues", ax=ax,
                cbar_kws={"label": "Retention %"})
    ax.set_title("Monthly Cohort Retention (%)")
    fig.tight_layout(); fig.savefig(SHOT_DIR / "cohort_heatmap.png", dpi=120); plt.close(fig)


def rfm(engine):
    users, summary = run_file(engine, SQL_DIR / "04_rfm_segmentation.sql")
    users.to_csv(OUT_DIR / "rfm_users.csv", index=False)
    summary.to_csv(OUT_DIR / "rfm_summary.csv", index=False)

    fig, ax = plt.subplots(figsize=(10, 5))
    sns.barplot(data=summary, x="segment", y="users", ax=ax, color="steelblue")
    ax.set_title("RFM Segments — User Counts"); ax.tick_params(axis="x", rotation=30)
    fig.tight_layout(); fig.savefig(SHOT_DIR / "rfm_segments.png", dpi=120); plt.close(fig)


def repeat_purchase(engine):
    stats, rate = run_file(engine, SQL_DIR / "05_repeat_purchase.sql")
    stats.to_csv(OUT_DIR / "repeat_intervals.csv", index=False)
    rate.to_csv(OUT_DIR / "repeat_rate.csv", index=False)


def gmv_concentration(engine):
    buckets, top20 = run_file(engine, SQL_DIR / "06_gmv_concentration.sql")
    buckets.to_csv(OUT_DIR / "gmv_concentration.csv", index=False)
    top20.to_csv(OUT_DIR / "gmv_top20.csv", index=False)

    labels = ["Top 5%", "Top 10%", "Top 20%", "Top 50%"]
    keys = ["top_5_pct_share", "top_10_pct_share", "top_20_pct_share", "top_50_pct_share"]
    shares = [float(buckets.iloc[0][k]) for k in keys]
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.bar(labels, shares, color="darkorange")
    for i, v in enumerate(shares):
        ax.text(i, v, f"{v:.1f}%", ha="center", va="bottom")
    ax.set_ylabel("Share of GMV (%)"); ax.set_title("GMV Concentration — Pareto")
    fig.tight_layout(); fig.savefig(SHOT_DIR / "gmv_pareto.png", dpi=120); plt.close(fig)


def category_weekly(engine):
    weekly, top10 = run_file(engine, SQL_DIR / "07_category_weekly_gmv.sql")
    weekly.to_csv(OUT_DIR / "category_weekly_gmv.csv", index=False)
    top10.to_csv(OUT_DIR / "category_top10.csv", index=False)

    top_cats = top10["category"].tolist()
    trend = weekly[weekly["category"].isin(top_cats)].copy()
    trend["week"] = pd.to_datetime(trend["week"])

    fig, ax = plt.subplots(figsize=(14, 6))
    for cat in top_cats:
        sub = trend[trend["category"] == cat].sort_values("week")
        ax.plot(sub["week"], sub["gmv"], label=cat, linewidth=1.5)
    ax.set_title("Weekly GMV — Top 10 Categories"); ax.set_ylabel("GMV (BRL)")
    ax.legend(loc="upper left", fontsize=8, ncol=2)
    fig.tight_layout(); fig.savefig(SHOT_DIR / "category_weekly_gmv.png", dpi=120); plt.close(fig)


STEPS = [
    ("funnel",               funnel),
    ("cohort retention",     cohort),
    ("rfm",                  rfm),
    ("repeat purchase",      repeat_purchase),
    ("gmv concentration",    gmv_concentration),
    ("category weekly gmv",  category_weekly),
]


def main():
    engine = get_engine()
    for name, fn in STEPS:
        print(f"Running {name}...")
        fn(engine)
    print(f"Analyses done. Outputs at {OUT_DIR}")


if __name__ == "__main__":
    main()
