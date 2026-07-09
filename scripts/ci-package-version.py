#!/usr/bin/env python3
"""Resolve RPM name-version-release patterns from spec files for CI change detection."""
from __future__ import annotations

import glob
import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent

STAGE_SPECS: dict[str, list[Path]] = {
    "re2c": [PROJECT_ROOT / "packaging/re2c.spec"],
    "libzip": [PROJECT_ROOT / "packaging/libzip.spec"],
    "rabbitmq-c": [PROJECT_ROOT / "packaging/rabbitmq-c.spec"],
    "php": [
        PROJECT_ROOT / "packaging/php85.spec",
        PROJECT_ROOT / "packaging/macros.php85",
        *sorted(Path(p) for p in glob.glob(str(PROJECT_ROOT / "packaging/configs/*"))),
    ],
}

for ext in ("igbinary", "redis", "apcu", "amqp", "imagick", "xdebug"):
    STAGE_SPECS[f"extension:{ext}"] = [
        PROJECT_ROOT / "extensions/macros.inc",
        PROJECT_ROOT / f"extensions/{ext}.spec",
    ]


def expand(value: str, globals_map: dict[str, str]) -> str:
    previous = None
    while value != previous:
        previous = value
        value = re.sub(
            r"%\{(\w+)\}",
            lambda match: globals_map.get(match.group(1), match.group(0)),
            value,
        )
    value = value.replace("%{?dist}", ".photon5")
    value = value.replace("%{dist}", ".photon5")
    return value.strip()


def parse_spec(path: Path) -> tuple[str, str, str]:
    globals_map: dict[str, str] = {"dist": ".photon5"}
    name = version = release = ""

    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        global_match = re.match(r"%global\s+(\w+)\s+(.+)", stripped)
        if global_match:
            globals_map[global_match.group(1)] = global_match.group(2).strip()
            continue
        if stripped.startswith("Name:"):
            name = expand(stripped.split(None, 1)[1], globals_map)
        elif stripped.startswith("Version:"):
            version = expand(stripped.split(None, 1)[1], globals_map)
        elif stripped.startswith("Release:"):
            release = expand(stripped.split(None, 1)[1], globals_map)

    if not name or not version or not release:
        raise SystemExit(f"ERROR: could not parse NVR from {path}")

    release = release.rstrip("%")
    return name, version, release


def stage_nvrs(stage: str) -> list[tuple[str, str, str]]:
    if stage not in STAGE_SPECS:
        raise SystemExit(f"ERROR: unknown stage '{stage}'")

    if stage == "php":
        return [parse_spec(PROJECT_ROOT / "packaging/php85.spec")]

    if stage.startswith("extension:"):
        return [parse_spec(STAGE_SPECS[stage][-1])]

    return [parse_spec(STAGE_SPECS[stage][0])]


def rpm_glob(name: str, version: str, release: str, arch: str) -> str:
    return f"{name}-{version}-{release}*.{arch}.rpm"


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit(f"Usage: {sys.argv[0]} <stage> <arch>")

    stage, arch = sys.argv[1], sys.argv[2]
    for name, version, release in stage_nvrs(stage):
        print(rpm_glob(name, version, release, arch))


if __name__ == "__main__":
    main()
