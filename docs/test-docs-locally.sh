#!/usr/bin/env bash
# Builds the fixed verified Wheeler documentation site without a renderer package manager.
set -euo pipefail

repository="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$repository"
rm -rf -- docs-site
./bootstrap/gradlew -p bootstrap -q :tools:wheeler --args='site -o docs-site'
printf 'Wheeler documentation: %s/docs-site/index.html\n' "$repository"
