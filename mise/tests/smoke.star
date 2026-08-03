# mise/tests/smoke.star — stable across upstream mise releases.
# Asserts the contract (exit code, version shape, the embedded tool registry,
# config parsing, env composition, task execution), never help/version prose.
#
# HERMETIC BY CONSTRUCTION. mise's headline job is installing toolchains over
# the network; nothing below does that. Every assertion here runs against a
# `mise.toml` this script writes into the scratch root, so the test is offline,
# deterministic, and identical on a container leg with no egress.
# See ocx.mirror testing-practices.md.

MISE = "mise.exe" if ocx.target_platform.os == ocx.os.Windows else "mise"

# Tier 1 + 2: liveness on the composed PATH + version SHAPE. mise is CalVer
# (`2026.8.1 linux-x64 (2026-08-03)`), which still has the three-number shape —
# the digits are the contract, the platform token and the date are not.
r_version = ocx.run(MISE, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# Tier 3a: the tool registry is COMPILED INTO the binary — ~1000 short names
# mapped to backends. It is mise's analogue of bat's embedded syntax set, and
# it is what would red against a truncated or wrong-flavour artifact that still
# happened to exec. Assert the COUNT, not exit 0: `registry` exits 0 while
# printing nothing, so an empty registry would sail past a bare expect.ok.
r_registry = ocx.run(MISE, "registry")
expect.ok(r_registry)
expect.true(
    len(r_registry.stdout.split("\n")) > 500,
    msg = "embedded tool registry looks empty or truncated",
)

# The same registry queried for one short name. The assertion is on the SHAPE
# of the mapping — `<backend>:<tool>` — not on which backend serves `node`
# today: upstream moves tools between `core:`, `aqua:` and `ubi:` between
# releases, and pinning `core:node` would make an upstream reclassification
# look like a broken mirror. That a lookup RESOLVES AT ALL is the contract.
r_lookup = ocx.run(MISE, "registry", "node")
expect.ok(r_lookup)
expect.matches(r_lookup.stdout, r"^[a-z0-9]+:\S*node")

# Tier 3b: config parsing + env composition. mise refuses to read a config it
# has not been told to trust ("Config files in … are not trusted"), so `trust`
# is a real gate, not a formality — asserting it succeeds is itself a contract
# check on the trust store.
ocx.write_file(
    "mise.toml",
    "[env]\n" +
    "OCX_SMOKE_ENV = \"ocx-smoke-42\"\n" +
    "\n" +
    "[tasks.ocx-smoke]\n" +
    "run = \"echo ocx-task-ran-42\"\n",
)

r_trust = ocx.run(MISE, "trust", "--yes")
expect.ok(r_trust)

# `--json` is pinned explicitly. The DEFAULT output of `mise env` is
# shell-specific (`export X=Y` under bash, `$env:X = 'Y'` under pwsh) and is
# therefore neither stable across platforms nor a contract — never assert a
# CLI's default format. The regex tolerates JSON whitespace changes.
r_env = ocx.run(MISE, "env", "--json")
expect.ok(r_env)
expect.matches(r_env.stdout, r"\"OCX_SMOKE_ENV\":\s*\"ocx-smoke-42\"")

# Tier 3c: the task runner, end to end — config → task lookup → subprocess.
# `tasks ls` first, because `run` alone cannot distinguish "task found and ran"
# from "task missing". stdout carries only the task's own output; mise's
# `[ocx-smoke] $ echo …` echo goes to stderr, so this is a clean read.
r_tasks = ocx.run(MISE, "tasks", "ls")
expect.ok(r_tasks)
expect.contains(r_tasks.stdout, "ocx-smoke")

r_run = ocx.run(MISE, "run", "ocx-smoke")
expect.ok(r_run)
expect.contains(r_run.stdout, "ocx-task-ran-42")

# No Tier 4: metadata.json declares PATH only, proven by the Tier 1 liveness
# call above.
