#!/usr/bin/env bash
# Launches the pinned local documentation renderer from its owned package root.
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
npm start
