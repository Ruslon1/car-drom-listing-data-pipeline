from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv
from loguru import logger

load_dotenv()

PROJ_ROOT = Path(__file__).resolve().parents[1]
_DEFAULT_APP_DATA_DIR = PROJ_ROOT.parent / "car-listing-visual-verification" / "data"


def _resolve_data_dir() -> Path:
    raw_data_dir = os.getenv("CAR_LISTING_DATA_DIR")
    if raw_data_dir:
        data_dir = Path(raw_data_dir).expanduser()
        if not data_dir.is_absolute():
            data_dir = (PROJ_ROOT / data_dir).resolve()
        return data_dir

    if _DEFAULT_APP_DATA_DIR.exists():
        return _DEFAULT_APP_DATA_DIR

    return PROJ_ROOT / "data"


DATA_DIR = _resolve_data_dir()
RAW_DATA_DIR = DATA_DIR / "raw"
INTERIM_DATA_DIR = DATA_DIR / "interim"
PROCESSED_DATA_DIR = DATA_DIR / "processed"
EXTERNAL_DATA_DIR = DATA_DIR / "external"
DROM_MANIFEST_FILE = PROCESSED_DATA_DIR / "manifest.parquet"
DROM_CLASS_MAPPING_FILE = PROCESSED_DATA_DIR / "class_mapping.parquet"

MODELS_DIR = PROJ_ROOT / "models"

REPORTS_DIR = PROJ_ROOT / "reports"
FIGURES_DIR = REPORTS_DIR / "figures"

logger.info(f"PROJ_ROOT={PROJ_ROOT} DATA_DIR={DATA_DIR}")

try:
    from tqdm import tqdm

    logger.remove(0)
    logger.add(lambda msg: tqdm.write(msg, end=""), colorize=True)
except ModuleNotFoundError:
    pass
