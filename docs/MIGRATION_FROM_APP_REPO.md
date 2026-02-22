# Migration Notes

Goal: keep dataset artifacts near the app while running scraping/filtering in a dedicated repository.

## Current split

- App repo: `car-listing-visual-verification`
  - keeps local dataset files under `data/`
  - consumes prepared artifacts
- Pipeline repo: `car-listing-data-pipeline`
  - contains scraping/filtering/dedup/manifest/HF upload logic

## First-step migration completed

- Copied Drom pipeline modules into this repository under `car_listing_data_pipeline/data/`
- Added standalone config and Makefile
- Kept defaults pointed to sibling app `data/` directory

## Next step (optional hard cut)

After you verify this pipeline repo in production, remove pipeline modules from the app repo and keep only inference/app code there.
