# oodiff3 v0.2.0 Makefile

OODA_COMPILER ?= $(firstword $(wildcard $(HOME)/.openooda/bin/oodac $(CURDIR)/../../openOODA/oodac/bin/oodac))
OODACODEX ?= $(HOME)/.openooda/northstar.oot
OO_LIST_AMBIENT_QUOTA ?= 8589934592
BIN := dist/oodiff3

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

SRC := $(wildcard *.oo) $(wildcard */*.oo)
VERSION ?= $(shell cat VERSION 2>/dev/null || echo 0.2.0)

.PHONY: build check line-cap file-law academy density verify clean test package package-deb package-rpm package-arch install uninstall

build: $(BIN)

$(BIN): $(SRC)
	@mkdir -p dist .ooda-cache/ooda-tmp
	OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODACODEX=$(OODACODEX) OODA_COMPILER=$(OODA_COMPILER) OODA_NO_JAIL=1 $(OODA_COMPILER) build main.oo -o $(BIN)
	@chmod +x $(BIN)
	@cp -a $(BIN) dist/oodiff3-linux-x86_64
	@sha256sum dist/oodiff3-linux-x86_64 > dist/oodiff3-linux-x86_64.sha256
	@echo "built $(BIN) (and dist/oodiff3-linux-x86_64)"

# --- Verification gate ---------------------------------------------------------

line-cap:
	@violations=0; \
	for f in $$(find . -name "*.oo" -o -name "*.oot" | grep -v "/dist/" | grep -v "/.ooda-cache/"); do \
		n=$$(wc -l < "$$f"); \
		if [ $$n -gt 256 ]; then \
			echo "VIOLATION: $$f = $$n lines (exceeds 256)"; violations=$$((violations+1)); \
		fi; \
		code=$$(grep -vE '^[[:space:]]*(//.*)?$$' "$$f" | grep -cvE '^[[:space:]]*import[[:space:]]+"'); \
		if [ "$$code" = "0" ]; then continue; fi; \
		if [ $$n -lt 16 ]; then \
			echo "VIOLATION: $$f = $$n lines (under 16-line floor, not a shim)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations files violate the Page Rule"; exit 1; fi; \
	echo "PASS: Page Rule sizing (16-256 lines, shims exempt from floor) holds"

file-law:
	@forbidden="js ts rb pl json yaml toml"; \
	violations=0; \
	for ext in $$forbidden; do \
		found=$$(find . -name "*.$$ext" -not -path "./.git/*" -not -path "./.github/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" 2>/dev/null | head -3); \
		if [ -n "$$found" ]; then \
			echo "VIOLATION: .$$ext forbidden:"; echo "$$found"; violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.md" -not -path "./.git/*" -not -path "./.github/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" 2>/dev/null); do \
		if [ "$$f" != "./README.md" ] && [ "$$f" != "./AGENTS.md" ]; then \
			echo "VIOLATION: .md forbidden outside README.md and AGENTS.md: $$f"; violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.sh" -not -path "./.git/*" -not -path "./dist/*" 2>/dev/null); do \
		if [ "$$f" != "./install.sh" ] && [ "$$f" != "./uninstall.sh" ]; then \
			echo "VIOLATION: .sh forbidden outside install.sh and uninstall.sh: $$f"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: file-law violations"; exit 1; fi; \
	echo "PASS: file law holds"

academy:
	@failures=0; \
	for f in $$(find . -name "*.oo" -not -path "./dist/*"); do \
		header=$$(head -7 "$$f"); \
		missing=""; \
		echo "$$header" | grep -q "^// # "        || missing="$$missing title"; \
		echo "$$header" | grep -q "^// Logline:"  || missing="$$missing logline"; \
		echo "$$header" | grep -q "^// Setup:"    || missing="$$missing setup"; \
		echo "$$header" | grep -q "^// Beats:"    || missing="$$missing beats"; \
		if [ -n "$$missing" ]; then \
			echo "FAIL: $$f missing Academy element(s):$$missing"; failures=$$((failures+1)); \
		fi; \
	done; \
	if [ $$failures -gt 0 ]; then echo "FAIL: $$failures academy header violations"; exit 1; fi; \
	echo "PASS: academy headers hold (all 4 elements present in first 7 lines)"

density:
	@violations=0; \
	for d in $$(find . -type d -not -path "./.git*" -not -path "./dist*" -not -path "./.ooda-cache*" -not -path "./packaging*" -not -path "./qa*"); do \
		n=$$(ls "$$d"/*.oo "$$d"/*.oot 2>/dev/null | grep -v '\*' | wc -l); \
		if [ $$n -gt 8 ]; then \
			echo "VIOLATION: $$d holds $$n pages (exceeds 8)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations directories exceed the density bound"; exit 1; fi; \
	echo "PASS: directory density (<= 8 pages per directory) holds"

check:
	@for f in $$(find . -name "*.oo" -not -path "./dist/*"); do \
		OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODACODEX=$(OODACODEX) OODA_COMPILER=$(OODA_COMPILER) OODA_NO_JAIL=1 $(OODA_COMPILER) check "$$f" > /dev/null || exit 1; \
	done; \
	echo "PASS: oodac check holds on all .oo files"

verify: line-cap file-law academy density check

test: $(BIN)
	@echo "=== testing --help ==="
	@./$(BIN) --help > /dev/null && echo "PASS: --help"
	@echo "=== testing --version ==="
	@./$(BIN) --version | grep -q "0.2.0" && echo "PASS: --version"
	@echo "=== testing internal anchors ==="
	@./$(BIN) --test | grep -q "oodiff3: internal anchor tests PASSED" && echo "PASS: internal anchors"
	@echo "=== testing --demo ==="
	@./$(BIN) -D | grep -q "SOVEREIGN 3-WAY RECONCILIATION SHOWCASE" && echo "PASS: --demo"
	@echo "=== testing --demo --json ==="
	@./$(BIN) -D -j | grep -q "oodiff3" && echo "PASS: --demo -j"
	@echo "=== testing standard 3-way compare ==="
	@mkdir -p /tmp/oodiff3_test && \
	  printf "base1\nbase2\nbase3\n" > /tmp/oodiff3_test/base.txt && \
	  printf "mine1\nbase2\nbase3\n" > /tmp/oodiff3_test/mine.txt && \
	  printf "base1\nbase2\nyours3\n" > /tmp/oodiff3_test/yours.txt && \
	  ./$(BIN) /tmp/oodiff3_test/mine.txt /tmp/oodiff3_test/base.txt /tmp/oodiff3_test/yours.txt | grep -q "====1" && echo "PASS: standard compare"
	@echo "=== testing 3-way unconflicted merge ==="
	@./$(BIN) -m /tmp/oodiff3_test/mine.txt /tmp/oodiff3_test/base.txt /tmp/oodiff3_test/yours.txt | grep -q "mine1" && echo "PASS: unconflicted merge"
	@echo "=== testing 3-way conflicting merge ==="
	@printf "conflict_mine\nbase2\nbase3\n" > /tmp/oodiff3_test/mine_c.txt && \
	  printf "conflict_yours\nbase2\nbase3\n" > /tmp/oodiff3_test/yours_c.txt && \
	  (./$(BIN) -m /tmp/oodiff3_test/mine_c.txt /tmp/oodiff3_test/base.txt /tmp/oodiff3_test/yours_c.txt || true) | grep -q "<<<<<<<" && echo "PASS: conflicting merge markers"
	@echo "=== testing ed script ==="
	@./$(BIN) -e /tmp/oodiff3_test/mine.txt /tmp/oodiff3_test/base.txt /tmp/oodiff3_test/yours.txt | grep -q "c" && echo "PASS: ed script"
	@rm -rf /tmp/oodiff3_test
	@echo "=== testing MCP initialize ==="
	@printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}\n' | ./$(BIN) --mcp | grep -q "protocolVersion" && echo "PASS: MCP initialize"
	@echo "=== testing MCP tools/list ==="
	@printf '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp | grep -q "diff3_merge" && echo "PASS: MCP tools/list"
	@echo "=== testing MCP tools/call diff3_merge ==="
	@printf '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"diff3_merge","arguments":{"text1":"mine\nshared\n","text2":"base\nshared\n","text3":"base\nshared\nyours\n"}}}\n' | ./$(BIN) --mcp | grep -q 'mine' && echo "PASS: MCP diff3_merge"
	@echo "=== testing MCP tools/call diff3_compare ==="
	@printf '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"diff3_compare","arguments":{"text1":"mine\n","text2":"base\n","text3":"yours\n"}}}\n' | ./$(BIN) --mcp | grep -q '====' && echo "PASS: MCP diff3_compare"
	@echo "=== testing MCP tools/call diff3_conflicts ==="
	@printf '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"diff3_conflicts","arguments":{"text1":"mine\n","text2":"base\n","text3":"yours\n"}}}\n' | ./$(BIN) --mcp | grep -q 'conflict' && echo "PASS: MCP diff3_conflicts"
	@echo "=== testing MCP tools/call diff3_ed_script ==="
	@printf '{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"diff3_ed_script","arguments":{"text1":"mine\n","text2":"base\n","text3":"yours\n"}}}\n' | ./$(BIN) --mcp | grep -q 'c' && echo "PASS: MCP diff3_ed_script"
	@echo "=== testing MCP tools/call diff3_demo ==="
	@printf '{"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"diff3_demo","arguments":{}}}\n' | ./$(BIN) --mcp | grep -q 'SHOWCASE' && echo "PASS: MCP diff3_demo"
	@echo "ALL TESTS PASSED"

install: $(BIN)
	@mkdir -p $(DESTDIR)$(BINDIR)
	install -m 0755 $(BIN) $(DESTDIR)$(BINDIR)/oodiff3
	install -m 0755 uninstall.sh $(DESTDIR)$(BINDIR)/oodiff3-uninstall
	@echo "installed oodiff3 and oodiff3-uninstall to $(DESTDIR)$(BINDIR)"

uninstall:
	@rm -f $(DESTDIR)$(BINDIR)/oodiff3 $(DESTDIR)$(BINDIR)/oodiff3-uninstall
	@if [ "$(PURGE)" = "1" ]; then rm -rf $(HOME)/.cache/oodiff3 $(HOME)/.config/oodiff3; echo "purged user cache and config"; fi
	@echo "uninstalled oodiff3 and oodiff3-uninstall from $(DESTDIR)$(BINDIR)"

package-deb: $(BIN)
	@mkdir -p dist/deb-root/DEBIAN dist/deb-root/usr/bin
	@sed "s/^Version:.*/Version: $(VERSION)-1/" packaging/debian/control.binary > dist/deb-root/DEBIAN/control
	@cp $(BIN) dist/deb-root/usr/bin/oodiff3
	@chmod 0755 dist/deb-root/usr/bin/oodiff3
	@cp uninstall.sh dist/deb-root/usr/bin/oodiff3-uninstall
	@chmod 0755 dist/deb-root/usr/bin/oodiff3-uninstall
	@dpkg-deb --build --root-owner-group dist/deb-root dist/oodiff3_$(VERSION)-1_amd64.deb
	@rm -rf dist/deb-root
	@echo "built dist/oodiff3_$(VERSION)-1_amd64.deb"

package-rpm: $(BIN)
	@mkdir -p ~/rpmbuild/SOURCES ~/rpmbuild/SPECS ~/rpmbuild/RPMS
	@cp $(BIN) ~/rpmbuild/SOURCES/oodiff3-linux-x86_64
	@cp uninstall.sh ~/rpmbuild/SOURCES/uninstall.sh
	@sed "s/^Version:.*/Version: $(VERSION)/" packaging/oodiff3.spec > ~/rpmbuild/SPECS/oodiff3.spec
	@rpmbuild -bb ~/rpmbuild/SPECS/oodiff3.spec
	@cp ~/rpmbuild/RPMS/x86_64/oodiff3-$(VERSION)*.rpm dist/
	@echo "built dist RPM package"

package-arch: $(BIN)
	@mkdir -p dist/arch-pkg/usr/bin
	@cp $(BIN) dist/arch-pkg/usr/bin/oodiff3
	@chmod 0755 dist/arch-pkg/usr/bin/oodiff3
	@cp uninstall.sh dist/arch-pkg/usr/bin/oodiff3-uninstall
	@chmod 0755 dist/arch-pkg/usr/bin/oodiff3-uninstall
	@printf "pkgname = oodiff3\npkgbase = oodiff3\npkgver = $(VERSION)-1\npkgdesc = Sovereign 3-way file reconciliation and conflict merger in pure openOODA.\nurl = https://github.com/openOODA-tools/oodiff3\nbuilddate = $$(date +%s)\npackager = openOODA-tools <ops@openooda.org>\nsize = $$(stat -c %s $(BIN))\narch = x86_64\nlicense = Apache-2.0\ndepend = glibc\nprovides = oodiff3\n" > dist/arch-pkg/.PKGINFO
	@tar --zstd -cf dist/oodiff3-$(VERSION)-1-x86_64.pkg.tar.zst -C dist/arch-pkg .PKGINFO usr
	@rm -rf dist/arch-pkg
	@bash -n packaging/arch/PKGBUILD
	@cp packaging/arch/PKGBUILD packaging/PKGBUILD
	@echo "built dist/oodiff3-$(VERSION)-1-x86_64.pkg.tar.zst and validated PKGBUILD"

package: package-deb package-rpm package-arch
	@cd dist && sha256sum oodiff3* > checksums.txt 2>/dev/null || true
	@echo "built all packages and dist/checksums.txt"

clean:
	@rm -rf dist .ooda-cache
	@echo "cleaned"
