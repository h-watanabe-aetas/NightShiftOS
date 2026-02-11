# Acceptance Test Execution

## 1. Install dependencies
```bash
python3 -m pip install -r tests/acceptance/requirements.txt
```

## 2. Generate step stubs
```bash
python3 scripts/generate_behave_steps.py
```

## 3. Run all acceptance tests
```bash
python3 -m behave docs/tests/acceptance
```

## 4. Run via helper script
```bash
# Install deps + run
INSTALL_DEPS=1 scripts/run_acceptance_tests.sh

# Run only
scripts/run_acceptance_tests.sh

# Install deps + run with option style
scripts/run_acceptance_tests.sh --install-deps
```

## 5. Run one feature
```bash
python3 -m behave docs/tests/acceptance/phase1_cloud.feature
```

## 6. Run one scenario by tag
```bash
python3 -m behave docs/tests/acceptance --tags=@NS-CLD-004

# helper script style
scripts/run_acceptance_tests.sh --issue NS-CLD-004
```

## 7. TDD cycle (issue-driven)
```bash
# RED: target one issue
scripts/run_acceptance_tests.sh --issue NS-PLT-001

# GREEN: implement code, rerun same issue until pass
scripts/run_acceptance_tests.sh --issue NS-PLT-001

# REFACTOR safety check: run all Phase1/P0
scripts/run_acceptance_tests.sh -- --tags=@phase1 --tags=@p0
```
