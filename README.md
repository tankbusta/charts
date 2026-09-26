# Public Helm Charts

Random Helm Charts for my Homelab. May be useful for others.

## Usage

```sh
helm repo add tankbusta https://tankbusta.github.io/charts
helm repo update
helm search repo tankbusta
```

| Chart | Description |
|-------|-------------|
| [ghidra-authpanel](charts/ghidra-authpanel) | Self-service account and repository access panel for Ghidra servers |
| [ghidra-server](charts/ghidra-server) | Ghidra shared project server, with optional ghidra-panel JAAS authentication |

## Releasing

Charts are released by [chart-releaser](https://github.com/helm/chart-releaser-action) on every push to `main`
that touches `charts/`. Bump `version` in the chart's `Chart.yaml` to publish a new release; versions that
already have a GitHub release are skipped. Pull requests are linted with [chart-testing](https://github.com/helm/chart-testing),
which also requires a version bump for any changed chart.
