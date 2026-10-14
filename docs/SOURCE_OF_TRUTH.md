# Source of truth

Chat backend and gateway images are built and published from **https://github.com/stawilabs/chat**.

| Component | Image |
|-----------|--------|
| Drone (default service) | `ghcr.io/stawilabs/chat` |
| Gateway | `ghcr.io/stawilabs/chat-gateway` |

## Version tags

| Tag pattern | Meaning | Workflow |
|-------------|---------|----------|
| `v1.*.*` | Backend service docker release | `.github/workflows/release.yaml` |
| `v0.*.*` | Flutter mobile app production | `.github/workflows/production.yml` |

Do **not** publish backend images from `antinvestor/service-chat`. That repository is legacy; its buf module path no longer resolves and production Flux tracks the stawi images above.

## Go / Buf modules

| Module | Owner |
|--------|--------|
| `github.com/stawilabs/chat` | This repo |
| `buf.build/stawi/chat` | This repo (chat protos) |
| `buf.build/antinvestor/common` | Platform shared protos (still under antinvestor BSR) |
| `buf.build/antinvestor/{device,profile,notification}` | Platform service protos (still under antinvestor BSR) |
| `github.com/antinvestor/common/v3` | Platform shared Go library |
| `github.com/pitabwire/frame/v3` | Framework |
| `connectrpc.com/connect/v2` | Connect RPC; generated clients and handlers come from the `…/connectrpc/go/v2` BSR modules |

There is **no** `buf.build/stawi/{common,device,profile,notification}` yet. Client packages for those APIs stay on `buf.build/gen/go/antinvestor/...` until the owning services migrate their BSR modules.
