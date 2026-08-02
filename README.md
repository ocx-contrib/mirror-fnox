# mirror-jdx

OCX mirror for [fnox](https://github.com/jdx/fnox). One repository, one spec
directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [fnox](https://github.com/jdx/fnox) | [`fnox/mirror.yml`](fnox/mirror.yml) | `ghcr.io/ocx-contrib/jdx/fnox` | `ocx.sh/jdx/fnox` | `MIT` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

> This repository previously published the same upstream to the flat coordinate
> `ocx.sh/fnox`. `jdx/fnox` is the grouped successor. The repo is named for the
> upstream owner, so a second tool by [@jdx](https://github.com/jdx) lands here
> as a sibling spec directory rather than a new repository.

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
fnox/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. Restate a block in full or
not at all.

## Platforms

`fnox` publishes six platform entries: both Linux arches, both macOS arches and
both Windows arches. On Linux the mirror carries the `-unknown-linux-musl`
assets, measured **fully static** on v1.32.0 — no `PT_INTERP`, no `DT_NEEDED`.
`os.features` states what an artifact requires *of the host*, so both Linux keys
are **bare**: tagging them `+libc.musl` would be a false requirement that hid
them from every glibc host. The `alpine:3.20` container leg in `mirror-base.yml`
is what turns that claim into evidence; the measurement itself is recorded above
the `assets:` block in `fnox/mirror.yml`.

The `-unknown-linux-gnu` twin is **not** mirrored. It needs `libudev.so.1` and
`libgcc_s.so.1` beyond base glibc, and `os.features` can only express a libc
*family* — a `+libc.glibc` key could never state the libudev requirement, so a
glibc host would satisfy the declared claim while the binary still failed to
start.

> **Linux capability delta.** Upstream excludes `ctap-hid-fido2` from musl
> builds (`hidapi` → `libudev` cannot be statically linked), so the musl binary
> offers **23** provider types where the gnu binary offers 24 — the missing one
> is `fido2: FIDO2 hmac-secret hardware-backed encryption`. The `yubikey`
> HMAC-SHA1 provider is present in both, and macOS/Windows are unaffected. On
> Linux, an OCX-installed `fnox` cannot use the `fido2` provider.

Upstream release `v1.27.0` carries **zero assets** (an aborted release, not a
draft and not a prerelease). Every asset pattern matches nothing there, so the
version is skipped — the correct outcome, since there is nothing to mirror.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `fnox/mirror.yml` | hand | yes — see below |
| `fnox/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `fnox/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec fnox/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## The binaries claim

fnox's archives carry the executable at the **root** — `strip_components: 0`,
no `bin/` directory — so the bundle's only PATH entry is a bare
`${installPath}`. `bin_scan` only looks *below* an `${installPath}/<dir>` entry,
so it has nothing to walk here. `mirror-base.yml` therefore sets `bin_scan: off`
and `fnox/metadata.json` hand-lists `binaries: ["fnox"]` — the blessed shape for
this layout.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; each
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
