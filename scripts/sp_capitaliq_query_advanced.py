import logging
import os
from pathlib import Path

import xlwings as xw

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
log = logging.getLogger(__name__)

# --- Configuration ---
EXCEL_PATH   = Path(r"D:\projects\Archie Copper\sp_capital_iq_copper.xls")
SHEET_NAME   = "Sheet1"   # source sheet holding the property IDs
PROP_ID_COL  = 2          # Column A (adjust if needed)
OUTPUT_COL   = 4          # first output column (D); each data item gets the next column
HEADER_ROW   = 2
WRITE_HEADERS = True       # write data-item names into row HEADER_ROW - 1

DATASET_ID   = "243327"
PRODUCT_TYPE = "Concentrate"  # Just for iron ore

YEARS   = [f"{y}Y" for y in range(2025, 2061)]  # 2025Y .. 2060Y (inclusive) → one sheet each
YEARS = YEARS[:1]  # Only for 2025
YEAR_PH = "<YEAR>"                               # placeholder → replaced by each sheet's year
DATE_PH = "<YEAR_END>"   # → replaced with 12/31/<year> per sheet

COMMODITIES = "Cu"      # Copper is Cu and iron ore is Fe in cap IQ dataset

DATA_ITEM = [
    "ACTV_STATUS", "OPERATOR_NAME", "OPERATOR_HQ", "OPERATOR_CITY_STATE",
    "OPERATOR_LOCATION", "OPERATOR_FRGN_PROVINCE", "OPERATOR_COUNTRY", "OWNER_LIST",
    "OWNER_NAME_1", "OWNER1_PCT", "OWNER1_HQ", "OWNER1_CITY_STATE", "OWNER1_LOCATION",
    "OWNER1_FRGN_PROVINCE", "OWNER1_COUNTRY", "OWNER2_NAME", "OWNER2_PCT", "OWNER2_HQ",
    "OWNER2_CITY_STATE", "OWNER2_LOCATION", "OWNER2_FRGN_PROVINCE", "OWNER2_COUNTRY",
    "OWNER3_NAME", "OWNER3_PCT", "OWNER3_HQ", "OWNER3_CITY_STATE", "OWNER3_LOCATION",
    "OWNER3_FRGN_PROVINCE", "OWNER3_COUNTRY", "OWNER4_NAME", "OWNER4_PCT", "OWNER4_HQ",
    "OWNER4_CITY_STATE", "OWNER4_LOCATION", "OWNER4_FRGN_PROVINCE", "OWNER4_COUNTRY",
    "OWNER5_NAME", "OWNER5_PCT", "OWNER5_HQ", "OWNER5_CITY_STATE", "OWNER5_LOCATION",
    "OWNER5_FRGN_PROVINCE", "OWNER5_COUNTRY", "STATE_PROVINCE", "COUNTRY_NAME",
    "LATITUDE", "LONGITUDE", "COORDINATE_ACCURACY", "PRODUCTION_CAPACITY_TONNE",
    "COMMODITY_PRODUCTION_TONNE_BY_PERIOD", "CONCENTRATE_PRODUCTION_KILOTONNES_COPPER",
    "CONCENTRATE_METAL_PRICE_TONNE_COPPER", "CONCENTRATE_GRD_PCT_COPPER",
    "SCOPE_1_2_TRANSPORTATION_EMISSIONS_ORE_PROCESSED_BULK_METALS", "RESV_ORE_TONNAGE",
]

# 3rd argument: generic SNL field for owner labels; label itself otherwise; Cap IQ dataset forluma does not differentiate owners by the 3rd argument but by the 4th
BASE_FIELD = {
    "OWNER_NAME_1": "OWNER_NAME", "OWNER1_PCT": "OWNER_PCT", "OWNER1_HQ": "OWNER_HQ",
    "OWNER1_CITY_STATE": "OWNER_CITY_STATE", "OWNER1_LOCATION": "OWNER_LOCATION",
    "OWNER1_FRGN_PROVINCE": "OWNER_FRGN_PROVINCE", "OWNER1_COUNTRY": "OWNER_COUNTRY",
    "OWNER2_NAME": "OWNER_NAME", "OWNER2_PCT": "OWNER_PCT", "OWNER2_HQ": "OWNER_HQ",
    "OWNER2_CITY_STATE": "OWNER_CITY_STATE", "OWNER2_LOCATION": "OWNER_LOCATION",
    "OWNER2_FRGN_PROVINCE": "OWNER_FRGN_PROVINCE", "OWNER2_COUNTRY": "OWNER_COUNTRY",
    "OWNER3_NAME": "OWNER_NAME", "OWNER3_PCT": "OWNER_PCT", "OWNER3_HQ": "OWNER_HQ",
    "OWNER3_CITY_STATE": "OWNER_CITY_STATE", "OWNER3_LOCATION": "OWNER_LOCATION",
    "OWNER3_FRGN_PROVINCE": "OWNER_FRGN_PROVINCE", "OWNER3_COUNTRY": "OWNER_COUNTRY",
    "OWNER4_NAME": "OWNER_NAME", "OWNER4_PCT": "OWNER_PCT", "OWNER4_HQ": "OWNER_HQ",
    "OWNER4_CITY_STATE": "OWNER_CITY_STATE", "OWNER4_LOCATION": "OWNER_LOCATION",
    "OWNER4_FRGN_PROVINCE": "OWNER_FRGN_PROVINCE", "OWNER4_COUNTRY": "OWNER_COUNTRY",
    "OWNER5_NAME": "OWNER_NAME", "OWNER5_PCT": "OWNER_PCT", "OWNER5_HQ": "OWNER_HQ",
    "OWNER5_CITY_STATE": "OWNER_CITY_STATE", "OWNER5_LOCATION": "OWNER_LOCATION",
    "OWNER5_FRGN_PROVINCE": "OWNER_FRGN_PROVINCE", "OWNER5_COUNTRY": "OWNER_COUNTRY",
}

# Extra SNLData arguments per data item (owner number, year, product type, ...).
# Items not listed here use the plain 3-argument formula.
# Use YEAR_PH wherever the sheet's year should be substituted.
EXTRA_ARGS = {
    # owner fields → owner number as 4th arg
    # owner fields → "owner N" as 4th arg
    "OWNER_NAME_1": ("Owner 1",), "OWNER1_PCT": ("Owner 1",), "OWNER1_HQ": ("Owner 1",),
    "OWNER1_CITY_STATE": ("Owner 1",), "OWNER1_LOCATION": ("Owner 1",),
    "OWNER1_FRGN_PROVINCE": ("Owner 1",), "OWNER1_COUNTRY": ("Owner 1",),
    "OWNER2_NAME": ("Owner 2",), "OWNER2_PCT": ("Owner 2",), "OWNER2_HQ": ("Owner 2",),
    "OWNER2_CITY_STATE": ("Owner 2",), "OWNER2_LOCATION": ("Owner 2",),
    "OWNER2_FRGN_PROVINCE": ("Owner 2",), "OWNER2_COUNTRY": ("Owner 2",),
    "OWNER3_NAME": ("Owner 3",), "OWNER3_PCT": ("Owner 3",), "OWNER3_HQ": ("Owner 3",),
    "OWNER3_CITY_STATE": ("Owner 3",), "OWNER3_LOCATION": ("Owner 3",),
    "OWNER3_FRGN_PROVINCE": ("Owner 3",), "OWNER3_COUNTRY": ("Owner 3",),
    "OWNER4_NAME": ("Owner 4",), "OWNER4_PCT": ("Owner 4",), "OWNER4_HQ": ("Owner 4",),
    "OWNER4_CITY_STATE": ("Owner 4",), "OWNER4_LOCATION": ("Owner 4",),
    "OWNER4_FRGN_PROVINCE": ("Owner 4",), "OWNER4_COUNTRY": ("Owner 4",),
    "OWNER5_NAME": ("Owner 5",), "OWNER5_PCT": ("Owner 5",), "OWNER5_HQ": ("Owner 5",),
    "OWNER5_CITY_STATE": ("Owner 5",), "OWNER5_LOCATION": ("Owner 5",),
    "OWNER5_FRGN_PROVINCE": ("Owner 5",), "OWNER5_COUNTRY": ("Owner 5",),
    # period / production fields → year as 4th arg
    "PRODUCTION_CAPACITY_TONNE": (COMMODITIES,),
    "COMMODITY_PRODUCTION_TONNE_BY_PERIOD": (YEAR_PH, "Best Of|" + COMMODITIES),
    "CONCENTRATE_PRODUCTION_KILOTONNES_COPPER": (YEAR_PH, COMMODITIES),
    "CONCENTRATE_METAL_PRICE_TONNE_COPPER": (YEAR_PH, COMMODITIES),
    "CONCENTRATE_GRD_PCT_COPPER": (YEAR_PH, COMMODITIES),
    "SCOPE_1_2_TRANSPORTATION_EMISSIONS_ORE_PROCESSED_BULK_METALS": (DATE_PH,),
    "RESV_ORE_TONNAGE": (YEAR_PH,),
}


def make_formula(pid, di, year):
    year_end = f"12/31/{year.rstrip('Y')}"   # "2025Y" -> "12/31/2025"
    subst = {YEAR_PH: year, DATE_PH: year_end}
    extra = tuple(subst.get(a, a) for a in EXTRA_ARGS.get(di, ()))
    field = BASE_FIELD.get(di, di)
    args = (DATASET_ID, pid, field) + extra
    return "=SNLData(" + ", ".join(f'"{a}"' for a in args) + ")"


def get_or_create_sheet(wb, name):
    if name in [s.name for s in wb.sheets]:
        return wb.sheets[name]
    return wb.sheets.add(name, after=wb.sheets[-1])


def main() -> None:
    SNL_ADDIN = r"C:\Program Files\SNL Financial\SNLxl\SNLXLAddin.xla"

    app = xw.App(visible=True)
    app.api.Workbooks.Open(SNL_ADDIN)  # load SNL add-in so SNLData is recognized
    wb  = app.books.open(str(EXCEL_PATH))
    src = wb.sheets[SHEET_NAME]

    # Read property IDs from the source sheet
    last_row = src.cells(src.cells.last_cell.row, PROP_ID_COL).end("up").row
    prop_ids = src.range(src.cells(HEADER_ROW, PROP_ID_COL),
                         src.cells(last_row, PROP_ID_COL)).value
    if not isinstance(prop_ids, list):
        prop_ids = [prop_ids]
    # Convert floats like 35760.0 → "35760"
    prop_ids = [str(int(float(p))) for p in prop_ids]
    n_rows = len(prop_ids)

    log.info("Found %d properties — building %d yearly sheets...", n_rows, len(YEARS))

    app.screen_updating = False
    app.display_alerts = False
    app.calculation = "manual"   # prevent CapIQ from firing during write

    for year in YEARS:
        ws = get_or_create_sheet(wb, year)

        # Property IDs in their column, formulas one column per data item
        ws.range(ws.cells(HEADER_ROW, PROP_ID_COL),
                 ws.cells(HEADER_ROW + n_rows - 1, PROP_ID_COL)).value = \
            [[pid] for pid in prop_ids]

        formulas = [[make_formula(pid, di, year) for di in DATA_ITEM]
                    for pid in prop_ids]
        ws.range(ws.cells(HEADER_ROW, OUTPUT_COL),
                 ws.cells(HEADER_ROW + n_rows - 1, OUTPUT_COL + len(DATA_ITEM) - 1)).value = formulas

        if WRITE_HEADERS:
            ws.range(ws.cells(HEADER_ROW - 1, OUTPUT_COL),
                     ws.cells(HEADER_ROW - 1, OUTPUT_COL + len(DATA_ITEM) - 1)).value = DATA_ITEM

        log.info("  %s — %d formulas", year, n_rows * len(DATA_ITEM))

    app.screen_updating = True
    app.calculation = "automatic"

    log.info("Done — %d sheets written (%s..%s).", len(YEARS), YEARS[0], YEARS[-1])
    log.info("Now click 'Refresh' on the S&P Cap IQ Pro ribbon.")
    os._exit(0)


main()