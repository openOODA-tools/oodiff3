Name:           oodiff3
Version:        0.1.0
Release:        1%{?dist}
Summary:        3-way file comparison engine reconciling conflicts between common ancestor and branches.
License:        ASL 2.0
URL:            https://github.com/openOODA-tools/oodiff3
Source0:        oodiff3-linux-x86_64
Source1:        uninstall.sh
BuildArch:      x86_64
Requires:       glibc

%description
oodiff3 is a sovereign, capability-bounded THREE-WAY MERGER written
in pure openOODA, featuring zero ambient authority, oote color themes,
and an MCP stdio server.

%install
mkdir -p %{buildroot}/usr/bin
install -m 0755 %{SOURCE0} %{buildroot}/usr/bin/oodiff3
install -m 0755 %{SOURCE1} %{buildroot}/usr/bin/oodiff3-uninstall

%files
/usr/bin/oodiff3
/usr/bin/oodiff3-uninstall

%changelog
* Wed Oct 07 2026 openOODA-tools <ops@openooda.org> - 0.1.0-1
- Initial sovereign blueprint scaffolding
