import logging
import os
from pathlib import Path

import xlwings as xw

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
log = logging.getLogger(__name__)

# --- Configuration ---
EXCEL_PATH   = Path(r"D:\projects\Archie_Steel\data\SPGlobalCaptialQ\SPGlobal_Export - Copy.xlsx")
SHEET_NAME   = "Sheet1"
PROP_ID_COL  = 2        # Column A (adjust if needed)
OUTPUT_COL   = 7        # Column E
HEADER_ROW   = 2

DATASET_ID   = "243327"
YEAR         = "2025Y"
PRODUCT_TYPE = "Concentrate"
DATA_ITEM    = "PROP_NAME"


def main() -> None:
    SNL_ADDIN = r"C:\Program Files (x86)\SNL Financial\SNLxl\SNLXLAddin.xla"

    app = xw.App(visible=True)
    app.api.Workbooks.Open(SNL_ADDIN)  # load SNL add-in so SNLData is recognized
    wb  = app.books.open(str(EXCEL_PATH))
    ws  = wb.sheets[SHEET_NAME]

    # Find last row with data in PROP_ID column
    last_row = ws.cells(ws.cells.last_cell.row, PROP_ID_COL).end("up").row
    prop_ids = ws.range(ws.cells(HEADER_ROW, PROP_ID_COL),
                        ws.cells(last_row, PROP_ID_COL)).value
    if not isinstance(prop_ids, list):
        prop_ids = [prop_ids]

    log.info("Found %d properties — writing formulas...", len(prop_ids))

    app.screen_updating = False
    app.display_alerts = False
    app.calculation = "manual"   # prevent CapIQ from firing during write

    # Convert floats like 35760.0 → "35760"
    prop_ids = [str(int(float(p))) for p in prop_ids]
    formulas = [[f'=SNLData("{DATASET_ID}", "{pid}", "{DATA_ITEM}")'] for pid in prop_ids]
    ws.range(ws.cells(HEADER_ROW, OUTPUT_COL),
             ws.cells(HEADER_ROW + len(prop_ids) - 1, OUTPUT_COL)).value = formulas

    app.screen_updating = True
    app.calculation = "automatic"

    log.info("Done — %d formulas written to column E.", len(prop_ids))
    log.info("Now click 'Refresh' on the S&P Cap IQ Pro ribbon.")
    os._exit(0)


main()
