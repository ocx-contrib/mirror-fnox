# mirror-jdx

OCX mirrors for [@jdx](https://github.com/jdx) tooling. One repository, one spec
directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [fnox](https://github.com/jdx/fnox) | [`fnox/mirror.yml`](fnox/mirror.yml) | `ghcr.io/ocx-contrib/jdx/fnox` | `ocx.sh/jdx/fnox` | `MIT` |
| [mise](https://github.com/jdx/mise) | [`mise/mirror.yml`](mise/mirror.yml) | `ghcr.io/ocx-contrib/jdx/mise` | `ocx.sh/jdx/mise` | `MIT` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

> This repository previously published `fnox` to the flat coordinate
> `ocx.sh/fnox`. `jdx/fnox` is the grouped successor. The repo is named for the
> upstream owner, which is why `mise` landed here as a sibling spec directory
> rather than a new repository.

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
fnox/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
mise/                   same shape
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

`mise` reaches the same conclusion from its own measurement, so it inherits the
same matrix: the `-musl` builds are static on both arches (x86-64 `static-pie`,
aarch64 `statically linked`; zero `PT_INTERP`, zero `DT_NEEDED` on v2026.8.1),
so both Linux keys are bare. Its gnu twins are dynamically linked against base
glibc only — a `+libc.glibc` key *would* be honest here, unlike fnox's — but the
two builds are functionally identical (same subcommands, same `backends ls`), so
a second key would double the artifacts to recover nothing reachable.

mise ships `-linux-armv7` assets that this mirror does not carry: ocx's platform
grammar has no 32-bit ARM at all (`Architecture` enumerates exactly `Amd64` and
`Arm64`). It also ships each Linux/macOS build in **four** forms — a bare
binary plus `.tar.gz`, `.tar.xz` and `.tar.zst` — where Windows ships only
`.exe` and `.zip`. The mirror carries the **raw** form, the only one present on
all three OSes, and every asset pattern is end-anchored so `…-linux-x64$` picks
neither the `.tar.*` siblings nor `…-linux-x64-musl`. A prefix pattern would
match four assets and fail the version on ambiguity.

mise is CalVer (`vYYYY.M.patch`) with an **unpadded month** — `v2026.7.0`, never
`v2026.07.0` — and releases near-daily, so `versions.min` tracks the current
month series rather than backfilling.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `fnox/mirror.yml`, `mise/mirror.yml` | hand | yes — see below |
| `<pkg>/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `<pkg>/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec fnox/mirror.yml --spec mise/mirror.yml
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

`mise` lands in the same place from the other direction: it has no archive at
all (`asset_type: {type: binary, name: mise}`), so the renamed binary *is* the
bundle root. Hand-listing is load-bearing there rather than merely accurate —
GitHub serves the raw asset with no executable bit, and `prepare` chmods only
the **declared** `binaries` to 0755.

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
