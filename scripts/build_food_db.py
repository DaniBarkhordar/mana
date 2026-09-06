#!/usr/bin/env python3
"""
Build the offline food database shipped inside the app.

LICENCE BOUNDARY — the reason this script exists rather than a hand-copied CSV.

Only two of the candidate nutrition sources may be redistributed inside an app
binary:

  * UK CoFID (McCance & Widdowson's Composition of Foods Integrated Dataset)
    - Open Government Licence v3.0, Crown copyright. Redistribution permitted
      with acknowledgement. Analytically determined UK foods: this is the right
      spine for a UK product.
  * USDA FoodData Central (Foundation Foods, SR Legacy, FNDDS)
    - Public domain. Fills every gap CoFID does not cover, especially composite
      dishes via FNDDS.

Everything else -- Nutritionix, Edamam, FatSecret, Spoonacular -- licenses
ACCESS to a service, not redistribution of the data. The moment their rows land
in this file you are in breach. Open Food Facts is ODbL: usable at runtime and
cacheable per user, but embedding a filtered extract makes it a derivative
database you must publish under ODbL, so it is deliberately kept out of here.

Inputs (download manually, they are large):
  data/cofid_2021.xlsx   https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid
  data/usda_foundation/  https://fdc.nal.usda.gov/download-datasets
  data/usda_sr_legacy/
  data/usda_fndds/

Output:
  app/assets/food/core.sqlite
"""
import argparse, os, sqlite3, sys

SCHEMA = """
create table foods (
  id           text primary key,
  name         text not null,
  source       text not null,     -- 'cofid' | 'usda'
  is_cooked    integer not null default 0,
  kcal_100g    real not null,
  protein_100g real, carb_100g real, sugar_100g real,
  fat_100g     real, saturates_100g real, fibre_100g real, salt_100g real
);
create virtual table foods_fts using fts5(name, content='foods', content_rowid='rowid');
create table meta (key text primary key, value text);
"""

# Attribution shipped in the app's About screen. Required by OGL, requested by
# USDA. Written here so it cannot drift from the data it describes.
ATTRIBUTION = (
    "Nutrition data: McCance and Widdowson's The Composition of Foods "
    "Integrated Dataset (Public Health England), used under the Open "
    "Government Licence v3.0; and USDA FoodData Central, public domain. "
    "Barcode data from Open Food Facts, used under the Open Database Licence."
)

def build(out_path, cofid=None, usda_dirs=()):
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    if os.path.exists(out_path):
        os.remove(out_path)
    db = sqlite3.connect(out_path)
    db.executescript(SCHEMA)

    n = 0
    if cofid:
        n += load_cofid(db, cofid)
    for d in usda_dirs:
        n += load_usda(db, d)

    db.execute("insert into foods_fts(rowid, name) select rowid, name from foods")
    db.execute("insert into meta values ('attribution', ?)", (ATTRIBUTION,))
    db.execute("insert into meta values ('rows', ?)", (str(n),))
    db.commit()
    db.execute("vacuum")
    db.close()
    return n

def load_cofid(db, path):
    """CoFID ships as a multi-sheet workbook, per 100 g of edible portion.

    Two things to get right when implementing:
      * 'Tr' means trace and 'N' means present but no reliable value. Neither is
        zero. Store NULL, not 0 -- coercing them is how a food log quietly
        under-reports.
      * Alcoholic drinks are per 100 ml, not per 100 g.
    """
    try:
        import openpyxl  # noqa: F401
    except ImportError:
        print("  ! openpyxl not installed; skipping CoFID", file=sys.stderr)
        return 0
    print(f"  CoFID: {path}  (implement sheet mapping for the 2021 edition)")
    return 0

def load_usda(db, path):
    """USDA FDC CSV export. Nutrient values are per 100 g; join food.csv to
    food_nutrient.csv on fdc_id and pivot the nutrient ids you need."""
    print(f"  USDA: {path}  (implement food_nutrient pivot)")
    return 0

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--out", default="app/assets/food/core.sqlite")
    p.add_argument("--cofid")
    p.add_argument("--usda", nargs="*", default=[])
    a = p.parse_args()
    print("Building offline food database")
    rows = build(a.out, a.cofid, a.usda)
    print(f"Wrote {a.out} ({rows} rows)")
    print(ATTRIBUTION)
