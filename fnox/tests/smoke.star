# fnox/tests/smoke.star — stable across upstream releases.
# Assert on the contract (exit code, version shape, computed result), never on
# help/version prose. fnox reworks its tagline and its command descriptions
# freely; the digits and the secret it stores and hands back are the contract.
FNOX = "fnox.exe" if ocx.target_platform.os == ocx.os.Windows else "fnox"

# fnox is a *stateful* CLI: it reads a global config, keeps a per-user daemon
# and caches under the home directory, and searches parent directories for
# `fnox.toml`. Point every home-ish variable at the scratch root so the run
# cannot read, write, or be perturbed by anything the host already has, and
# turn off both the daemon and the interactive prompts.
#
# `PATH` is deliberately absent — it is a reserved key `ocx.run` refuses to
# override, which is what keeps the bundle's own PATH (the thing under test)
# intact.
HOME = ocx.scratch_root
ENV = {
    "HOME": HOME,                             # Unix
    "USERPROFILE": HOME,                      # Windows
    "APPDATA": HOME + "/AppData/Roaming",     # Windows roaming
    "LOCALAPPDATA": HOME + "/AppData/Local",  # Windows local
    "XDG_CONFIG_HOME": HOME + "/.config",
    "XDG_DATA_HOME": HOME + "/.local/share",
    "XDG_STATE_HOME": HOME + "/.local/state",
    "XDG_CACHE_HOME": HOME + "/.cache",
    "FNOX_NON_INTERACTIVE": "true",
    "NO_COLOR": "1",
}

# Tier 1 + 2: liveness + version SHAPE (fnox prints its version to stdout).
r_version = ocx.run(FNOX, "--version", env = ENV)
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# Tier 3: the round trip — fnox's entire reason to exist. Everything below runs
# with the scratch root as cwd (ocx.run's default), so `fnox.toml` is created,
# read, and mutated inside the sandbox. Hermetic: the `plain` provider needs no
# key material, no OS keychain, and no network.
TOKEN = "ocx-smoke-a1b2c3"

# 3a: config bootstrap.
expect.ok(ocx.run(FNOX, "init", "--skip-wizard", env = ENV))
expect.true(ocx.exists("fnox.toml"), msg = "init must create fnox.toml in cwd")

# 3b: provider registry — proves the provider table is written and parsed back,
# not merely that a flag was accepted.
expect.ok(ocx.run(FNOX, "provider", "add", "local", "plain", env = ENV))
expect.contains(ocx.read_file("fnox.toml"), "plain")

# 3c: write, then read back the EXACT token. This is the check that fails if
# the secret store, the TOML round trip, or profile resolution regresses —
# anchored so a substring of some longer value cannot satisfy it.
expect.ok(ocx.run(FNOX, "--no-daemon", "set", "MY_TOKEN", TOKEN, env = ENV))
r_get = ocx.run(FNOX, "--no-daemon", "get", "MY_TOKEN", env = ENV)
expect.ok(r_get)
expect.matches(r_get.stdout, r"^ocx-smoke-a1b2c3\s*$")

# 3d: a second read path over the same store. `export` renders the whole
# resolved secret set rather than one lookup, so it exercises the collection
# path that `fnox exec` and the shell hook are built on.
r_export = ocx.run(FNOX, "--no-daemon", "export", env = ENV)
expect.ok(r_export)
expect.contains(r_export.stdout, "MY_TOKEN=" + TOKEN)

# Tier 4: fnox is a self-contained CLI — PATH only (proven by Tier 1). Its
# other env vars (FNOX_PROFILE, FNOX_NON_INTERACTIVE) are user knobs, not
# bundle interface, so there is no non-PATH variable to wire and no Tier 4
# check.
