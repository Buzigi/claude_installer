Name:           claude-installer
Version:        1.0.0
Release:        1%{?dist}
Summary:        Claude Code CLI Installer with GLM5 configuration

License:        MIT
URL:            https://github.com/Buzigi/claude_installer
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
Requires:       bash, curl, git
Recommends:     powershell

%description
Installs Claude Code CLI with GLM5 model configuration, skills,
agents, and hooks for an Agent-First workflow. Includes complete
setup for development environment with Zhipu AI proxy support.

%prep
%setup -q

%install
rm -rf %{buildroot}

# Create directories
mkdir -p %{buildroot}/usr/share/claude-installer
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications

# Copy main scripts
install -m 644 Install-ClaudeCode.ps1 %{buildroot}/usr/share/claude-installer/
install -m 755 install-claude-code.sh %{buildroot}/usr/share/claude-installer/
install -m 644 Uninstall-ClaudeCode.ps1 %{buildroot}/usr/share/claude-installer/ 2>/dev/null || true
install -m 755 uninstall-claude-code.sh %{buildroot}/usr/share/claude-installer/ 2>/dev/null || true
install -m 644 Verify-Installation.ps1 %{buildroot}/usr/share/claude-installer/ 2>/dev/null || true
install -m 644 Update-Skills.ps1 %{buildroot}/usr/share/claude-installer/ 2>/dev/null || true

# Copy documentation
install -m 644 README.md %{buildroot}/usr/share/claude-installer/ 2>/dev/null || true
install -m 644 CLAUDE.md %{buildroot}/usr/share/claude-installer/ 2>/dev/null || true

# Copy directories
cp -r config %{buildroot}/usr/share/claude-installer/ 2>/dev/null || true
cp -r templates %{buildroot}/usr/share/claude-installer/ 2>/dev/null || true
cp -r skills %{buildroot}/usr/share/claude-installer/ 2>/dev/null || true
cp -r agents %{buildroot}/usr/share/claude-installer/ 2>/dev/null || true
cp -r docs %{buildroot}/usr/share/claude-installer/ 2>/dev/null || true

# Create launcher script
cat > %{buildroot}/usr/bin/claude-installer << 'LAUNCHER_EOF'
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

chmod 755 %{buildroot}/usr/bin/claude-installer

# Create desktop entry
cat > %{buildroot}/usr/share/applications/claude-installer.desktop << 'DESKTOP_EOF'
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

%files
%defattr(-,root,root,-)
/usr/share/claude-installer/
/usr/bin/claude-installer
/usr/share/applications/claude-installer.desktop

%post
echo ""
echo "Claude Code Installer installed successfully!"
echo ""
echo "To install Claude Code, run:"
echo "  claude-installer"
echo ""

%preun
echo "Removing Claude Code Installer..."

%changelog
* Thu Feb 19 2026 Claude Installer Project <https://github.com/Buzigi/claude_installer> - 1.0.0-1
- Initial RPM package release
- Includes Claude Code CLI installer with GLM5 configuration
- Skills, agents, and templates included
