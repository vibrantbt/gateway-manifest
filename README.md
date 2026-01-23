# gateway-manifest
This repo contains the gateway container image manifest(s) used by the gateway update process.

## Files
- `dev/images.env` — dev channel manifest (mutable)
- `prod/images.env` — prod channel manifest (mutable)

These files are intentionally kept in `KEY=VALUE` env-file format so they can be consumed directly by the gateway update tooling.

## Tagging scheme
Gateway images should be referenced with an immutable tag:
- `YYYY.MM.DD-<shortsha>` (UTC date + Git commit SHA prefix)

Example:
- `harbor-dev.vibrantbt.net/gateway/gatewayos:2026.01.23-1a2b3c4d`

Avoid using `:latest` in gateway deployments.

## Updating
Use `update.sh` to update one or more keys in the dev/prod manifest:

```bash
./update.sh --env dev \
  --set VBT_GATEWAYOS_IMAGE=harbor-dev.vibrantbt.net/gateway/gatewayos:2026.01.23-1a2b3c4d
```
