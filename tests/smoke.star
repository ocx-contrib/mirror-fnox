# Stable smoke test — assert on the contract (exit code, version shape,
# subcommand presence), never on help/version prose. fnox reworks its
# tagline freely; the digits and the subcommand surface are the contract.
FNOX = "fnox.exe" if ocx.target_platform.os == ocx.os.Windows else "fnox"

# Tier 1 + 2: liveness + version SHAPE.
r_version = ocx.run(FNOX, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# Tier 3: prove the secret-management surface EXISTS via subcommand
# presence (exit-0 of `<sub> --help`), not by grepping a description string.
# Replaces the brittle `--help .contains "secret management"` check.
expect.eq(ocx.run(FNOX, "get", "--help").exit_code, 0)
expect.eq(ocx.run(FNOX, "exec", "--help").exit_code, 0)
expect.eq(ocx.run(FNOX, "set", "--help").exit_code, 0)
