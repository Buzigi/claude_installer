#!/bin/bash
# Build AppImage for Claude Code Installer
# Usage: ./build-appimage.sh [version]

set -e

# Get version from argument or use date-based version
VERSION="${1:-$(date +%Y%m%d)}"
PACKAGE_NAME="Claude_Installer"
APPIMAGE_NAME="${PACKAGE_NAME}-${VERSION}-x86_64.AppImage"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APPDIR="$ROOT_DIR/build/AppDir"

echo "Building $PACKAGE_NAME AppImage version $VERSION..."

# Clean and create AppDir structure
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/claude-installer"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# Copy main scripts
echo "Copying files..."
cp "$ROOT_DIR/Install-ClaudeCode.ps1" "$APPDIR/usr/share/claude-installer/"
cp "$ROOT_DIR/install-claude-code.sh" "$APPDIR/usr/share/claude-installer/"
cp "$ROOT_DIR/Uninstall-ClaudeCode.ps1" "$APPDIR/usr/share/claude-installer/" 2>/dev/null || true
cp "$ROOT_DIR/uninstall-claude-code.sh" "$APPDIR/usr/share/claude-installer/" 2>/dev/null || true
cp "$ROOT_DIR/Verify-Installation.ps1" "$APPDIR/usr/share/claude-installer/" 2>/dev/null || true
cp "$ROOT_DIR/Update-Skills.ps1" "$APPDIR/usr/share/claude-installer/" 2>/dev/null || true
cp "$ROOT_DIR/README.md" "$APPDIR/usr/share/claude-installer/" 2>/dev/null || true
cp "$ROOT_DIR/CLAUDE.md" "$APPDIR/usr/share/claude-installer/" 2>/dev/null || true

# Copy directories
cp -r "$ROOT_DIR/config" "$APPDIR/usr/share/claude-installer/" 2>/dev/null || true
cp -r "$ROOT_DIR/templates" "$APPDIR/usr/share/claude-installer/" 2>/dev/null || true
cp -r "$ROOT_DIR/skills" "$APPDIR/usr/share/claude-installer/" 2>/dev/null || true
cp -r "$ROOT_DIR/agents" "$APPDIR/usr/share/claude-installer/" 2>/dev/null || true
cp -r "$ROOT_DIR/docs" "$APPDIR/usr/share/claude-installer/" 2>/dev/null || true

# Create main launcher script
cat > "$APPDIR/usr/bin/claude-installer" << 'LAUNCHER_EOF'
#!/bin/bash
# Claude Code Installer Launcher for AppImage

# Get the AppImage installation directory
if [ -n "$APPIMAGE" ]; then
    INSTALL_DIR="$(dirname "$APPIMAGE")"
else
    INSTALL_DIR="/usr/share/claude-installer"
fi

# For AppImage, files are in the mounted squashfs
if [ -d "$APPDIR/usr/share/claude-installer" ]; then
    INSTALL_DIR="$APPDIR/usr/share/claude-installer"
fi

show_menu() {
    echo ""
    echo "  ================================================================"
    echo "       Claude Code Installer - GLM5 Edition"
    echo "  ================================================================"
    echo ""
    echo "   1. Install Claude Code"
    echo "   2. Verify Installation"
    echo "   3. Update Skills"
    echo "   4. View Documentation"
    echo "   5. Exit"
    echo ""
    echo "  ================================================================"
    echo ""
}

while true; do
    show_menu
    read -p "Enter your choice (1-5): " choice

    case $choice in
        1)
            echo ""
            echo "Starting installation..."
            if command -v pwsh &> /dev/null; then
                pwsh -File "$INSTALL_DIR/Install-ClaudeCode.ps1"
            else
                bash "$INSTALL_DIR/install-claude-code.sh"
            fi
            ;;
        2)
            if [ -f "$INSTALL_DIR/Verify-Installation.ps1" ]; then
                pwsh -File "$INSTALL_DIR/Verify-Installation.ps1"
            else
                echo "Verification script not available"
            fi
            ;;
        3)
            if [ -f "$INSTALL_DIR/Update-Skills.ps1" ]; then
                pwsh -File "$INSTALL_DIR/Update-Skills.ps1"
            else
                echo "Update script not available"
            fi
            ;;
        4)
            if [ -d "$INSTALL_DIR/docs" ]; then
                "${PAGER:-less}" "$INSTALL_DIR/README.md"
            else
                echo "Documentation not available"
            fi
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac

    echo ""
    read -p "Press Enter to continue..."
done
LAUNCHER_EOF

chmod +x "$APPDIR/usr/bin/claude-installer"

# Create AppRun entry point
cat > "$APPDIR/AppRun" << 'APPRUN_EOF'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin:${PATH}"
export APPDIR="$HERE"
exec "${HERE}/usr/bin/claude-installer" "$@"
APPRUN_EOF

chmod +x "$APPDIR/AppRun"

# Create desktop entry
cat > "$APPDIR/usr/share/applications/claude-installer.desktop" << 'DESKTOP_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Claude Code Installer
GenericName=Claude Code Installer
Comment=Install Claude Code CLI with GLM5 configuration
Exec=claude-installer
Icon=claude-installer
Terminal=true
Categories=Development;Utility;
Keywords=claude;ai;installer;development;
StartupNotify=true
DESKTOP_EOF

# Create a simple icon (text-based SVG)
cat > "$APPDIR/claude-installer.svg" << 'SVG_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="256" height="256" viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg">
  <rect width="256" height="256" fill="#2b579a"/>
  <text x="128" y="140" font-family="Arial, sans-serif" font-size="80" font-weight="bold" fill="white" text-anchor="middle">CC</text>
  <text x="128" y="200" font-family="Arial, sans-serif" font-size="32" fill="white" text-anchor="middle">Installer</text>
</svg>
SVG_EOF

# Copy desktop file to root of AppDir (required by AppImage)
cp "$APPDIR/usr/share/applications/claude-installer.desktop" "$APPDIR/claude-installer.desktop"

# Create icon in proper location
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
cp "$APPDIR/claude-installer.svg" "$APPDIR/usr/share/icons/hicolor/256x256/apps/claude-installer.svg"

# Also create a PNG icon using a simple approach
# If ImageMagick is available, convert SVG to PNG
if command -v convert &> /dev/null; then
    convert -background "#2b579a" -fill white -font Arial -pointsize 80 \
        -gravity center -size 256x256 xc:"#2b579a" \
        -annotate 0 "CC\nInstaller" \
        "$APPDIR/claude-installer.png" 2>/dev/null || true
    if [ -f "$APPDIR/claude-installer.png" ]; then
        cp "$APPDIR/claude-installer.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/"
    fi
fi

# Download appimagetool if not present
APPIMAGETOOL="$ROOT_DIR/build/appimagetool"
if [ ! -f "$APPIMAGETOOL" ]; then
    echo "Downloading appimagetool..."
    ARCH=$(uname -m)
    wget -q "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-${ARCH}.AppImage" \
        -O "$APPIMAGETOOL" || curl -sL "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-${ARCH}.AppImage" \
        -o "$APPIMAGETOOL"
    chmod +x "$APPIMAGETOOL"
fi

# Build the AppImage
# Use APPIMAGE_EXTRACT_AND_RUN to avoid FUSE requirement in CI environments
mkdir -p "$DIST_DIR"
echo "Building AppImage..."
export APPIMAGE_EXTRACT_AND_RUN=1
ARCH=$(uname -m) "$APPIMAGETOOL" "$APPDIR" "$DIST_DIR/$APPIMAGE_NAME"

echo ""
echo "AppImage built successfully: $DIST_DIR/$APPIMAGE_NAME"
echo "Size: $(du -h "$DIST_DIR/$APPIMAGE_NAME" | cut -f1)"
