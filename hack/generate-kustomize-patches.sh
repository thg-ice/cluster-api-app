#!/usr/bin/env bash

# This script will generate kustomize patches for webhooks by first getting the
# MutatingWebhookConfiguration and ValidatingWebhookConfiguration, so it
# generates patches only or those webhooks that are specified in upstream.
#
# This way we don't have to specify webhook patches manually, since those
# change from time to time, as CRDs are added, modified and removed.

set -o errexit
set -o nounset
set -o pipefail

# Directories
ROOT_DIR="./$(dirname "$0")/.."
ROOT_DIR="$(realpath "$ROOT_DIR")"
KUSTOMIZE_DIR="$ROOT_DIR/config/helm"
HELM_DIR="$ROOT_DIR/helm/cluster-api"
KUSTOMIZE_INPUT_DIR="$ROOT_DIR/config/helm/input"

# Download upstream manifests
helm_values="$HELM_DIR/values.yaml"
org="kubernetes-sigs"
repo="cluster-api"
version="$(yq e '.images.tag' "$helm_values")"
url="https://github.com/$org/$repo/releases/download/$version/cluster-api-components.yaml"
mkdir -p "$KUSTOMIZE_INPUT_DIR"
curl -L "$url" -o "$KUSTOMIZE_INPUT_DIR/cluster-api-components.yaml"

# Update kustomize patches for webhooks. We do this for every CRD

# First clear previous watchfilter patches
true > "$KUSTOMIZE_DIR/webhook-watchfilter.yaml"

# For every CRD, add webhook label selector
for webhook_cr_name in $(yq e -N 'select(.kind=="MutatingWebhookConfiguration" or .kind=="ValidatingWebhookConfiguration") | .metadata.name' "$KUSTOMIZE_INPUT_DIR/cluster-api-components.yaml"); do
    webhook="$(
        webhook_cr_name="$webhook_cr_name" \
        yq e 'select((.kind=="MutatingWebhookConfiguration" or .kind=="ValidatingWebhookConfiguration") and .metadata.name==env(webhook_cr_name))' \
            "$KUSTOMIZE_INPUT_DIR/cluster-api-components.yaml"
    )"

    webhook_api_version="$(echo "$webhook" | yq e ".apiVersion" -)"
    webhook_kind="$(echo "$webhook" | yq e ".kind" -)"

    webhook_patch="---
apiVersion: $webhook_api_version
kind: $webhook_kind
metadata:
  name: $webhook_cr_name
webhooks: null
"

    echo "Generating watch-filter patches for $webhook_kind $webhook_cr_name"
    # Get all CRDs for this provider
    for webhook_name in $(webhook_cr_name="$webhook_cr_name" yq e 'select((.kind=="MutatingWebhookConfiguration" or .kind=="ValidatingWebhookConfiguration") and .metadata.name==env(webhook_cr_name)) | .webhooks[].name' "$KUSTOMIZE_INPUT_DIR/cluster-api-components.yaml"); do
        object_selector_patch="$(
            webhook_name="$webhook_name" \
            yq e --null-input \
                '.name = env(webhook_name) |
                .objectSelector.matchLabels["cluster.x-k8s.io/watch-filter"] = "{{ .Values.watchFilter }}"'
            )"

        webhook_patch="$(
            echo "$webhook_patch" | \
                object_selector_patch="$object_selector_patch" \
                yq e '.webhooks += [env(object_selector_patch)]' -
        )"
    done

    # Write webhook patch to file
    echo "$webhook_patch" >> "$KUSTOMIZE_DIR"/webhook-watchfilter.yaml
done
