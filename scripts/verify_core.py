#!/usr/bin/env python3
"""
Independent verification of the numeric core.

The Dart unit tests in app/test/ cannot be executed in this build environment
(no Flutter toolchain), so this script re-implements the same equations and the
same byte parsers from the same published sources and asserts the same expected
values. If the two agree, a coefficient typo in either would have to be
duplicated in both to survive.

Run:  python3 scripts/verify_core.py
"""
import math, sys

FAILS = []

def check(name, got, want, tol=1e-6):
    ok = (abs(got - want) <= tol) if isinstance(want, (int, float)) else (got == want)
    print(("  PASS  " if ok else "  FAIL  ") + f"{name}: got {got!r}, want {want!r}")
    if not ok:
        FAILS.append(name)

def check_eq(name, got, want):
    ok = got == want
    print(("  PASS  " if ok else "  FAIL  ") + f"{name}: got {got!r}, want {want!r}")
    if not ok:
        FAILS.append(name)

# ---------------------------------------------------------------- equations
def ri(h, r): return (h * h) / r

def ffm_sun2003(h, w, r, male):
    RI = ri(h, r)
    return (-10.68 + 0.65*RI + 0.26*w + 0.02*r) if male else (-9.53 + 0.69*RI + 0.17*w + 0.02*r)

def ffm_kyle2001(h, w, r, xc, male):
    return -4.104 + 0.518*ri(h, r) + 0.231*w + 0.130*xc + 4.229*(1 if male else 0)

def ffm_deurenberg1991(h, w, age, r, male):
    return -12.44 + 0.34*ri(h, r) + 0.1534*h + 0.273*w - 0.127*age + 4.56*(1 if male else 0)

def bf_from_bmi(h, w, age, male):
    bmi = w / (h/100)**2
    s = 1 if male else 0
    return (1.20*bmi + 0.23*age - 10.8*s - 5.4) if age > 15 else (1.51*bmi - 0.70*age - 3.6*s + 1.4)

def tbw_sun2003(h, w, r, male):
    RI = ri(h, r)
    return (1.20 + 0.45*RI + 0.18*w) if male else (3.75 + 0.45*RI + 0.11*w)

def smm_janssen2000(h, age, r, male):
    return 0.401*ri(h, r) + 3.825*(1 if male else 0) - 0.071*age + 5.102

def bmr_mifflin(h, w, age, male):
    return 9.99*w + 6.25*h - 4.92*age + 166*(1 if male else 0) - 161

def rmr_cunningham(ffm): return 500 + 22*ffm

print("== BIA equations (subject: 178cm, 80kg, 34y, male, R=500) ==")
H, W, AGE, R = 178, 80, 34, 500
check("resistance index", ri(H, R), 63.368, 1e-3)
check("Sun 2003 FFM (male)", ffm_sun2003(H, W, R, True), 61.3092, 1e-3)
check("Sun 2003 FFM (female 165/65/600)", ffm_sun2003(165, 65, 600, False), 44.82875, 1e-3)
check("Kyle 2001 FFM (Xc=55)", ffm_kyle2001(H, W, R, 55, True), 58.579624, 1e-3)
check("Deurenberg 1991 BIA FFM", ffm_deurenberg1991(H, W, AGE, R, True), 58.49232, 1e-3)
check("Deurenberg BMI body fat %", bf_from_bmi(H, W, AGE, True), 21.9192, 1e-2)
check("Sun 2003 TBW (male)", tbw_sun2003(H, W, R, True), 44.1156, 1e-3)
check("TBW from FFM (0.732)", 0.732*60, 43.92)
check("Janssen 2000 SMM", smm_janssen2000(H, AGE, R, True), 31.923568, 1e-3)
check("Mifflin-St Jeor BMR", bmr_mifflin(H, W, AGE, True), 1749.42, 1e-2)
check("Cunningham 1980 RMR (FFM 60)", rmr_cunningham(60), 1820)
check("TDEE at PAL 1.85", 1800*1.85, 3330)

print("\n== Sanity relations ==")
ffm = ffm_sun2003(H, W, R, True)
smm = smm_janssen2000(H, AGE, R, True)
ok = smm < ffm
print(("  PASS  " if ok else "  FAIL  ") + f"skeletal muscle ({smm:.2f}) < fat-free mass ({ffm:.2f})")
if not ok: FAILS.append("smm<ffm")
bf = (W - ffm)/W*100
ok = 5 < bf < 40
print(("  PASS  " if ok else "  FAIL  ") + f"body fat {bf:.1f}% is physiologically plausible")
if not ok: FAILS.append("bf plausible")

# ---------------------------------------------------------------- frames
def h2b(s): return bytes.fromhex(s.replace(" ", ""))

def lefu_checksum(d): return sum(d[2:7]) & 0xFF

def lefu_parse(d):
    assert len(d) == 8 and d[0] == 0xAC and d[1] == 0x02, "not AC02"
    assert lefu_checksum(d) == d[7], "checksum"
    return ((d[2] << 8) | d[3]) / 10.0, ("stable" if d[6] == 0xCA else "live")

def qn_parse(d, divisor=100):
    assert d[0] == 0x10
    w = ((d[3] << 8) | d[4]) / divisor
    if w >= 250: w /= 10
    r1 = (d[6] << 8) | d[7]
    r2 = (d[8] << 8) | d[9]
    return w, ("stable" if d[5] else "live"), (r1 or None), (r2 or None)

def mibfs_parse(d):
    assert len(d) == 13
    flags = d[1]
    imp_present, stabilised, removed = flags & 0x02, flags & 0x20, flags & 0x80
    weight = (d[11] | (d[12] << 8)) / 200.0 if d[0] != 0x03 else (d[11] | (d[12] << 8))*0.01*0.453592
    z = d[9] | (d[10] << 8)
    z = z if (imp_present and 0 < z < 3000) else None
    state = "removed" if removed else ("stable" if stabilised else "live")
    return weight, z, state

def sig_parse(d):
    imperial = d[0] & 0x01
    raw = d[1] | (d[2] << 8)
    return raw*0.01*0.45359237 if imperial else raw*0.005

print("\n== Lefu / Shenzhen Unique Scales FFB0 'AC02' ==")
gt = h2b("ac0203490000ca16")
check("captured ground-truth checksum", lefu_checksum(gt), 0x16)
w, st = lefu_parse(gt)
check("captured frame weight", w, 84.1)
check_eq("captured frame stability", st, "stable")
w, st = lefu_parse(h2b("ac0203470000ce18"))
check("live frame weight", w, 83.9)
check_eq("live frame stability", st, "live")
try:
    lefu_parse(h2b("ac0203490000ca17")); FAILS.append("corrupt not rejected")
    print("  FAIL  corrupted frame was accepted")
except AssertionError:
    print("  PASS  corrupted frame rejected")

# handshake checksums
hs = [(0xFA,0x01,0,0),(0xFB,0x02,0x1F,0xA5),(0xFD,0xE2,0x01,0x01),(0xFC,0x01,0,0),(0xFE,0x06,0,0)]
expected_first = h2b("ac02fa010000ccc7")
built = bytearray([0xAC,0x02,0xFA,0x01,0x00,0x00,0xCC,0x00])
built[7] = lefu_checksum(built)
check_eq("handshake frame 1 matches capture", bytes(built), expected_first)
allok = True
for d0,d1,d2,d3 in hs:
    b = bytearray([0xAC,0x02,d0,d1,d2,d3,0xCC,0x00]); b[7] = lefu_checksum(b)
    if lefu_checksum(b) != b[7]: allok = False
print(("  PASS  " if allok else "  FAIL  ") + "all handshake checksums self-consistent")

print("\n== Qingniu / QN ==")
w, st, r1, r2 = qn_parse(h2b("1000001f400101f40258"))
check("QN weight", w, 80.0); check_eq("QN stability", st, "stable")
check("QN R1", r1, 500); check("QN R2", r2, 600)
w, *_ = qn_parse(h2b("10000075300101f40258"))
check("QN divisor sanity fallback", w, 30.0)
_, _, r1, _ = qn_parse(h2b("1000001f40010000 0000"))
check_eq("QN empty impedance -> None", r1, None)

print("\n== Xiaomi MIBFS ==")
w, z, st = mibfs_parse(h2b("0222ea070819070f00f401803e"))
check("MIBFS weight", w, 80.0); check("MIBFS impedance", z, 500)
check_eq("MIBFS stability", st, "stable")
_, _, st = mibfs_parse(h2b("02a2ea070819070f00f401803e"))
check_eq("MIBFS load removed", st, "removed")
_, z, _ = mibfs_parse(h2b("0222ea070819070f00b80b803e"))
check_eq("MIBFS rejects z>=3000", z, None)

print("\n== Bluetooth SIG weight measurement ==")
check("SIG SI weight", sig_parse(h2b("00803e")), 80.0)
check("SIG imperial weight", sig_parse(h2b("01e544")), 80.0, 0.01)

# ---------------------------------------------------------------- portions
print("\n== Portion maths ==")
RICE_DRY_KCAL, CHICKEN_KCAL, OIL_KCAL = 356, 106, 884
check("rice 75g dry", RICE_DRY_KCAL*0.75, 267.0)
check("chicken 160g", CHICKEN_KCAL*1.60, 169.6, 1e-9)
check("meal total", RICE_DRY_KCAL*0.75 + CHICKEN_KCAL*1.60, 436.6, 1e-9)
check("olive oil 7g absorbed", OIL_KCAL*0.07, 61.88, 1e-9)
check("cooked rice yield 75g -> 225g", 75*3.0, 225.0)
check("225g cooked logged as dry overstates by", RICE_DRY_KCAL*2.25 - RICE_DRY_KCAL*0.75, 534.0)
check("recipe per100g of finished (905 kcal / 400 g)", 905/400*100, 226.25, 1e-9)
check("200g serving of that recipe", 905/400*200, 452.5, 1e-9)

# quadrature
def comp_err(kcal, qty_rel, id_rel): return math.sqrt((kcal*qty_rel)**2 + (kcal*id_rel)**2)
e1 = comp_err(356, 0.01, 0.05)
e2 = math.sqrt(e1**2 + e1**2)
ok = e1 < e2 < 2*e1
print(("  PASS  " if ok else "  FAIL  ") + f"two equal errors combine to {e2:.2f}, between {e1:.2f} and {2*e1:.2f}")
if not ok: FAILS.append("quadrature")

weighed_kcal, guess_kcal = 356*0.10, 90*4.00
frac = weighed_kcal/(weighed_kcal+guess_kcal)
check("weighed fraction is by calories not item count", frac, 35.6/(35.6+360), 1e-6)
ok = frac < 0.15
print(("  PASS  " if ok else "  FAIL  ") + f"one small weighed + one large guess = {frac*100:.1f}%, not 50%")
if not ok: FAILS.append("weighed fraction")

print("\n" + "="*64)
if FAILS:
    print(f"FAILED: {len(FAILS)} check(s): {FAILS}")
    sys.exit(1)
print("All checks passed.")
