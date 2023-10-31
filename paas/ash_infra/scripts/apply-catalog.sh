#!/bin/bash
set -x

MANIFEST_DIR=$(find /quay/oc-mirror -type d | grep "results-")
set -- $MANIFEST_DIR
oc apply -f $(echo $1)
