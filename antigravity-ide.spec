# Disable debug packages — we're repackaging precompiled upstream binaries
%global debug_package %{nil}
%undefine __brp_check_rpaths

%global __provides_exclude_from ^/opt/antigravity-ide-Linux/.*\.so.*$
%global __requires_exclude_from ^/opt/antigravity-ide-Linux/.*\.so.*$
%global __requires_exclude ^(libstdc\+\+\.so\.6.*|libgcc_s\.so\.1.*|/usr/bin/python3)

Name:           antigravity-ide
Version:        __VERSION__
Release:        1%{?dist}
Summary:        Antigravity 2.0 IDE

License:        Proprietary (Google Terms of Service)
URL:            https://google.com
ExclusiveArch:  x86_64

Source0:        __URL_X64__
Source1:        antigravity-ide.desktop
Source2:        antigravity.png

BuildRequires:  tar
BuildRequires:  gzip

Requires:       liberation-fonts
Requires:       libX11
Requires:       libXext
Requires:       libXrender
Requires:       libXtst
Requires:       libXi
Requires:       freetype
Requires:       fontconfig

%description
Antigravity 2.0 IDE is a standalone development environment for modern agentic workflows.
This package repackages the upstream precompiled binaries for Fedora.

%prep
%setup -c -T
tar -xzf %{SOURCE0}

%build
# Repackaging precompiled upstream binaries

%install
mkdir -p %{buildroot}/opt
# Find the extracted directory name and move it
EXTRACTED_DIR=$(find . -maxdepth 1 -mindepth 1 -type d | head -n 1)
mv $EXTRACTED_DIR %{buildroot}/opt/antigravity-ide-Linux

# Wrapper script
mkdir -p %{buildroot}%{_bindir}
cat << 'EOF' > %{buildroot}%{_bindir}/antigravity-ide
#!/usr/bin/env bash
# Apply Wayland and GPU acceleration optimizations
EXTRA_ARGS=()
if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
    EXTRA_ARGS=(
        "--ozone-platform-hint=wayland"
        "--enable-features=WaylandWindowDecorations,CanvasOopRasterization"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
    )
fi
exec /opt/antigravity-ide-Linux/antigravity-ide "${EXTRA_ARGS[@]}" "$@"
EOF
chmod +x %{buildroot}%{_bindir}/antigravity-ide

# Install desktop entry
mkdir -p %{buildroot}%{_datadir}/applications
install -m 644 %{SOURCE1} %{buildroot}%{_datadir}/applications/antigravity-ide.desktop

# Icons
mkdir -p %{buildroot}%{_datadir}/pixmaps
install -m 644 %{SOURCE2} %{buildroot}%{_datadir}/pixmaps/antigravity.png

%post
/usr/bin/update-desktop-database &>/dev/null || :

%postun
/usr/bin/update-desktop-database &>/dev/null || :

%files
/opt/antigravity-ide-Linux/
%{_bindir}/antigravity-ide
%{_datadir}/applications/antigravity-ide.desktop
%{_datadir}/pixmaps/antigravity.png

%changelog
* Tue Aug 11 2026 Maintainer <maintainer@example.com>
- Automated package build
