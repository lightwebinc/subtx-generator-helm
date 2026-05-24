# bitcoin-subtx-generator Helm chart

Helm chart for [bitcoin-subtx-generator](https://github.com/lightwebinc/bitcoin-subtx-generator) — the BSV multicast load and control-frame tooling.

This repository packages templates, default values, JSON Schema validation, and CI workflows for the generator. The application source lives in [`bitcoin-subtx-generator`](https://github.com/lightwebinc/bitcoin-subtx-generator).

## Modes

The chart packages a single multi-binary image and selects the binary via `.Values.mode`:

| mode | Binary | Purpose |
|---|---|---|
| `subtx-gen` (default) | `/subtx-gen` | BRC-124/BRC-128 traffic generator |
| `send-anchor-frame` | `/send-anchor-frame` | BRC-134 anchor tx sender |
| `send-block-announce` | `/send-block-announce` | BRC-131 block + coinbase announcements (TCP) |
| `send-subtree-data` | `/send-subtree-data` | BRC-132 subtree data sender (TCP) |

The binaries accept **CLI flags only** (no environment variables). The chart translates the matching `*Args` block from `values.yaml` into the container's `command` and `args`. Zero / empty values are omitted so the binary defaults apply.

## Install

```bash
# Continuous traffic generator (Deployment) — emits 1000 pps until killed
helm install gen oci://ghcr.io/lightwebinc/charts/bitcoin-subtx-generator \
  --version 0.1.0 -n bitcoin-mcast \
  --set mode=subtx-gen \
  --set args.addr=[fd20::20]:9000 \
  --set subtxGen.pps=1000 --set subtxGen.duration=0s

# Finite load test (Job) — send 10 anchor frames then exit
helm install anchor-test . -n bitcoin-mcast \
  --set mode=send-anchor-frame \
  --set workloadType=Job \
  --set args.addr=[fd20::20]:9000 \
  --set sendAnchorFrame.count=10
```

## Workload type

| `workloadType` | Use case |
|---|---|
| `Deployment` (default) | Long-running generators (`subtx-gen` with `duration=0`). |
| `Job` | Finite runs; pod terminates on completion. |

## Networking

The generator is a pure UDP/TCP client toward the proxy — no MLD join, no multicast receive. Default `networking.mode: pod` is appropriate for any CNI. `host` and `multus` are available for operators that need a specific source NIC.

## Values reference

See [`values.yaml`](values.yaml). Every flag of every binary is exposed under per-mode blocks:

- `args` — shared flags (`addr`)
- `subtxGen` — full `subtx-gen` surface (frame version, payload format, gap injection, BRC-127 announce, txid corruption)
- `sendAnchorFrame` — BRC-134 sender
- `sendBlockAnnounce` — BRC-131 sender
- `sendSubtreeData` — BRC-132 sender

## Release

Gated `release.yml` — `workflow_dispatch` with `confirm: RELEASE` and `production` Environment review.

## License

Apache-2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
