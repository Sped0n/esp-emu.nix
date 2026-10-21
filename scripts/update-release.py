#!/usr/bin/env python3
import json
import os
from pathlib import Path
import re
import subprocess
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parent.parent


def output(command: list[str]) -> str:
    return subprocess.check_output(
        command, cwd=ROOT, text=True, timeout=300
    ).strip()


def replace_once(contents: str, old: str, new: str) -> str:
    if contents.count(old) != 1:
        raise ValueError(f"Expected exactly one occurrence of {old!r} in package")
    return contents.replace(old, new, 1)


def main() -> None:
    current = output(["nix", "eval", "--raw", "path:.#esp-emu.version"])
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "esp-emu-release-updater",
    }
    if token := os.environ.get("GH_TOKEN"):
        headers["Authorization"] = f"Bearer {token}"
    request = Request(
        "https://api.github.com/repos/espressif/esp-emulator/releases/latest",
        headers=headers,
    )
    with urlopen(request, timeout=30) as response:
        tag = json.load(response)["tag_name"]
    if not re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+", tag):
        raise ValueError(f"Unsupported release tag: {tag}")
    version = tag[1:]
    if version == current:
        print(f"esp-emu is up to date ({current}).")
        return
    if tuple(map(int, version.split("."))) < tuple(map(int, current.split("."))):
        raise ValueError(f"Refusing to downgrade esp-emu from {current} to {version}")

    package = ROOT / "packages/esp-emu/default.nix"
    contents = package.read_text(encoding="utf-8")
    systems = json.loads(output([
        "nix", "eval", "--json", "path:.#packages", "--apply", "builtins.attrNames",
    ]))
    for system in systems:
        source = f"path:.#packages.{system}.esp-emu.src"
        old_url = output(["nix", "eval", "--raw", f"{source}.url"])
        old_hash = output(["nix", "eval", "--raw", f"{source}.outputHash"])
        new_url = old_url.replace(current, version)
        new_hash = json.loads(output([
            "nix", "store", "prefetch-file", "--json", new_url,
        ]))["hash"]
        contents = replace_once(contents, old_hash, new_hash)
    contents = replace_once(
        contents, f'version = "{current}";', f'version = "{version}";'
    )
    package.write_text(contents, encoding="utf-8")
    print(f"Updated esp-emu from {current} to {version}.")
    if "GITHUB_OUTPUT" in os.environ:
        with Path(os.environ["GITHUB_OUTPUT"]).open("a", encoding="utf-8") as outputs:
            outputs.write(f"updated=true\nversion={version}\n")


if __name__ == "__main__":
    main()
