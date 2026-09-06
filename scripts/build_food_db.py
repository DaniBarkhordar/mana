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

Inputs (download manually, they are large; keep them under data/, which is
git-ignored):

  data/cofid_2021.xlsx
      https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid
      "McCance and Widdowson's composition of foods integrated dataset 2021"
  data/usda_foundation/   data/usda_sr_legacy/   data/usda_fndds/
      https://fdc.nal.usda.gov/download-datasets
      the "CSV" zips, unpacked: each folder holds food.csv and food_nutrient.csv

Run:

  python3 scripts/build_food_db.py --cofid data/cofid_2021.xlsx \
      --usda data/usda_sr_legacy data/usda_foundation data/usda_fndds
  python3 scripts/build_food_db.py --verify   # times a "chicken breast" search

Output:  app/assets/food/core.sqlite  (commit it; the app ships it)

Two things this gets right that a quick CSV import gets wrong:

  * CoFID marks "trace" as `Tr` and "present but no reliable value" as `N`.
    Neither is zero. They are stored as NULL, because coercing them to 0 is how
    a food log quietly under-reports.
  * CoFID gives alcoholic and some other drinks per 100 ml, not per 100 g. The
    row is flagged (`per_100ml = 1`) so the app can say so.

Search is FTS5 over name and brand, plus two plain columns the app uses to
rank exact and prefix matches above mid-word ones: a user typing "chick"
wants chicken breast, not chickpea flour.
"""
import argparse
import csv
import os
import re
import sqlite3
import sys
import time
import unicodedata

SCHEMA = """
create table foods (
  id           text primary key,     -- 'cofid:13-001', 'usda:171077'
  name         text not null,
  brand        text,                 -- unused for reference data; here so the
                                     -- app's search shape matches user foods
  source       text not null,        -- 'cofid' | 'usda'
  source_id    text not null,        -- the dataset's own code
  food_group   text,
  is_cooked    integer not null default 0,
  per_100ml    integer not null default 0,
  kcal_100g    real not null,
  protein_100g real, carb_100g real, sugar_100g real,
  fat_100g     real, saturates_100g real, fibre_100g real, salt_100g real,
  -- lower-cased, accent-stripped name for exact / prefix ranking
  name_norm    text not null,
  -- shorter names rank first among equals: "Chicken breast, grilled" before
  -- "Chicken breast, grilled, with skin, in a sandwich"
  name_len     integer not null
);
create index foods_name_norm_idx on foods (name_norm);
create virtual table foods_fts using fts5(
  name, brand, content='foods', content_rowid='rowid',
  tokenize='unicode61 remove_diacritics 2'
);
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

SCHEMA_VERSION = "1"


# ---------------------------------------------------------------- helpers

def normalise(name):
    """Lower-case, accents stripped, punctuation to spaces, single-spaced."""
    s = unicodedata.normalize("NFKD", name)
    s = "".join(c for c in s if not unicodedata.combining(c))
    s = re.sub(r"[^a-z0-9]+", " ", s.lower())
    return s.strip()


def number_or_none(v):
    """CoFID cells: a number, 'Tr' (trace), 'N' (no reliable value), '' or
    None. Only a real number is a value; everything else is NULL, never 0."""
    if v is None:
        return None
    if isinstance(v, (int, float)):
        return float(v)
    s = str(v).strip()
    if s == "" or s.upper() in {"TR", "N", "NA", "N/A", "-", "—"}:
        return None
    # Some cells carry a footnote marker or a range like "0.5-0.8".
    m = re.match(r"^[<~]?\s*(-?\d+(\.\d+)?)", s)
    return float(m.group(1)) if m else None


def sodium_mg_to_salt_g(sodium_mg):
    """UK labelling convention: salt = sodium x 2.5."""
    return None if sodium_mg is None else sodium_mg * 2.5 / 1000.0


class Row:
    """One food as it goes into the table."""

    def __init__(self, source, source_id, name, kcal, **kw):
        self.source = source
        self.source_id = str(source_id)
        self.name = name.strip()
        self.kcal = kcal
        self.protein = kw.get("protein")
        self.carb = kw.get("carb")
        self.sugar = kw.get("sugar")
        self.fat = kw.get("fat")
        self.saturates = kw.get("saturates")
        self.fibre = kw.get("fibre")
        self.salt = kw.get("salt")
        self.group = kw.get("group")
        self.is_cooked = 1 if kw.get("is_cooked") else 0
        self.per_100ml = 1 if kw.get("per_100ml") else 0

    @property
    def id(self):
        return f"{self.source}:{self.source_id}"

    def as_tuple(self):
        norm = normalise(self.name)
        return (
            self.id, self.name, None, self.source, self.source_id, self.group,
            self.is_cooked, self.per_100ml, self.kcal,
            self.protein, self.carb, self.sugar, self.fat, self.saturates,
            self.fibre, self.salt, norm, len(norm),
        )


COOKED_WORDS = re.compile(
    r"\b(cooked|boiled|grilled|roast(ed)?|fried|baked|steamed|stewed|poached|"
    r"braised|microwaved|toasted|casseroled|barbecued|broiled|simmered|"
    r"scrambled|drained)\b",
    re.I,
)

PER_100ML_HINT = re.compile(
    r"\b(beer|lager|cider|wine|spirits?|vodka|whisky|whiskey|gin|rum|brandy|"
    r"liqueur|sherry|port|champagne|stout|ale|alcopop|milk|juice|squash|"
    r"cordial|drink|water|lemonade|cola|tea|coffee|smoothie|shake)\b",
    re.I,
)


def looks_cooked(name):
    return bool(COOKED_WORDS.search(name)) and not re.search(r"\braw\b", name, re.I)


# ---------------------------------------------------------------- CoFID

def _sheet_by_name(wb, *candidates):
    for title in wb.sheetnames:
        t = title.strip().lower()
        for c in candidates:
            if t == c.lower() or t.startswith(c.lower()):
                return wb[title]
    return None


def _header_index(rows, needed):
    """Find the header row (the first that contains 'Food Code') and map each
    wanted column to an index by loose, case-insensitive matching on the
    column's first word tokens. CoFID headers carry units and footnotes, e.g.
    'Energy (kcal) (kcal)' or 'Total sugars (g)', so match on prefixes."""
    for r_idx, row in enumerate(rows):
        cells = [str(c).strip() if c is not None else "" for c in row]
        if any(c.lower().replace(" ", "") == "foodcode" for c in cells):
            index = {}
            lowered = [c.lower() for c in cells]
            for key, prefixes in needed.items():
                for i, cell in enumerate(lowered):
                    if any(cell.startswith(p) for p in prefixes):
                        index[key] = i
                        break
            return r_idx, index
    return None, {}


PROXIMATES = {
    "code": ("food code",),
    "name": ("food name",),
    "group": ("group",),
    "kcal": ("energy (kcal)",),
    "protein": ("protein",),
    "fat": ("fat (g)", "fat"),
    "carb": ("carbohydrate",),
    "sugar": ("total sugars",),
    "aoac_fibre": ("aoac fibre",),
    "nsp": ("nsp",),
    "satd": ("satd fa /100g fd", "satd fa /100g food", "saturated"),
    "alcohol": ("alcohol",),
}

INORGANICS = {
    "code": ("food code",),
    "sodium": ("sodium",),
}


def load_cofid(db, path):
    """CoFID 2021 ships as a multi-sheet workbook, per 100 g of edible portion.

    Proximates sheet: energy, protein, fat, carbohydrate, sugars, fibre and the
    saturated-fat total. Inorganics sheet: sodium, from which salt is derived.
    'Tr' and 'N' become NULL (see number_or_none). Drinks are per 100 ml and
    are flagged rather than converted, because density is not in the dataset.
    """
    try:
        import openpyxl
    except ImportError:
        print("  ! openpyxl not installed (pip install openpyxl); skipping CoFID",
              file=sys.stderr)
        return 0

    wb = openpyxl.load_workbook(path, read_only=True, data_only=True)
    prox = _sheet_by_name(wb, "Proximates")
    inorg = _sheet_by_name(wb, "Inorganics")
    if prox is None:
        raise SystemExit(f"CoFID: no Proximates sheet in {path}; sheets: {wb.sheetnames}")

    prox_rows = list(prox.iter_rows(values_only=True))
    header_row, col = _header_index(prox_rows, PROXIMATES)
    missing = [k for k in ("code", "name", "kcal", "protein", "fat", "carb") if k not in col]
    if header_row is None or missing:
        raise SystemExit(f"CoFID Proximates: could not find columns {missing}; "
                         f"header row {header_row}")

    sodium = {}
    if inorg is not None:
        rows = list(inorg.iter_rows(values_only=True))
        h, icol = _header_index(rows, INORGANICS)
        if h is not None and "sodium" in icol:
            for r in rows[h + 1:]:
                code = r[icol["code"]] if icol["code"] < len(r) else None
                if code:
                    sodium[str(code).strip()] = number_or_none(r[icol["sodium"]])

    def cell(r, key):
        i = col.get(key)
        return r[i] if i is not None and i < len(r) else None

    n = 0
    for r in prox_rows[header_row + 1:]:
        code = cell(r, "code")
        name = cell(r, "name")
        if not code or not name:
            continue
        code = str(code).strip()
        name = str(name).strip()
        kcal = number_or_none(cell(r, "kcal"))
        if kcal is None:
            # A food with no energy value cannot be logged; skip rather than
            # invent one.
            continue
        fibre = number_or_none(cell(r, "aoac_fibre"))
        if fibre is None:
            fibre = number_or_none(cell(r, "nsp"))
        group = cell(r, "group")
        per_100ml = bool(PER_100ML_HINT.search(name)) and (
            number_or_none(cell(r, "alcohol")) not in (None, 0.0)
            or bool(re.search(r"\b(milk|juice|squash|cordial|drink|lemonade|cola|water)\b", name, re.I))
        )
        row = Row(
            "cofid", code, name, kcal,
            protein=number_or_none(cell(r, "protein")),
            carb=number_or_none(cell(r, "carb")),
            sugar=number_or_none(cell(r, "sugar")),
            fat=number_or_none(cell(r, "fat")),
            saturates=number_or_none(cell(r, "satd")),
            fibre=fibre,
            salt=sodium_mg_to_salt_g(sodium.get(code)),
            group=str(group).strip() if group else None,
            is_cooked=looks_cooked(name),
            per_100ml=per_100ml,
        )
        _insert(db, row)
        n += 1
    print(f"  CoFID: {n} foods from {path}")
    return n


# ---------------------------------------------------------------- USDA

# FoodData Central nutrient ids (nutrient.csv `nutrient_nbr`), per 100 g.
USDA_NUTRIENTS = {
    "208": "kcal",        # Energy, kcal
    "203": "protein",
    "205": "carb",        # Carbohydrate, by difference
    "204": "fat",         # Total lipid (fat)
    "291": "fibre",       # Fiber, total dietary
    "269": "sugar",       # Sugars, total
    "606": "saturates",   # Fatty acids, total saturated
    "307": "sodium_mg",
}
# Newer FDC exports use nutrient.id rather than nutrient_nbr in
# food_nutrient.csv. Both are handled: the map is filled from nutrient.csv
# when present.
USDA_NUTRIENT_IDS = {
    "1008": "kcal", "1003": "protein", "1005": "carb", "1004": "fat",
    "1079": "fibre", "2000": "sugar", "1258": "saturates", "1093": "sodium_mg",
}


def load_usda(db, path):
    """USDA FDC CSV export: join food.csv to food_nutrient.csv on fdc_id and
    pivot the nutrient ids above. `data_type` tells the sources apart:
    foundation_food, sr_legacy_food, survey_fndds_food (composite dishes),
    branded_food (skipped: not a reference dataset, and enormous)."""
    food_csv = os.path.join(path, "food.csv")
    nutrient_csv = os.path.join(path, "food_nutrient.csv")
    if not (os.path.exists(food_csv) and os.path.exists(nutrient_csv)):
        print(f"  ! USDA: {path} needs food.csv and food_nutrient.csv; skipping",
              file=sys.stderr)
        return 0

    # nutrient.csv maps ids to numbers; without it, fall back to both maps.
    id_to_key = dict(USDA_NUTRIENT_IDS)
    nutrient_file = os.path.join(path, "nutrient.csv")
    if os.path.exists(nutrient_file):
        with open(nutrient_file, newline="", encoding="utf-8") as f:
            for r in csv.DictReader(f):
                nbr = (r.get("nutrient_nbr") or "").strip().split(".")[0]
                if nbr in USDA_NUTRIENTS:
                    id_to_key[r["id"].strip()] = USDA_NUTRIENTS[nbr]

    foods = {}
    with open(food_csv, newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            data_type = (r.get("data_type") or "").strip()
            if data_type == "branded_food":
                continue
            foods[r["fdc_id"].strip()] = {
                "name": (r.get("description") or "").strip(),
                "group": (r.get("food_category_id") or "").strip() or None,
                "data_type": data_type,
            }

    values = {}
    with open(nutrient_csv, newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            fdc = r["fdc_id"].strip()
            if fdc not in foods:
                continue
            key = id_to_key.get(r["nutrient_id"].strip())
            if key is None:
                continue
            amount = number_or_none(r.get("amount"))
            if amount is None:
                continue
            values.setdefault(fdc, {})[key] = amount

    n = 0
    for fdc, meta in foods.items():
        v = values.get(fdc)
        if not v or "kcal" not in v or not meta["name"]:
            continue
        row = Row(
            "usda", fdc, meta["name"], v["kcal"],
            protein=v.get("protein"), carb=v.get("carb"), sugar=v.get("sugar"),
            fat=v.get("fat"), saturates=v.get("saturates"), fibre=v.get("fibre"),
            salt=sodium_mg_to_salt_g(v.get("sodium_mg")),
            group=meta["data_type"],
            is_cooked=looks_cooked(meta["name"]),
        )
        _insert(db, row)
        n += 1
    print(f"  USDA: {n} foods from {path}")
    return n


# ---------------------------------------------------------------- build

def _insert(db, row):
    db.execute(
        "insert or replace into foods (id, name, brand, source, source_id, "
        "food_group, is_cooked, per_100ml, kcal_100g, protein_100g, carb_100g, "
        "sugar_100g, fat_100g, saturates_100g, fibre_100g, salt_100g, "
        "name_norm, name_len) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
        row.as_tuple(),
    )


def build(out_path, cofid=None, usda_dirs=()):
    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    if os.path.exists(out_path):
        os.remove(out_path)
    db = sqlite3.connect(out_path)
    db.executescript(SCHEMA)

    n = 0
    if cofid:
        n += load_cofid(db, cofid)
    for d in usda_dirs:
        n += load_usda(db, d)

    db.execute("insert into foods_fts(rowid, name, brand) "
               "select rowid, name, coalesce(brand, '') from foods")
    db.execute("insert into foods_fts(foods_fts) values ('optimize')")
    db.execute("insert into meta values ('attribution', ?)", (ATTRIBUTION,))
    db.execute("insert into meta values ('rows', ?)", (str(n),))
    db.execute("insert into meta values ('schema_version', ?)", (SCHEMA_VERSION,))
    db.execute("insert into meta values ('built_at', ?)",
               (time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),))
    db.execute("insert into meta values ('sources', ?)",
               (",".join(s for s in (["cofid"] if cofid else []) + (["usda"] if usda_dirs else [])),))
    db.commit()
    db.execute("vacuum")
    db.close()
    return n


# The same ranking the app uses, so this script can prove the acceptance
# check ("chicken breast" returns a CoFID row, fast) before a build is shipped.
SEARCH_SQL = """
select f.id, f.name, f.source, f.kcal_100g,
       case when f.name_norm = :norm then 0
            when f.name_norm like :prefix then 1
            else 2 end as tier,
       bm25(foods_fts) as rank
from foods_fts
join foods f on f.rowid = foods_fts.rowid
where foods_fts match :match
order by tier, (f.source = 'cofid') desc, rank, f.name_len
limit :limit
"""


def fts_query(text):
    """Every token as a prefix, so 'chick br' finds 'Chicken breast'."""
    tokens = [t for t in normalise(text).split() if t]
    return " ".join(f'"{t}"*' for t in tokens)


def search(db, text, limit=20):
    norm = normalise(text)
    return db.execute(SEARCH_SQL, {
        "norm": norm, "prefix": norm + "%", "match": fts_query(text), "limit": limit,
    }).fetchall()


def verify(path, query="chicken breast"):
    db = sqlite3.connect(path)
    rows = db.execute("select value from meta where key='rows'").fetchone()
    print(f"{path}: {rows[0] if rows else '?'} rows")
    t0 = time.perf_counter()
    hits = search(db, query)
    ms = (time.perf_counter() - t0) * 1000
    print(f'"{query}" -> {len(hits)} hits in {ms:.1f} ms')
    for h in hits[:8]:
        print(f"   [{h[2]}] {h[1]}  {h[3]:.0f} kcal")
    db.close()
    ok = bool(hits) and ms < 100
    print("PASS" if ok else "FAIL")
    return ok


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--out", default="app/assets/food/core.sqlite")
    p.add_argument("--cofid")
    p.add_argument("--usda", nargs="*", default=[])
    p.add_argument("--verify", action="store_true",
                   help="time a 'chicken breast' search against --out and exit")
    a = p.parse_args()
    if a.verify:
        sys.exit(0 if verify(a.out) else 1)
    if not a.cofid and not a.usda:
        p.error("nothing to build: pass --cofid and/or --usda (see the docstring)")
    print("Building offline food database")
    rows = build(a.out, a.cofid, a.usda)
    print(f"Wrote {a.out} ({rows} rows)")
    print(ATTRIBUTION)
