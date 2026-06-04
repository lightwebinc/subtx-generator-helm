# subtx-generator Helm chart

Helm chart for [subtx-generator](https://github.com/lightwebinc/subtx-generator) — the BSV multicast load and control-frame tooling.

This repository packages templates, default values, JSON Schema validation, and CI workflows for the generator. The application source lives in [`subtx-generator`](https://github.com/lightwebinc/subtx-generator).

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
helm install gen oci://ghcr.io/lightwebinc/charts/subtx-generator \
  --version 0.1.0 -n bsv-mcast \
  --set mode=subtx-gen \
  --set args.addr=[fd20::20]:9000 \
  --set subtxGen.pps=1000 --set subtxGen.duration=0s

# Finite load test (Job) — send 10 anchor frames then exit
helm install anchor-test . -n bsv-mcast \
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
- `subtxGen` — full `subtx-gen` surface (frame version, payload format, gap injection, BRC-127 announce, txid corruption, direct-multicast SSM mode)
- `sendAnchorFrame` — BRC-134 sender
- `sendBlockAnnounce` — BRC-131 sender
- `sendSubtreeData` — BRC-132 sender
- `logFormat` (`text`|`json`, schema-validated) → `LOG_FORMAT`: the generator now logs through `shard-common/logging`; set `json` to match the rest of the fleet. See the [Unified Logging Plan](https://github.com/lightwebinc/shard-common/blob/main/docs/logging.md).

### direct-multicast mode (subtxGen)

`subtxGen.mode` defaults to `unicast` (forward to proxy via `args.addr`).
Set `subtxGen.mode=direct-multicast` plus `subtxGen.bindSource`,
`subtxGen.egressIface`, `subtxGen.sourceMode`, `subtxGen.scope`, and
`subtxGen.egressPort` to bypass the proxy and emit `(S=bindSource, G)`
directly. The generator stamps SeqNum per-flow and HashKey =
XXH64(bindSource ∥ groupIdx ∥ subtreeID) so SSM listeners see
deterministic flows without a proxy in the loop. Operators MUST add
`bindSource` to the shard-manifest `publishers` list so receivers'
`(S,G)` joins include this generator. See the
[SSM Support Plan](https://github.com/lightwebinc/bsv-multicast/blob/main/docs/SourceSpecificMulticast/ssm-support-plan.md).

## Release

Gated `release.yml` — `workflow_dispatch` with `confirm: RELEASE` and `production` Environment review.

## License

Apache-2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
