"""DB connection helpers."""
import os
import time

import psycopg2
from sqlalchemy import create_engine


def conn_kwargs():
    return dict(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "5432")),
        dbname=os.getenv("DB_NAME", "olist_analytics"),
        user=os.getenv("DB_USER", "olist"),
        password=os.getenv("DB_PASSWORD", "olist"),
    )


def sqlalchemy_url():
    k = conn_kwargs()
    return (
        f"postgresql+psycopg2://{k['user']}:{k['password']}"
        f"@{k['host']}:{k['port']}/{k['dbname']}"
    )


def get_engine():
    return create_engine(sqlalchemy_url(), pool_pre_ping=True)


def wait_for_db(timeout=60):
    deadline = time.time() + timeout
    last_err = None
    while time.time() < deadline:
        try:
            with psycopg2.connect(**conn_kwargs()) as c:
                c.cursor().execute("SELECT 1")
            return
        except Exception as e:
            last_err = e
            time.sleep(1)
    raise RuntimeError(f"DB not ready after {timeout}s: {last_err}")
