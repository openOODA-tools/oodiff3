# oodiff3: Sovereign 3-Way File Reconciliation & Conflict Merger

<div align="center">

```
================================================================================
                                oodiff3
            Sovereign openOODA 3-Way File Reconciliation Engine
================================================================================
```

**Sovereign 3-Way File Comparison & Merge Engine**  
*Reconciling conflicts between common ancestor baseline and divergent branches.*  
*Two Faces, One Engine:* Modern terminal ergonomics for humans • Zero-leakage MCP for AI agents  
Written in 100% pure [openOODA](https://github.com/openOODA).

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![openOODA](https://img.shields.io/badge/openOODA-1.0-emerald.svg)](https://openooda.org)
[![Architecture: x86_64 | aarch64](https://img.shields.io/badge/Arch-x86__64%20%7C%20aarch64-lightgrey.svg)]()

</div>

---

## 1. Quick Install

### Automated Installer (Linux x86_64 & aarch64)
```bash
curl -fsSL https://tools.openooda.org/oodiff3/install.sh | bash
```

### Native Package Managers
```bash
# Arch Linux (AUR / PKGBUILD)
yay -S oodiff3-bin
# Or manual PKGBUILD:
cd packaging/arch && makepkg -si

# Debian / Ubuntu (.deb)
curl -fsSL https://tools.openooda.org/oodiff3/install.sh | bash -s -- --deb

# Fedora / RHEL (.rpm)
curl -fsSL https://tools.openooda.org/oodiff3/install.sh | bash -s -- --rpm
```

### Uninstallation
```bash
oodiff3-uninstall
# or: curl -fsSL https://tools.openooda.org/oodiff3/uninstall.sh | bash
```

---

## 2. CLI Usage

```
usage: oodiff3 [options] MYFILE OLDFILE YOURFILE

3-way file comparison engine reconciling conflicts between common ancestor and branches.

Options:
  -m, --merge           output actual merged file, according to -A if no other options are given
  -A, --show-all        output all changes, bracketing conflicts
  -E, --show-overlap    like -e, but bracket conflicts
  -e, --ed              output ed script incorporating changes
  -3, --easy-only       like -e, but incorporate only nonoverlapping changes
  -x, --overlap-only    like -e, but incorporate only overlapping changes
  -X                    like -x, but bracket conflicts
  -i                    append 'w' and 'q' commands to ed scripts
  -T, --initial-tab     make tabs line up by prepending a tab
  -a, --text            treat all files as text
  -L, --label=LABEL     use LABEL instead of file name (can be used up to 3 times)
  -j, --json            output formatted as JSON Lines
  -D, --demo            synthetic multi-scenario reconciliation showcase
      --color <WHEN>    colorize output: auto, always, never [default: auto]
      --theme <NAME>    override active oote palette
      --mcp             run as Model Context Protocol stdio server
      --test            run internal verification anchor suite
  -h, --help            display this help and exit
  -v, --version         output version information and exit
```

### Examples

```bash
# Compare branches against baseline in standard diff3 format
oodiff3 branch_a.txt ancestor.txt branch_b.txt

# Perform 3-way merge with standard conflict markers
oodiff3 -m branch_a.txt ancestor.txt branch_b.txt

# Specify custom conflict labels
oodiff3 -m -L "MINE" -L "COMMON_ANCESTOR" -L "YOURS" mine.txt base.txt yours.txt

# Generate ed editing script for unconflicted changes
oodiff3 -3 mine.txt base.txt yours.txt

# Stream structured JSON Lines analysis of diff hunks and conflict telemetry
oodiff3 -j mine.txt base.txt yours.txt

# Run built-in synthetic showcase
oodiff3 --demo
```

---

## 3. Theming Integration (`oote`)

`oodiff3` synchronizes visual styles and status colors with [oote](https://github.com/openOODA-tools/oote):
* **Configuration:** Reads active palette from `~/.openooda/theme.oot`.
* **Environment Overrides:** Respects `$OODA_THEME` and `$NO_COLOR`.

---

## 4. Model Context Protocol (MCP)

When invoked with `--mcp`, `oodiff3` runs a JSON-RPC 2.0 stdio server providing structured tools for AI coding agents:

```bash
oodiff3 --mcp
```

### Supported MCP Tools

* **`diff3_merge`**: Reconciles divergent branches against common baseline, returning unified merged content with conflict markers.
* **`diff3_compare`**: Returns 3-way hunk comparison with exact file coordinate intervals.
* **`diff3_conflicts`**: Returns structured telemetry for only the conflicting regions across branches.
* **`diff3_ed_script`**: Generates ed editing script to reconcile file 1 with file 3.
* **`diff3_demo`**: Returns multi-scenario synthetic 3-way reconciliation demonstration document.

---

## 5. Security & Zero Ambient Authority

* **Pure Capability Bounded:** Operates strictly with explicit tokens (`&FsReadCap`, `&ProcessCap`, `&EnvCap`). Physical absence of ambient disk or network authority.
* **Negative-Trust Architecture:** Strict line bounds and memory limits prevent denial-of-service on adversarial inputs.
* **Hermetic Binary:** Standalone zero-dependency executable.

---

## 6. License

Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
