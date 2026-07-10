#!/usr/bin/env python3
"""Plan parallel CI build waves with RPM dependency ordering."""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent

ARCH_META: dict[str, dict[str, str]] = {
    "x86_64": {"runner": "ubuntu-latest", "platform": "linux/amd64"},
    "aarch64": {"runner": "ubuntu-24.04-arm", "platform": "linux/arm64"},
}

# Wave 0 runs first (parallel within wave). Higher waves wait for prior publish.
WAVE_BY_STAGE: dict[tuple[str, str], int] = {
    ("bootstrap", "re2c"): 0,
    ("bootstrap", "rabbitmq-c"): 0,
    ("bootstrap", "libzip"): 1,
    ("php", "php"): 0,
    ("php", "extension:redis"): 2,
}


def wave_for(group: str, stage: str) -> int:
    if group == "php" and stage.startswith("extension:") and stage != "extension:redis":
        return 1
    return WAVE_BY_STAGE.get((group, stage), 0)


def changed_stages(group: str, arch: str, published: str) -> list[str]:
    env = os.environ.copy()
    result = subprocess.run(
        [str(SCRIPT_DIR / "ci-changed-stages.sh"), group, arch, published],
        capture_output=True,
        text=True,
        check=True,
        env=env,
    )
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit(f"Usage: {sys.argv[0]} <bootstrap|php> [published_dir]")

    group = sys.argv[1]
    published = sys.argv[2] if len(sys.argv) > 2 else "published"

    if group not in {"bootstrap", "php"}:
        raise SystemExit(f"ERROR: unknown group '{group}'")

    waves: dict[int, list[dict[str, str]]] = {0: [], 1: [], 2: []}

    for arch, meta in ARCH_META.items():
        for stage in changed_stages(group, arch, published):
            wave = wave_for(group, stage)
            waves[wave].append(
                {
                    "group": group,
                    "arch": arch,
                    "stage": stage,
                    "runner": meta["runner"],
                    "platform": meta["platform"],
                }
            )

    for wave_id in waves:
        waves[wave_id].sort(key=lambda item: (item["arch"], item["stage"]))

    payload = {
        "has_builds": any(waves[w] for w in waves),
        "wave0": waves[0],
        "wave1": waves[1],
        "wave2": waves[2],
    }
    print(json.dumps(payload))


if __name__ == "__main__":
    main()
