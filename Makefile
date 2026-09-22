# Nomos
PY ?= python3
export PYTHONPATH := src

.PHONY: all lean corpus seed test notebooks clean fetch-restricted dist

all: lean corpus seed test

# `make corpus` first on a fresh checkout: the built corpus is not shipped.

lean:                       ## build the Lean library and the exporter
	cd lean && lake build

corpus:                     ## rebuild data/corpus/provisions.jsonl.gz from data/raw
	$(PY) -m nomos.build_corpus

corpus-permissive:          ## the same, excluding non-commercially licensed texts
	$(PY) -m nomos.build_corpus --no-nc --out data/corpus/provisions_permissive.jsonl.gz

seed: lean                  ## re-export the seed formalisations from Lean
	$(PY) -m nomos.build_seed

test:                       ## run the test suite (needs lean for the full set)
	$(PY) tests/test_nomos.py

notebooks:                  ## regenerate the notebooks from tools/build_notebooks.py
	$(PY) tools/build_notebooks.py

run-notebooks: notebooks    ## regenerate and execute 01 and 02
	$(PY) -m jupyter nbconvert --to notebook --execute --inplace \
	  --ExecutePreprocessor.timeout=900 notebooks/01_corpus.ipynb notebooks/02_autoformalize.ipynb

fetch-restricted:           ## fetch the sources the build sandbox could not reach
	$(PY) -m nomos.fetch.restricted

clean:
	rm -rf lean/.lake/build __pycache__ src/nomos/__pycache__ .pytest_cache

help:
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
