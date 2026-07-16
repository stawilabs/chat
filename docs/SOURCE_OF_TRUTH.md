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
