
# Makefile — helper targets for the relocate workflow
# Safety: `apply` requires an explicit `CONFIRM=yes` to avoid accidental destructive changes.
PYTHON?=python3
PIP?=pip3

.PHONY: install-deps validate validate-skill dry-run apply backup-main smoke-test

install-deps:
	$(PIP) install -r requirements.txt

validate:
	$(PYTHON) tools/validate_skill.py

validate-skill:
	if [ -z "$(FILE)" ]; then echo "Specify FILE=path/to/SKILL.md"; exit 2; fi
	$(PYTHON) tools/validate_skill.py "$(FILE)"

dry-run:
	if [ -z "$(SOURCE)" -o -z "$(DEST)" ]; then echo "Usage: make dry-run SOURCE=src DEST=dest"; exit 2; fi
	bash scripts/relocate-dryrun.sh "$(SOURCE)" "$(DEST)"

apply:
	@if [ "$(CONFIRM)" != "yes" ]; then echo "Dangerous: add CONFIRM=yes to apply"; exit 2; fi
	if [ -z "$(SOURCE)" -o -z "$(DEST)" ]; then echo "Usage: make apply SOURCE=src DEST=dest CONFIRM=yes"; exit 2; fi
	bash scripts/relocate-apply.sh "$(SOURCE)" "$(DEST)"

backup-main:
	git bundle create /tmp/main-backup.bundle --all

smoke-test:
	if [ -z "$(SOURCE)" -o -z "$(DEST)" ]; then echo "Usage: make smoke-test SOURCE=src DEST=dest"; exit 2; fi
	# Quick existence checks
	if [ -e "$(DEST)" ]; then echo "OK: dest exists: $(DEST)"; else echo "FAIL: dest missing: $(DEST)"; exit 2; fi

check-shapes:
	python3 tools/check_shapes_pr.py --base ${BASE_REF:-origin/main}

.PHONY: docs-check

docs-check:
	# For CI/strict checks set FAIL_ON_MISSING=1 so the target fails on missing refs.
	FAIL_ON_MISSING=1 bash scripts/docs/check_docs.sh

.PHONY: smoke-test-oci smoke-test-all

smoke-test-oci:
	@bash examples/oci/smoke-test.sh

smoke-test-all: smoke-test-oci
	@echo "All smoke-tests completed (non-destructive)."
