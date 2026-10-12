#!/usr/bin/env bash
set -euo pipefail

# Builds an unofficial custom flashrom v1.6.0 with ONLY two UI changes.
# Upstream: https://github.com/flashrom/flashrom
# Original source and its license/copyright notices stay intact.

ROOT="${1:-$HOME/flashrom-serprog-custom-src}"
if [[ ! -d "$ROOT/.git" ]]; then
  git clone https://github.com/flashrom/flashrom.git "$ROOT"
fi
cd "$ROOT"
git fetch --tags origin
git checkout --detach v1.6.0

# Avoid silently overwriting unrelated local source edits.
python3 - <<'PY'
from pathlib import Path
changes = {
    "cli_classic.c": (
        "struct cli_options options = { 0 };",
        "struct cli_options options = { .show_progress = true };"
    ),
    "cli_common.c": (
        "(chip->tested.wp == BAD) || (chip->tested.wp == NT)){",
        "(chip->tested.wp == BAD)){"
    )
}
for name, (old, new) in changes.items():
    f = Path(name)
    src = f.read_text()
    if src.count(new) == 1 and old not in src:
        print(f"{name}: already modified")
    elif src.count(old) == 1:
        f.write_text(src.replace(old, new, 1))
        print(f"{name}: modified")
    else:
        raise SystemExit(f"Unexpected contents in {name}: stopping")
PY

git diff --check
git diff -- cli_classic.c cli_common.c

if [[ ! -f build-custom/build.ninja ]]; then
    meson setup build-custom -Dprogrammer=serprog -Dtests=disabled --buildtype=release
else
    meson configure build-custom -Dtests=disabled
fi
meson compile -C build-custom
./build-custom/flashrom --version
echo "Built: $ROOT/build-custom/flashrom"
echo "No system installation was performed."
