"""Apply schema and load Olist CSVs into Postgres via COPY FROM STDIN."""
import os
import sys
from pathlib import Path

import psycopg2

from db import conn_kwargs

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = Path(os.getenv("DATA_DIR", ROOT / "data"))
SQL_DIR = ROOT / "sql"

LOAD_PLAN = [
    ("customers",            "olist_customers_dataset.csv"),
    ("sellers",              "olist_sellers_dataset.csv"),
    ("products",             "olist_products_dataset.csv"),
    ("category_translation", "product_category_name_translation.csv"),
    ("geolocation",          "olist_geolocation_dataset.csv"),
    ("orders",               "olist_orders_dataset.csv"),
    ("order_items",          "olist_order_items_dataset.csv"),
    ("payments",             "olist_order_payments_dataset.csv"),
    ("reviews",              "olist_order_reviews_dataset.csv"),
]


def apply_schema(cur):
    cur.execute((SQL_DIR / "01_create_tables.sql").read_text())


def copy_csv(cur, table, csv_path):
    sql = f"COPY {table} FROM STDIN WITH (FORMAT csv, HEADER true)"
    with open(csv_path, "r", encoding="utf-8") as f:
        cur.copy_expert(sql, f)


def already_loaded(cur):
    cur.execute(
        "SELECT EXISTS (SELECT 1 FROM information_schema.tables "
        "WHERE table_name = 'orders')"
    )
    if not cur.fetchone()[0]:
        return False
    cur.execute("SELECT COUNT(*) FROM orders")
    return cur.fetchone()[0] > 0


def main():
    missing = [c for _, c in LOAD_PLAN if not (DATA_DIR / c).exists()]
    if missing:
        print(f"Missing CSVs in {DATA_DIR}: {missing}", file=sys.stderr)
        sys.exit(1)

    with psycopg2.connect(**conn_kwargs()) as conn:
        with conn.cursor() as cur:
            if already_loaded(cur):
                print("Data already loaded — skipping schema + COPY.")
                return

            print("Applying schema...")
            apply_schema(cur)

            for table, fname in LOAD_PLAN:
                print(f"Loading {table:<22} <- {fname}")
                copy_csv(cur, table, DATA_DIR / fname)
                cur.execute(f"SELECT COUNT(*) FROM {table}")
                print(f"  rows: {cur.fetchone()[0]:,}")
        conn.commit()
    print("Load done.")


if __name__ == "__main__":
    main()
