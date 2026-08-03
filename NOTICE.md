# NOTICE

This repository packages and redistributes upstream software published by
[@jdx](https://github.com/jdx). The Apache-2.0 license in [`LICENSE`](LICENSE)
covers the OCX pipeline files authored here. It does **not** cover any
upstream-derived asset — each package's redistributed bytes carry their own
license, recorded below.

Each package's logo is reproduced for catalog identification only, under
nominative fair use. The marks remain the property of their respective owners
and no endorsement is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `fnox` | `ghcr.io/ocx-contrib/jdx/fnox` | `MIT` |
| `mise` | `ghcr.io/ocx-contrib/jdx/mise` | `MIT` |

---

## `fnox`

Upstream: <https://github.com/jdx/fnox>
Published to `ghcr.io/ocx-contrib/jdx/fnox`.

| Component | SPDX | Holder |
|---|---|---|
| fnox (`fnox`) | **MIT** | Copyright (c) Jeff Dickey / @jdx |

Permissive; redistribution of the compiled binary is granted provided the
copyright notice and permission notice are retained. Upstream ships archives
containing the bare executable with no bundled `LICENSE` file, so the notice is
reproduced above and the terms are those of
<https://github.com/jdx/fnox/blob/main/LICENSE>. The published binaries
statically link third-party Rust crates under permissive licenses, enumerated in
upstream's `Cargo.toml` / `Cargo.lock`.

The fnox name is used for catalog identification under nominative fair use.

---

## `mise`

Upstream: <https://github.com/jdx/mise>
Published to `ghcr.io/ocx-contrib/jdx/mise`.

| Component | SPDX | Holder |
|---|---|---|
| mise (`mise`) | **MIT** | Copyright (c) Jeff Dickey / @jdx |

Permissive; redistribution of the compiled binary is granted provided the
copyright notice and permission notice are retained. Upstream publishes the
Linux/macOS/Windows builds as bare executables with no accompanying `LICENSE`
file, so the notice is reproduced above and the terms are those of
<https://github.com/jdx/mise/blob/main/LICENSE>. The published binaries
statically link third-party Rust crates under permissive licenses, enumerated in
upstream's `Cargo.toml` / `Cargo.lock`.

`mise/logo.svg` reproduces upstream's `docs/public/logo.svg` mark unmodified;
the only addition is a light background plate, because the upstream artwork is
black line art with no declared fill and is invisible on the dark surfaces
catalog thumbnails land on. The mise name and mark are used for catalog
identification under nominative fair use.

---

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
