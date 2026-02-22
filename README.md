# car-listing-data-pipeline

Standalone pipeline for collecting authorized Drom car listings and building ML-ready artifacts.

This repository contains only data pipeline logic. The application repository stays clean from scraping/filtering internals.

## Data location

By default, this pipeline writes artifacts to the sibling app repository path:

- `../car-listing-visual-verification/data`

You can override it with:

```bash
export CAR_LISTING_DATA_DIR=/absolute/path/to/data
```

## Quick start

```bash
make requirements
python3 -m car_listing_data_pipeline.data.drom --help
```

Run full pipeline:

```bash
make drom-run-all
```

Stage-by-stage:

```bash
make drom-discover
make drom-fetch-meta
make drom-fetch-images
make drom-validate
make drom-filter-content
make drom-dedup
make drom-manifest
make drom-split
```

## Hugging Face release and upload

Build release folder:

```bash
make hf-release
```

Upload (single pass):

```bash
make hf-upload DATASET_REPO=<hf-user>/<dataset-name> HF_UPLOAD_WORKERS=4
```

Upload in resilient batches (recommended for slow internet):

```bash
make hf-upload-batch DATASET_REPO=<hf-user>/<dataset-name> HF_UPLOAD_WORKERS=4
```

## Config

- Class/source config file: `configs/classes.yaml`
- CLI entrypoint: `python3 -m car_listing_data_pipeline.data.drom`

## Compliance

Use only with an explicit agreement with drom.ru.
