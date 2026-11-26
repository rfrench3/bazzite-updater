#!/usr/bin/python3

import argparse
import sys
from time import sleep


def main():
    parser = argparse.ArgumentParser(
        description="Run specific actions based on arguments."
    )

    subparsers = parser.add_subparsers(dest="mode", required=True)

    subparsers.add_parser("update")

    status_parser = subparsers.add_parser("status")
    status_parser.add_argument(
        "--json",
        action="store_true",
    )

    args = parser.parse_args()

    sleep(0.3)

    if args.mode == "update":
        print("not implemented")
        return sys.exit(1)
    elif args.mode == "status":
        if args.json:
            print(
                """{"apiVersion":"org.containers.bootc/v1","kind":"BootcHost","metadata":{"name":"host"},"spec":{"bootOrder":"default","image":{"image":"ghcr.io/ublue-os/bazzite-dx:stable","signature":"containerPolicy","transport":"registry"}},"status":{"booted":{"cachedUpdate":null,"composefs":null,"downloadOnly":false,"image":{"architecture":"amd64","image":{"image":"ghcr.io/ublue-os/bazzite-dx:stable","signature":"containerPolicy","transport":"registry"},"imageDigest":"sha256:c61f3499be1fa03c2351332907cfde9500a2baaf77e714da3c168a49d33e8a08","timestamp":"2026-11-25T15:40:42Z","version":"45.20261125"},"incompatible":false,"ostree":{"checksum":"89f5072a5cf709b5d8afe457aa4de4e50520d5e99cee2ba1a9494971936a8e42","deploySerial":0,"stateroot":"default"},"pinned":false,"softRebootCapable":true,"store":"ostreeContainer"},"readOnly":false,"rollback":{"cachedUpdate":{"architecture":"amd64","image":{"image":"ghcr.io/ublue-os/bazzite-dx:stable","signature":"containerPolicy","transport":"registry"},"imageDigest":"sha256:c61f3499be1fa03c2351332907cfde9500a2baaf77e714da3c168a49d33e8a08","timestamp":"2026-11-25T15:40:42Z","version":"45.20261125"},"composefs":null,"downloadOnly":false,"image":{"architecture":"amd64","image":{"image":"ghcr.io/ublue-os/bazzite-dx:stable","signature":"containerPolicy","transport":"registry"},"imageDigest":"sha256:ea250d03962fdbbfb8f86584e27edec856f282a059ff538221e83fc6dec4713f","timestamp":"2026-11-23T04:43:58Z","version":"45.20261123"},"incompatible":false,"ostree":{"checksum":"12168b96695e64ea944f375f26b0a30f8dae94935815fe6d149f8a1df8161375","deploySerial":0,"stateroot":"default"},"pinned":false,"softRebootCapable":false,"store":"ostreeContainer"},"rollbackQueued":false,"staged":null,"type":"bootcHost","usrOverlay":null}}""",
                end="",
            )
        else:
            print("""apiVersion: org.containers.bootc/v1
kind: BootcHost
metadata:
    name: host
spec:
    image:
    image: ghcr.io/ublue-os/bazzite-dx:stable
    transport: registry
    signature: containerPolicy
    bootOrder: default
status:
    staged: null
    booted:
    image:
        image:
        image: ghcr.io/ublue-os/bazzite-dx:stable
        transport: registry
        signature: containerPolicy
        version: '45.20261125'
        timestamp: 2026-11-25T15:40:42Z
        imageDigest: sha256:c61f3499be1fa03c2351332907cfde9500a2baaf77e714da3c168a49d33e8a08
        architecture: amd64
    cachedUpdate: null
    incompatible: false
    pinned: false
    softRebootCapable: true
    downloadOnly: false
    store: ostreeContainer
    ostree:
        stateroot: default
        checksum: 89f5072a5cf709b5d8afe457aa4de4e50520d5e99cee2ba1a9494971936a8e42
        deploySerial: 0
    composefs: null
    rollback:
    image:
        image:
        image: ghcr.io/ublue-os/bazzite-dx:stable
        transport: registry
        signature: containerPolicy
        version: '45.20261123'
        timestamp: 2026-11-23T04:43:58Z
        imageDigest: sha256:ea250d03962fdbbfb8f86584e27edec856f282a059ff538221e83fc6dec4713f
        architecture: amd64
    cachedUpdate:
        image:
        image: ghcr.io/ublue-os/bazzite-dx:stable
        transport: registry
        signature: containerPolicy
        version: '45.20261125'
        timestamp: 2026-11-25T15:40:42Z
        imageDigest: sha256:c61f3499be1fa03c2351332907cfde9500a2baaf77e714da3c168a49d33e8a08
        architecture: amd64
    incompatible: false
    pinned: false
    softRebootCapable: false
    downloadOnly: false
    store: ostreeContainer
    ostree:
        stateroot: default
        checksum: 12168b96695e64ea944f375f26b0a30f8dae94935815fe6d149f8a1df8161375
        deploySerial: 0
    composefs: null
    rollbackQueued: false
    type: bootcHost
    usrOverlay: null
    readOnly: false""")


if __name__ == "__main__":
    main()
