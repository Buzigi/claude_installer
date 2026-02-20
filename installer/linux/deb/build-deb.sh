#!/bin/bash
# Build .deb package for Claude Code Installer
# Usage: ./build-deb.sh [version]

set -e

# Get version from argument or use date-based version
VERSION="${1:-$(date +%Y%m%d)}"
PACKAGE_NAME="claude-installer"
ARCH="all"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/claude-installer"
DIST_DIR="$ROOT_DIR/dist"

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/share/claude-installer"
mkdir -p "$BUILD_DIR/usr/share/applications"
mkdir -p "$BUILD_DIR/usr/bin"

echo "Building $PACKAGE_NAME version $VERSION..."

# Copy main scripts
cp "$ROOT_DIR/Install-ClaudeCode.ps1" "$BUILD_DIR/usr/share/claude-installer/"
cp "$ROOT_DIR/install-claude-code.sh" "$BUILD_DIR/usr/share/claude-installer/"
cp "$ROOT_DIR/Uninstall-ClaudeCode.ps1" "$BUILD_DIR/usr/share/claude-installer/" 2>/dev/null || true
cp "$ROOT_DIR/uninstall-claude-code.sh" "$BUILD_DIR/usr/share/claude-installer/" 2>/dev/null || true
cp "$ROOT_DIR/Verify-Installation.ps1" "$BUILD_DIR/usr/share/claude-installer/" 2>/dev/null || true
cp "$ROOT_DIR/Update-Skills.ps1" "$BUILD_DIR/usr/share/claude-installer/" 2>/dev/null || true

# Copy configuration, templates, skills, and agents
cp -r "$ROOT_DIR/config" "$BUILD_DIR/usr/share/claude-installer/" 2>/dev/null || true
cp -r "$ROOT_DIR/templates" "$BUILD_DIR/usr/share/claude-installer/" 2>/dev/null || true
cp -r "$ROOT_DIR/skills" "$BUILD_DIR/usr/share/claude-installer/" 2>/dev/null || true
cp -r "$ROOT_DIR/agents" "$BUILD_DIR/usr/share/claude-installer/" 2>/dev/null || true
cp -r "$ROOT_DIR/docs" "$BUILD_DIR/usr/share/claude-installer/" 2>/dev/null || true

# Copy documentation
cp "$ROOT_DIR/README.md" "$BUILD_DIR/usr/share/claude-installer/" 2>/dev/null || true
cp "$ROOT_DIR/CLAUDE.md" "$BUILD_DIR/usr/share/claude-installer/" 2>/dev/null || true

# Create launcher script
cat > "$BUILD_DIR/usr/bin/claude-installer" << 'LAUNCHER_EOF'
#!/bin/bash
# Claude Code Installer Launcher

INSTALL_DIR="/usr/share/claude-installer"

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

chmod +x "$BUILD_DIR/usr/bin/claude-installer"

# Create desktop entry
cat > "$BUILD_DIR/usr/share/applications/claude-installer.desktop" << 'DESKTOP_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Claude Code Installer
GenericName=Claude Code Installer
Comment=Install Claude Code CLI with GLM5 configuration
Exec=claude-installer
Icon=terminal
Terminal=true
Categories=Development;Utility;
Keywords=claude;ai;installer;development;
DESKTOP_EOF

# Create control file
cat > "$BUILD_DIR/DEBIAN/control" << EOF
Package: $PACKAGE_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Depends: bash, curl, git
Recommends: powershell | pwsh
Maintainer: Claude Installer Project <https://github.com/Buzigi/claude_installer>
Description: Claude Code CLI Installer with GLM5 configuration
 Installs Claude Code CLI with GLM5 model configuration, skills,
 agents, and hooks for an Agent-First workflow. Includes complete
 setup for development environment with Zhipu AI proxy support.
Homepage: https://github.com/Buzigi/claude_installer
EOF

# Create postinst script
cat > "$BUILD_DIR/DEBIAN/postinst" << 'POSTINST_EOF'
#!/bin/bash
set -e

echo ""
echo "Claude Code Installer installed successfully!"
echo ""
echo "To install Claude Code, run:"
echo "  claude-installer"
echo ""
echo "Or directly:"
echo "  /usr/share/claude-installer/install-claude-code.sh"
echo ""

exit 0
POSTINST_EOF

chmod 755 "$BUILD_DIR/DEBIAN/postinst"

# Create prerm script
cat > "$BUILD_DIR/DEBIAN/prerm" << 'PRERM_EOF'
#!/bin/bash
set -e

echo "Removing Claude Code Installer..."

exit 0
PRERM_EOF

chmod 755 "$BUILD_DIR/DEBIAN/prerm"

# Build the package
mkdir -p "$DIST_DIR"
OUTPUT_FILE="$DIST_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"

echo "Building package: $OUTPUT_FILE"
dpkg-deb --build "$BUILD_DIR" "$OUTPUT_FILE"

echo ""
echo "Package built successfully: $OUTPUT_FILE"
echo "Size: $(du -h "$OUTPUT_FILE" | cut -f1)"
