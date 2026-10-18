#!/bin/bash
# Concert backend test runner.
#
# Runs the same Maven commands as .github/workflows/backend-ci.yml, so local
# results match CI:
#   unit tests         ./mvnw -B -ntp test                  (surefire, no Docker)
#   integration tests  ./mvnw -B -ntp verify -DskipUTs=true (failsafe, Testcontainers,
#                                                            coverage gate)
set -euo pipefail

cd "$(dirname "$0")"
MVN=(./mvnw -B -ntp)

require_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo "Docker is not running. Integration tests start MySQL with Testcontainers." >&2
        exit 1
    fi
}

summary() {
    if command -v python3 > /dev/null 2>&1; then
        python3 ../.github/scripts/backend_test_summary.py .
    fi
    echo
    echo "Coverage report (unit + integration): target/site/jacoco/index.html"
    echo "Coverage report (unit only):          target/site/jacoco-unit/index.html"
}

show_help() {
    cat <<'EOF'
Usage: ./run-tests.sh [COMMAND]

Commands:
  all          Unit tests, then integration tests and the coverage gate, as in CI (default)
  unit         Unit and Spring slice tests only (no Docker needed)
  integration  Integration tests and the coverage gate (needs Docker)
  coverage     Same as "all", then print the coverage summary
  specific X   Run one test class X (unit or integration); coverage gate not applied
  clean        Remove build output and compile main and test code
  help         Show this help
EOF
}

case "${1:-all}" in
    all)
        require_docker
        "${MVN[@]}" test
        "${MVN[@]}" verify -DskipUTs=true
        ;;
    unit)
        "${MVN[@]}" test
        ;;
    integration)
        require_docker
        "${MVN[@]}" verify -DskipUTs=true
        ;;
    coverage)
        require_docker
        "${MVN[@]}" test
        "${MVN[@]}" verify -DskipUTs=true
        summary
        ;;
    specific)
        if [ -z "${2:-}" ]; then
            echo "Usage: ./run-tests.sh specific AuthServiceTest" >&2
            exit 1
        fi
        "${MVN[@]}" verify -Dtest="$2" -Dit.test="$2" \
            -Dsurefire.failIfNoSpecifiedTests=false -Dfailsafe.failIfNoSpecifiedTests=false \
            -Djacoco.haltOnFailure=false
        ;;
    clean)
        "${MVN[@]}" clean test-compile
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        echo "Unknown command: $1" >&2
        show_help
        exit 1
        ;;
esac
