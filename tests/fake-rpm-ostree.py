#!/usr/bin/python3

import argparse
import json
import sys
from pathlib import Path
from string import Template
from time import sleep

STATE_FILE = Path("/tmp/mock_rpm_ostree_state.json")

DEFAULT_STATE = {
    "active": [
        "neovim",
        "other-active-package-1",
        "other-active-package-2",
        "other-active-package-3",
        "other-active-package-4",
    ],
    "staged": [
        "neovim",
        "other-staged-package-a",
        "other-staged-package-b",
        "other-staged-package-c",
        "other-staged-package-d",
    ],
}


def load_state():
    if not STATE_FILE.exists():
        save_state(DEFAULT_STATE)
        return {
            "active": list(DEFAULT_STATE["active"]),
            "staged": list(DEFAULT_STATE["staged"]),
        }
    with STATE_FILE.open("r", encoding="utf-8") as f:
        return json.load(f)


def save_state(state):
    with STATE_FILE.open("w", encoding="utf-8") as f:
        json.dump(state, f, indent=2)


def format_packages(packages):
    return ", ".join(json.dumps(pkg) for pkg in packages)


def main():
    parser = argparse.ArgumentParser(
        description="Run specific actions based on arguments."
    )

    subparsers = parser.add_subparsers(dest="mode", required=True)

    subparsers.add_parser("update")
    subparsers.add_parser("restore")
    subparsers.add_parser("reset")

    install_parser = subparsers.add_parser("install")
    install_parser.add_argument(
        "packages",
        nargs="+",
    )

    remove_parser = subparsers.add_parser("remove")
    remove_parser.add_argument(
        "packages",
        nargs="+",
    )

    status_parser = subparsers.add_parser("status")
    status_parser.add_argument(
        "--json",
        action="store_true",
    )

    args, _ = parser.parse_known_args()

    sleep(0.3)

    if args.mode == "update":
        print("not implemented")
        sys.exit(1)

    elif args.mode == "restore":
        save_state(DEFAULT_STATE)

    elif args.mode == "reset":
        state = load_state()
        state["staged"] = []
        save_state(state)

    elif args.mode == "install":
        state = load_state()
        for pkg in args.packages:
            if pkg not in state["staged"]:
                state["staged"].append(pkg)
        save_state(state)

    elif args.mode == "remove":
        state = load_state()
        to_remove = set(args.packages)
        state["staged"] = [pkg for pkg in state["staged"] if pkg not in to_remove]
        save_state(state)

    elif args.mode == "status":
        state = load_state()
        if args.json:
            template = Template("""
{
    "deployments" : [
    {
        "unlocked" : "none",
        "requested-local-packages" : [],
        "base-commit-meta" : {"removed": "because this output is massive and not used"},
        "base-removals" : [],
        "pinned" : false,
        "osname" : "default",
        "base-remote-replacements" : {      },
        "regenerate-initramfs" : false,
        "checksum" : "89f5072a5cf709b5d8afe457aa4de4e50520d5e99cee2ba1a9494971936a8e42",
        "container-image-reference-digest" : "sha256:c61f3499be1fa03c2351332907cfde9500a2baaf77e714da3c168a49d33e8a08",
        "requested-base-local-replacements" : [],
        "id" : "default-89f5072a5cf709b5d8afe457aa4de4e50520d5e99cee2ba1a9494971936a8e42.0",
        "version" : "45.20261125",
        "requested-local-fileoverride-packages" : [],
        "requested-base-removals" : [],
        "requested-packages" : [
            $stagedpackages
        ],
        "serial" : 0,
        "timestamp" : 1795622223,
        "staged" : true,
        "booted" : false,
        "container-image-reference" : "ostree-image-signed:docker://ghcr.io/ublue-os/bazzite-dx:stable",
        "packages" : [],
        "base-local-replacements" : []
    },
    {
        "unlocked" : "none",
        "requested-local-packages" : [],
        "base-commit-meta" : {"removed": "because this output is massive and not used"},
        "base-removals" : [],
        "pinned" : false,
        "osname" : "default",
        "base-remote-replacements" : {      },
        "regenerate-initramfs" : false,
        "checksum" : "12168b96695e64ea944f375f26b0a30f8dae94935815fe6d149f8a1df8161375",
        "container-image-reference-digest" : "sha256:ea250d03962fdbbfb8f86584e27edec856f282a059ff538221e83fc6dec4713f",
        "requested-base-local-replacements" : [],
        "id" : "default-12168b96695e64ea944f375f26b0a30f8dae94935815fe6d149f8a1df8161375.0",
        "version" : "45.20261123",
        "requested-local-fileoverride-packages" : [],
        "requested-base-removals" : [],
        "requested-packages" : [
            $activepackages
        ],
        "serial" : 0,
        "timestamp" : 1795409792,
        "staged" : false,
        "booted" : true,
        "container-image-reference" : "ostree-image-signed:docker://ghcr.io/ublue-os/bazzite-dx:stable",
        "packages" : [],
        "base-local-replacements" : []
    }
    ],
    "transaction" : null,
    "cached-update" : null,
    "update-driver" : null
}
                """)

            print(
                template.substitute(
                    activepackages=format_packages(state["active"]),
                    stagedpackages=format_packages(state["staged"]),
                )
            )
        else:
            print("""
State: idle
Deployments:
● ostree-image-signed:docker://ghcr.io/ublue-os/bazzite-dx:stable
                    Digest: sha256:c61f3499be1fa03c2351332907cfde9500a2baaf77e714da3c168a49d33e8a08
                    Version: 45.20261125 (2026-11-25T15:57:03Z)

    ostree-image-signed:docker://ghcr.io/ublue-os/bazzite-dx:stable
                    Digest: sha256:ea250d03962fdbbfb8f86584e27edec856f282a059ff538221e83fc6dec4713f
                    Version: 45.20261123 (2026-11-23T04:56:32Z)
                """)


if __name__ == "__main__":
    main()
