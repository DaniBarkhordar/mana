#!/usr/bin/env python3
"""
Tests for build_food_db.py against fixtures in the published layouts.

The real CoFID workbook and USDA CSVs are large and downloaded separately;
these fixtures reproduce the exact shapes the loaders read — the CoFID header
row with units, Tr/N cells, the Inorganics sheet for sodium, and the FDC
food.csv / food_nutrient.csv / nutrient.csv trio — so the loaders are proven
before the real files arrive.

Run:  python3 scripts/test_build_food_db.py
"""
import os
import sqlite3
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_food_db as b  # noqa: E402


def write_cofid_fixture(path):
    import openpyxl
    wb = openpyxl.Workbook()
    intro = wb.active
    intro.title = "Introduction"
    intro["A1"] = "McCance and Widdowson's Composition of Foods Integrated Dataset 2021"

    prox = wb.create_sheet("Proximates")
    # CoFID has a title row and a units row above the real header.
    prox.append(["Proximates", None])
    prox.append([])
    prox.append([
        "Food Code", "Food Name", "Description", "Group", "Previous",
        "Main data references", "Footnote", "Water (g)", "Total nitrogen (g)",
        "Protein (g)", "Fat (g)", "Carbohydrate (g)", "Energy (kcal) (kcal)",
        "Energy (kJ) (kJ)", "Starch (g)", "Oligosaccharide (g)",
        "Total sugars (g)", "Glucose (g)", "Fructose (g)", "Sucrose (g)",
        "Maltose (g)", "Lactose (g)", "Alcohol (g)", "NSP (g)", "AOAC fibre (g)",
        "Satd FA /100g FA (g)", "Satd FA /100g fd (g)",
    ])
    prox.append([
        "18-016", "Chicken, breast, grilled, meat only", "", "MI", "", "", "",
        64.6, 5.13, 32.0, 2.2, 0, 148, 628, 0, 0, "Tr", 0, 0, 0, 0, 0, 0, 0, 0,
        29.8, 0.6,
    ])
    prox.append([
        "11-020", "Rice, basmati, raw", "", "AC", "", "", "",
        10.5, 1.3, 8.1, 1.0, 78.0, 356, 1508, 77.5, 0, 0.5, "N", "N", "N", "N",
        0, 0, "N", 2.0, "N", "N",
    ])
    prox.append([
        "17-300", "Beer, bitter, draught", "", "QA", "", "", "",
        94.0, 0.05, 0.3, 0, 2.3, 32, 132, 0, 0, 2.3, "Tr", "Tr", 0, 2.3, 0,
        3.1, 0, 0, 0, 0,
    ])
    prox.append(["99-999", "Nothing measured", "", "ZZ", "", "", "", "N"] + ["N"] * 19)
    prox.append([None, None])

    inorg = wb.create_sheet("Inorganics")
    inorg.append(["Inorganics"])
    inorg.append([])
    inorg.append(["Food Code", "Food Name", "Sodium (mg)", "Potassium (mg)"])
    inorg.append(["18-016", "Chicken, breast, grilled, meat only", 60, 380])
    inorg.append(["11-020", "Rice, basmati, raw", "Tr", 110])
    inorg.append(["17-300", "Beer, bitter, draught", 8, 30])
    wb.save(path)


def write_usda_fixture(folder):
    os.makedirs(folder, exist_ok=True)
    with open(os.path.join(folder, "food.csv"), "w", newline="") as f:
        f.write('"fdc_id","data_type","description","food_category_id","publication_date"\n')
        f.write('"171077","sr_legacy_food","Chicken, broilers or fryers, breast, meat only, cooked, roasted","5","2019-04-01"\n')
        f.write('"170287","sr_legacy_food","Chickpea flour (besan)","16","2019-04-01"\n')
        f.write('"999999","branded_food","Some Brand Bar","","2019-04-01"\n')
    with open(os.path.join(folder, "nutrient.csv"), "w", newline="") as f:
        f.write('"id","name","unit_name","nutrient_nbr","rank"\n')
        f.write('"1008","Energy","KCAL","208","300"\n')
        f.write('"1003","Protein","G","203","600"\n')
        f.write('"1004","Total lipid (fat)","G","204","800"\n')
        f.write('"1005","Carbohydrate, by difference","G","205","1110"\n')
        f.write('"1093","Sodium, Na","MG","307","5800"\n')
        f.write('"1079","Fiber, total dietary","G","291","1200"\n')
    with open(os.path.join(folder, "food_nutrient.csv"), "w", newline="") as f:
        f.write('"id","fdc_id","nutrient_id","amount","data_points","derivation_id"\n')
        rows = [
            ("171077", "1008", 165), ("171077", "1003", 31.02), ("171077", "1004", 3.57),
            ("171077", "1005", 0), ("171077", "1093", 74),
            ("170287", "1008", 387), ("170287", "1003", 22.39), ("170287", "1004", 6.69),
            ("170287", "1005", 57.82), ("170287", "1079", 10.8),
            ("999999", "1008", 400),
        ]
        for i, (fdc, nid, amt) in enumerate(rows):
            f.write(f'"{i}","{fdc}","{nid}","{amt}","","71"\n')


class BuildTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp()
        cls.xlsx = os.path.join(cls.tmp, "cofid.xlsx")
        cls.usda = os.path.join(cls.tmp, "usda")
        cls.out = os.path.join(cls.tmp, "core.sqlite")
        write_cofid_fixture(cls.xlsx)
        write_usda_fixture(cls.usda)
        cls.n = b.build(cls.out, cls.xlsx, [cls.usda])
        cls.db = sqlite3.connect(cls.out)
        cls.db.row_factory = sqlite3.Row

    def row(self, id_):
        return self.db.execute("select * from foods where id = ?", (id_,)).fetchone()

    def test_row_count_skips_unloggable_and_branded(self):
        # 3 CoFID (the all-N row has no energy) + 2 USDA (branded skipped).
        self.assertEqual(self.n, 5)
        self.assertEqual(self.db.execute("select value from meta where key='rows'").fetchone()[0], "5")

    def test_cofid_values_and_trace_as_null(self):
        r = self.row("cofid:18-016")
        self.assertEqual(r["name"], "Chicken, breast, grilled, meat only")
        self.assertEqual(r["source"], "cofid")
        self.assertEqual(r["kcal_100g"], 148)
        self.assertEqual(r["protein_100g"], 32.0)
        self.assertEqual(r["fat_100g"], 2.2)
        self.assertEqual(r["saturates_100g"], 0.6)   # per 100 g food, not per 100 g FA
        self.assertIsNone(r["sugar_100g"])           # 'Tr' is not 0
        self.assertEqual(r["is_cooked"], 1)
        self.assertEqual(r["per_100ml"], 0)

    def test_n_means_null_never_zero(self):
        r = self.row("cofid:11-020")
        self.assertIsNone(r["saturates_100g"])
        self.assertEqual(r["fibre_100g"], 2.0)       # NSP used when AOAC is N
        self.assertIsNone(r["salt_100g"])            # sodium 'Tr'
        self.assertEqual(r["is_cooked"], 0)          # "raw" wins over nothing

    def test_salt_is_sodium_times_two_and_a_half(self):
        r = self.row("cofid:18-016")
        self.assertAlmostEqual(r["salt_100g"], 60 * 2.5 / 1000, places=6)

    def test_drinks_are_flagged_per_100ml(self):
        r = self.row("cofid:17-300")
        self.assertEqual(r["per_100ml"], 1)

    def test_usda_pivot(self):
        r = self.row("usda:171077")
        self.assertEqual(r["kcal_100g"], 165)
        self.assertAlmostEqual(r["protein_100g"], 31.02)
        self.assertAlmostEqual(r["salt_100g"], 74 * 2.5 / 1000, places=6)
        self.assertIsNone(r["fibre_100g"])
        self.assertEqual(r["is_cooked"], 1)
        self.assertEqual(r["food_group"], "sr_legacy_food")
        self.assertIsNone(self.row("usda:999999"))

    def test_search_ranks_prefix_and_uk_first(self):
        hits = b.search(self.db, "chick")
        names = [h[1] for h in hits]
        # Chicken before chickpea, CoFID before USDA among prefix matches.
        self.assertTrue(names[0].startswith("Chicken"), names)
        self.assertEqual(hits[0][2], "cofid")
        self.assertIn("Chickpea flour (besan)", names)
        self.assertGreater(names.index("Chickpea flour (besan)"),
                           names.index("Chicken, breast, grilled, meat only"))

    def test_search_multi_token_prefix(self):
        hits = b.search(self.db, "chicken bre")
        self.assertTrue(all("hicken" in h[1] for h in hits), hits)
        self.assertEqual(len(hits), 2)

    def test_search_exact_beats_prefix(self):
        b._insert(self.db, b.Row("cofid", "x1", "Chicken", 100))
        self.db.execute("insert into foods_fts(foods_fts) values ('rebuild')")
        hits = b.search(self.db, "chicken")
        self.assertEqual(hits[0][1], "Chicken")

    def test_normalise(self):
        self.assertEqual(b.normalise("Crème fraîche, 30% fat"), "creme fraiche 30 fat")
        self.assertEqual(b.fts_query("crème  fra"), '"creme"* "fra"*')

    def test_number_or_none(self):
        self.assertIsNone(b.number_or_none("Tr"))
        self.assertIsNone(b.number_or_none("N"))
        self.assertIsNone(b.number_or_none(""))
        self.assertEqual(b.number_or_none("<0.5"), 0.5)
        self.assertEqual(b.number_or_none(12), 12.0)

    def test_verify_passes_on_the_fixture(self):
        self.assertTrue(b.verify(self.out, "chicken breast"))

    def test_attribution_present(self):
        att = self.db.execute("select value from meta where key='attribution'").fetchone()[0]
        self.assertIn("Open Government Licence", att)
        self.assertIn("USDA", att)


if __name__ == "__main__":
    unittest.main(verbosity=1)
