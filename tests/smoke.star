# Branch on the typed constant; ocx.platform() was removed.
FNOX = "fnox.exe" if ocx.target_platform.os == ocx.os.Windows else "fnox"

r_version = ocx.run(FNOX, "--version")
expect.ok(r_version)
expect.eq(r_version.exit_code, 0)
expect.contains(r_version.stdout, "fnox")

r_help = ocx.run(FNOX, "--help")
expect.eq(r_help.exit_code, 0)
expect.contains(r_help.stdout, "secret management")
