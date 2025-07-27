"""Pipeline orchestrator: wait for DB -> load -> analyze -> excel."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from db import wait_for_db
import load_data
import run_analyses
import export_excel


def main():
    print("Waiting for Postgres...")
    wait_for_db()
    print("Postgres ready.")

    print("\n=== Step 1/3: load data ===")
    load_data.main()

    print("\n=== Step 2/3: run analyses ===")
    run_analyses.main()

    print("\n=== Step 3/3: build Excel dashboard ===")
    export_excel.main()

    print("\nPipeline complete.")


if __name__ == "__main__":
    main()
