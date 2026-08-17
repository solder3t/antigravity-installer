#!/usr/bin/env bash
set -euo pipefail

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

OUTDIR="${OUTDIR:-$HOME/rpkg}"

FALLBACK_VERSION_IDE="2.5.5"
FALLBACK_VERSION_AGENT="2.8.1"

FALLBACK_URL_IDE_X64="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.5.5-4923483625488384/linux-x64/Antigravity%20IDE.tar.gz"
FALLBACK_URL_AGENT_X64="https://storage.googleapis.com/antigravity-public/antigravity-hub/2.8.1-6512087774658560/linux-x64/Antigravity.tar.gz"

RESOLVED_VERSION_IDE=""
RESOLVED_URL_IDE_X64=""

RESOLVED_VERSION_AGENT=""
RESOLVED_URL_AGENT_X64=""

# ── Version Auto-Detection ──────────────────────────────────────────────────
resolve_latest_version() {
    local feed_url="https://storage.googleapis.com/antigravity-public/latest.json"
    echo -e "${YELLOW}Checking for the latest stable releases...${NC}"

    local json
    json=$(curl -fsSL --max-time 5 "$feed_url" 2>/dev/null) || true

    if [[ -n "$json" ]] && command -v python3 &>/dev/null; then
        # IDE
        RESOLVED_VERSION_IDE=$(echo "$json" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('ide', {}).get('version', ''))" 2>/dev/null || true)
        RESOLVED_URL_IDE_X64=$(echo "$json" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('ide', {}).get('url_x64', ''))" 2>/dev/null || true)

        # Agent
        RESOLVED_VERSION_AGENT=$(echo "$json" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('agent', {}).get('version', ''))" 2>/dev/null || true)
        RESOLVED_URL_AGENT_X64=$(echo "$json" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('agent', {}).get('url_x64', ''))" 2>/dev/null || true)
    fi

    # Fallbacks for IDE
    if [[ -z "$RESOLVED_VERSION_IDE" || -z "$RESOLVED_URL_IDE_X64" ]]; then
        echo -e "${YELLOW}Warning: Could not resolve IDE from feed. Using fallback.${NC}"
        RESOLVED_VERSION_IDE="$FALLBACK_VERSION_IDE"
        RESOLVED_URL_IDE_X64="$FALLBACK_URL_IDE_X64"
    fi

    # Fallbacks for Agent
    if [[ -z "$RESOLVED_VERSION_AGENT" || -z "$RESOLVED_URL_AGENT_X64" ]]; then
        echo -e "${YELLOW}Warning: Could not resolve Agent from feed. Using fallback.${NC}"
        RESOLVED_VERSION_AGENT="$FALLBACK_VERSION_AGENT"
        RESOLVED_URL_AGENT_X64="$FALLBACK_URL_AGENT_X64"
    fi

    echo -e "${GREEN}✓ Resolved IDE to v${RESOLVED_VERSION_IDE}${NC}"
    echo -e "${GREEN}✓ Resolved Agent to v${RESOLVED_VERSION_AGENT}${NC}"
}

# ── Build RPM ───────────────────────────────────────────────────────────────
build_rpm() {
    local mode="$1"
    local version="$2"
    local dl_url="$3"
    
    local spec_file="antigravity-${mode}.spec"

    echo -e "\n${BLUE}${BOLD}=== Building RPM Package ($mode) ===${NC}"

    for tool in spectool rpkg; do
        if ! command -v "$tool" &>/dev/null; then
            echo -e "${RED}Error: Required packaging utility '${tool}' is missing.${NC}" >&2
            exit 1
        fi
    done

    # Generate Desktop file required by RPM
    if [[ "$mode" == "ide" ]]; then
        cat << 'EOF' > antigravity-ide.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Antigravity 2.0 IDE
Comment=Experience liftoff (v2.0 Standalone IDE)
Exec=/usr/bin/antigravity-ide --new-window %F
Icon=antigravity
Terminal=false
Categories=Development;IDE;
StartupNotify=true
StartupWMClass=AntigravityIDE
EOF
    else
        cat << 'EOF' > antigravity-agent.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Antigravity 2.0 Agent
Comment=Experience liftoff (v2.0 Agent)
Exec=/usr/bin/antigravity --new-window %F
Icon=antigravity
Terminal=false
Categories=Development;IDE;
StartupNotify=true
StartupWMClass=Antigravity
EOF
    fi

    # Ensure spec file is aligned with current version and URL
    sed -i "s|^Version:.*|Version:        ${version}|" "$spec_file"
    sed -i "s|^Source0:.*|Source0:        ${dl_url}|" "$spec_file"

    echo "Downloading sources for $mode..."
    spectool -gS "$spec_file"

    echo "Building RPM package..."
    rpkg local --outdir "$OUTDIR" --spec "$spec_file"

    echo -e "${GREEN}✓ RPM package built successfully in ${OUTDIR}${NC}"
}

# ── Build DEB ───────────────────────────────────────────────────────────────
build_deb() {
    local mode="$1"
    local version="$2"
    local dl_url="$3"

    echo -e "\n${BLUE}${BOLD}=== Building DEB Package ($mode) ===${NC}"

    if ! command -v dpkg-deb &>/dev/null; then
        echo -e "${RED}Error: Required utility 'dpkg-deb' is missing.${NC}" >&2
        exit 1
    fi

    local stage_dir
    stage_dir=$(mktemp -d -t antigravity-${mode}-deb-XXXXXX)
    # Cleanup trap handles removing the current staging directory
    trap 'rm -rf "$stage_dir"' EXIT INT TERM

    # Mode specifics
    local install_dir bin_dir desktop_dir pixmap_dir control_dir pkg_name target_bin app_name app_comment wm_class ext_dir_target
    if [[ "$mode" == "ide" ]]; then
        ext_dir_target="antigravity-ide-Linux"
        install_dir="$stage_dir/opt/$ext_dir_target"
        bin_dir="$stage_dir/usr/bin"
        desktop_dir="$stage_dir/usr/share/applications"
        pixmap_dir="$stage_dir/usr/share/pixmaps"
        control_dir="$stage_dir/DEBIAN"
        pkg_name="antigravity-ide"
        target_bin="antigravity-ide"
        app_name="Antigravity 2.0 IDE"
        app_comment="Experience liftoff (v2.0 Standalone IDE)"
        wm_class="AntigravityIDE"
    else
        ext_dir_target="antigravity-Linux"
        install_dir="$stage_dir/opt/$ext_dir_target"
        bin_dir="$stage_dir/usr/bin"
        desktop_dir="$stage_dir/usr/share/applications"
        pixmap_dir="$stage_dir/usr/share/pixmaps"
        control_dir="$stage_dir/DEBIAN"
        pkg_name="antigravity-agent"
        target_bin="antigravity"
        app_name="Antigravity 2.0 Agent"
        app_comment="Experience liftoff (v2.0 Agent)"
        wm_class="Antigravity"
    fi

    mkdir -p "$install_dir" "$bin_dir" "$desktop_dir" "$pixmap_dir" "$control_dir"

    # We determine the filename from the URL
    local tarball
    tarball=$(basename "${dl_url%%\?*}")

    if [[ ! -f "$tarball" ]]; then
        echo "Downloading $mode package..."
        curl -L --progress-bar -o "$tarball" "$dl_url"
    else
        echo "Using existing local package: $tarball"
    fi

    echo "Extracting to staging area..."
    tar -xzf "$tarball" -C "$stage_dir/opt"

    # Because extraction folder names can vary, we rename the first directory found inside /opt
    local ext_dir
    ext_dir=$(find "$stage_dir/opt" -maxdepth 1 -mindepth 1 -type d | head -n 1)
    if [[ -n "$ext_dir" && "$ext_dir" != "$install_dir" ]]; then
        mv "$ext_dir" "$install_dir"
    fi

    echo "Creating launcher wrapper..."
    cat > "$bin_dir/$target_bin" <<WRAPPER
#!/usr/bin/env bash
EXTRA_ARGS=()
if [[ "\$XDG_SESSION_TYPE" == "wayland" ]]; then
    EXTRA_ARGS=(
        "--ozone-platform-hint=wayland"
        "--enable-features=WaylandWindowDecorations,CanvasOopRasterization"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
    )
fi
exec /opt/$ext_dir_target/$target_bin "\${EXTRA_ARGS[@]}" "\$@"
WRAPPER
    chmod 755 "$bin_dir/$target_bin"

    echo "Configuring desktop integration..."
    cat > "$desktop_dir/$pkg_name.desktop" <<DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=$app_name
Comment=$app_comment
GenericName=IDE
Exec=/usr/bin/$target_bin --new-window %F
Icon=antigravity
Terminal=false
Categories=Development;IDE;
StartupNotify=true
StartupWMClass=$wm_class
DESKTOP
    chmod 644 "$desktop_dir/$pkg_name.desktop"

    echo "Copying icon..."
    cp antigravity.png "$pixmap_dir/antigravity.png"

    echo "Writing package control file..."
    cat > "$control_dir/control" <<CONTROL
Package: $pkg_name
Version: ${version}
Section: devel
Priority: optional
Architecture: amd64
Maintainer: solder3t <solder3t@users.noreply.github.com>
Description: $app_comment
 Repackaged precompiled upstream binaries for $app_name.
Depends: tar, gzip
CONTROL
    chmod 644 "$control_dir/control"

    echo "Building Debian package for $mode..."
    local deb_name="${pkg_name}_${version}-1_amd64.deb"
    dpkg-deb --build "$stage_dir" "$OUTDIR/$deb_name"

    echo -e "${GREEN}✓ Debian package built successfully: $OUTDIR/$deb_name${NC}"
    
    # Remove trap so it doesn't fire when function returns normally
    trap - EXIT INT TERM
    rm -rf "$stage_dir"
}

# ── Main Entrypoint ──────────────────────────────────────────────────────────
mkdir -p "$OUTDIR"

# Parse package format target
TARGET=""
if [[ $# -gt 0 ]]; then
    case "$1" in
        rpm)    TARGET="rpm" ;;
        deb)    TARGET="deb" ;;
        all)    TARGET="all" ;;
        -h|--help)
            echo "Usage: $(basename "$0") [rpm | deb | all]"
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown target '$1'. Choose 'rpm', 'deb', or 'all'.${NC}" >&2
            exit 1
            ;;
    esac
fi

# Auto-detect target format based on packaging tools if not specified
if [[ -z "$TARGET" ]]; then
    if command -v rpkg &>/dev/null && command -v spectool &>/dev/null; then
        TARGET="rpm"
    elif command -v dpkg-deb &>/dev/null; then
        TARGET="deb"
    else
        if command -v dnf &>/dev/null; then
            TARGET="rpm"
        else
            TARGET="deb"
        fi
    fi
    echo -e "${YELLOW}Auto-detected target format: ${BOLD}${TARGET}${NC}"
fi

resolve_latest_version

if [[ "$TARGET" == "rpm" || "$TARGET" == "all" ]]; then
    build_rpm "ide" "$RESOLVED_VERSION_IDE" "$RESOLVED_URL_IDE_X64"
    build_rpm "agent" "$RESOLVED_VERSION_AGENT" "$RESOLVED_URL_AGENT_X64"
fi

if [[ "$TARGET" == "deb" || "$TARGET" == "all" ]]; then
    build_deb "ide" "$RESOLVED_VERSION_IDE" "$RESOLVED_URL_IDE_X64"
    build_deb "agent" "$RESOLVED_VERSION_AGENT" "$RESOLVED_URL_AGENT_X64"
fi
