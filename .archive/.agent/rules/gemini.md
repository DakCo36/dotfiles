# Project Instruction Files

Before making any changes, scan the directory tree from the repo root down to the
directory of the file being edited for `AGENTS.md` and `GEMINI.md` files.
Read all matching files and apply their rules.

## Priority

When rules conflict, the file **closest to the file being edited** takes precedence.

Example: editing `devkit/lib/components/cli/bat.rb`

1. `devkit/lib/components/cli/AGENTS.md`, `devkit/lib/components/cli/GEMINI.md` (highest priority)
2. `devkit/lib/components/AGENTS.md`, `devkit/lib/components/GEMINI.md`
3. `devkit/lib/AGENTS.md`, `devkit/lib/GEMINI.md`
4. `devkit/AGENTS.md`, `devkit/GEMINI.md`
5. `AGENTS.md`, `GEMINI.md` (lowest priority)

`AGENTS.md` and `GEMINI.md` at the same level: if `GEMINI.md` exists, ignore `AGENTS.md`.
