## Verification in the cloud sandbox

This is a Linux environment. iOS builds, Fastlane, the iPhone 15 simulator,
and integration tests under `integration_test/` cannot run here.

Use the project's `just` recipes for verification:

1. `just generate` — runs `build_runner` (only needed if you changed drift
   schemas, anything annotated for code generation, or pulled new deps)
2. `just lint` — runs all pre-commit hooks across the repo
3. `just test` — runs unit tests in `test/`

**Do not run `just all`** in this environment. It chains `test-integration`,
which requires the iPhone 15 simulator and will fail. Run the three recipes
above individually instead.

**Do not run `just test-integration` or `just run`.** Both require a
device/simulator that doesn't exist in the sandbox.

If `flutter` or `just` is not on PATH, source `~/.bashrc` or use the absolute
paths: `$HOME/flutter/bin/flutter`, `$HOME/.local/bin/just`.
