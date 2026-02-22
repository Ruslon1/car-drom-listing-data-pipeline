#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_NAME = car-listing-data-pipeline
PYTHON_INTERPRETER = python3
DROM_CLASSES = configs/classes.yaml
DROM_QPS = 1.5
DROM_CONCURRENCY = 12
DROM_LISTINGS_PER_CLASS = 150
DROM_CLI = $(PYTHON_INTERPRETER) -m car_listing_data_pipeline.data.drom

# Default keeps dataset artifacts in the app repository (sibling directory).
DATA_DIR ?= ../car-listing-visual-verification/data
HF_RELEASE_DIR ?= $(DATA_DIR)/processed/hf_release
HF_DATASET_NAME = drom-car-listings-99-classes
HF_FILE_MODE = hardlink
HF_LICENSE = other
HF_UPLOAD_WORKERS ?= 4

#################################################################################
# COMMANDS                                                                      #
#################################################################################

.PHONY: requirements
requirements:
	$(PYTHON_INTERPRETER) -m pip install -U pip
	$(PYTHON_INTERPRETER) -m pip install -r requirements.txt

.PHONY: lint
lint:
	ruff format --check
	ruff check

.PHONY: format
format:
	ruff check --fix
	ruff format

#################################################################################
# PIPELINE STAGES                                                               #
#################################################################################

.PHONY: drom-discover
drom-discover:
	$(DROM_CLI) discover --classes $(DROM_CLASSES) --qps $(DROM_QPS) --concurrency $(DROM_CONCURRENCY) --max-listings-per-class $(DROM_LISTINGS_PER_CLASS)

.PHONY: drom-fetch-meta
drom-fetch-meta:
	$(DROM_CLI) fetch-meta --classes $(DROM_CLASSES) --qps $(DROM_QPS) --concurrency $(DROM_CONCURRENCY)

.PHONY: drom-fetch-images
drom-fetch-images:
	$(DROM_CLI) fetch-images --classes $(DROM_CLASSES) --qps $(DROM_QPS) --concurrency $(DROM_CONCURRENCY)

.PHONY: drom-validate
drom-validate:
	$(DROM_CLI) validate

.PHONY: drom-filter-content
drom-filter-content:
	$(DROM_CLI) filter-content

.PHONY: drom-dedup
drom-dedup:
	$(DROM_CLI) dedup

.PHONY: drom-manifest
drom-manifest:
	$(DROM_CLI) prepare-manifest

.PHONY: drom-split
drom-split:
	$(DROM_CLI) split --val-ratio 0.1 --test-ratio 0.1 --seed 42

.PHONY: drom-run-all
drom-run-all:
	$(DROM_CLI) run-all --classes $(DROM_CLASSES) --qps $(DROM_QPS) --concurrency $(DROM_CONCURRENCY) --max-listings-per-class $(DROM_LISTINGS_PER_CLASS) --no-cache

.PHONY: drom-prune-artifacts
drom-prune-artifacts:
	rm -rf $(DATA_DIR)/raw/drom/pages $(DATA_DIR)/interim/drom
	mkdir -p $(DATA_DIR)/raw/drom/pages $(DATA_DIR)/interim/drom

.PHONY: data
data: requirements drom-run-all drom-prune-artifacts

#################################################################################
# HUGGING FACE                                                                  #
#################################################################################

.PHONY: hf-release
hf-release:
	$(DROM_CLI) prepare-hf-release --manifest-path $(DATA_DIR)/processed/manifest.parquet --class-mapping-path $(DATA_DIR)/processed/class_mapping.parquet --output-dir $(HF_RELEASE_DIR) --dataset-name $(HF_DATASET_NAME) --file-mode $(HF_FILE_MODE) --license-id $(HF_LICENSE)

.PHONY: hf-upload
hf-upload: hf-release
	@if [ -z "$(DATASET_REPO)" ]; then echo "Usage: make hf-upload DATASET_REPO=<hf-user>/<dataset-name>"; exit 1; fi
	hf repo create $(DATASET_REPO) --repo-type dataset --private || true
	hf upload-large-folder --repo-type dataset $(DATASET_REPO) $(HF_RELEASE_DIR) --num-workers $(HF_UPLOAD_WORKERS)

.PHONY: hf-upload-batch
hf-upload-batch: hf-release
	@if [ -z "$(DATASET_REPO)" ]; then echo "Usage: make hf-upload-batch DATASET_REPO=<hf-user>/<dataset-name>"; exit 1; fi
	hf repo create $(DATASET_REPO) --repo-type dataset --private || true
	hf upload-large-folder --repo-type dataset $(DATASET_REPO) $(HF_RELEASE_DIR) --include "*.parquet" --include "README.md" --include "release_stats.json" --num-workers $(HF_UPLOAD_WORKERS)
	hf upload-large-folder --repo-type dataset $(DATASET_REPO) $(HF_RELEASE_DIR) --include "images/train/**" --num-workers $(HF_UPLOAD_WORKERS)
	hf upload-large-folder --repo-type dataset $(DATASET_REPO) $(HF_RELEASE_DIR) --include "images/validation/**" --num-workers $(HF_UPLOAD_WORKERS)
	hf upload-large-folder --repo-type dataset $(DATASET_REPO) $(HF_RELEASE_DIR) --include "images/test/**" --num-workers $(HF_UPLOAD_WORKERS)

#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help

define PRINT_HELP_PYSCRIPT
import re, sys; \
lines = '\n'.join([line for line in sys.stdin]); \
matches = re.findall(r'\n## (.*)\n[\s\S]+?\n([a-zA-Z_-]+):', lines); \
print('Available rules:\n'); \
print('\n'.join(['{:25}{}'.format(*reversed(match)) for match in matches]))
endef
export PRINT_HELP_PYSCRIPT

help:
	@$(PYTHON_INTERPRETER) -c "${PRINT_HELP_PYSCRIPT}" < $(MAKEFILE_LIST)
