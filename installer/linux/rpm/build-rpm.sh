#!/bin/bash
# Build .rpm package for Claude Code Installer
# Usage: ./build-rpm.sh [version]

set -e

# Get version from argument or use date-based version
VERSION="${1:-1.0.0}"
PACKAGE_NAME="claude-installer"
RELEASE="1"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"

echo "Building $PACKAGE_NAME version $VERSION-$RELEASE..."

# Create RPM build directory structure
RPM_ROOT="${RPM_ROOT:-$HOME/rpmbuild}"
mkdir -p "$RPM_ROOT"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Create source tarball
TARBALL_NAME="$PACKAGE_NAME-$VERSION"
TARBALL_PATH="$RPM_ROOT/SOURCES/$TARBALL_NAME.tar.gz"

echo "Creating source tarball..."
mkdir -p "/tmp/$TARBALL_NAME"

# Copy files to temp directory
cp "$ROOT_DIR/Install-ClaudeCode.ps1" "/tmp/$TARBALL_NAME/"
cp "$ROOT_DIR/install-claude-code.sh" "/tmp/$TARBALL_NAME/"
cp "$ROOT_DIR/Uninstall-ClaudeCode.ps1" "/tmp/$TARBALL_NAME/" 2>/dev/null || true
cp "$ROOT_DIR/uninstall-claude-code.sh" "/tmp/$TARBALL_NAME/" 2>/dev/null || true
cp "$ROOT_DIR/Verify-Installation.ps1" "/tmp/$TARBALL_NAME/" 2>/dev/null || true
cp "$ROOT_DIR/Update-Skills.ps1" "/tmp/$TARBALL_NAME/" 2>/dev/null || true
cp "$ROOT_DIR/README.md" "/tmp/$TARBALL_NAME/" 2>/dev/null || true
cp "$ROOT_DIR/CLAUDE.md" "/tmp/$TARBALL_NAME/" 2>/dev/null || true

# Copy directories
cp -r "$ROOT_DIR/config" "/tmp/$TARBALL_NAME/" 2>/dev/null || true
cp -r "$ROOT_DIR/templates" "/tmp/$TARBALL_NAME/" 2>/dev/null || true
cp -r "$ROOT_DIR/skills" "/tmp/$TARBALL_NAME/" 2>/dev/null || true
cp -r "$ROOT_DIR/agents" "/tmp/$TARBALL_NAME/" 2>/dev/null || true
cp -r "$ROOT_DIR/docs" "/tmp/$TARBALL_NAME/" 2>/dev/null || true

# Create tarball
tar -czf "$TARBALL_PATH" -C /tmp "$TARBALL_NAME"
rm -rf "/tmp/$TARBALL_NAME"

echo "Source tarball created: $TARBALL_PATH"

# Copy spec file
cp "$SCRIPT_DIR/SPECS/claude-installer.spec" "$RPM_ROOT/SPECS/"
sed -i "s/^Version:.*/Version:        $VERSION/" "$RPM_ROOT/SPECS/claude-installer.spec"
sed -i "s/^Release:.*/Release:        $RELEASE%{?dist}/" "$RPM_ROOT/SPECS/claude-installer.spec"

# Build the RPM
echo "Building RPM package..."
rpmbuild -bb "$RPM_ROOT/SPECS/claude-installer.spec"

# Find and copy the built RPM to dist directory
mkdir -p "$DIST_DIR"
find "$RPM_ROOT/RPMS" -name "*.rpm" -exec cp {} "$DIST_DIR/" \;

echo ""
echo "RPM package built successfully!"
ls -la "$DIST_DIR"/*.rpm 2>/dev/null || echo "No RPM files found in $DIST_DIR"
