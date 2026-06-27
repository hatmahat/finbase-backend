.PHONY: install ingest ingest-dir import-csv migrate revert verify

install:
	pip install -r requirements.txt

# Usage: make ingest f=data/statements/bca-jan-2026.pdf w="BCA (Leisure)"
ingest:
	python -m app.main ingest $(f) --wallet "$(w)"

# Usage: make ingest-dir d=data/statements w="BCA (Leisure)"
ingest-dir:
	python -m app.main ingest-dir $(d) --wallet "$(w)"

# Usage: make import-csv
import-csv:
	python -m app.main import-csv "data/imports/transactions-from-1-1-2025-to-31-12-2026.csv"

migrate:
	cd migrations && sqitch deploy --verify

revert:
	cd migrations && sqitch revert

verify:
	cd migrations && sqitch verify
