# Claude Code Installer - Project Structure

## Directory Layout

```
claude-installer/
├── Install-ClaudeCode.ps1          # Main installation script
├── Verify-Installation.ps1          # Installation verification script
├── Update-Skills.ps1                # Skills update script
├── README.md                        # Main documentation
│
├── config/                          # Configuration files
│   ├── glm5-config.json            # GLM5 model configuration
│   ├── skills-repository.json      # Skills manifest
│   └── agents-manifest.json        # Agents manifest
│
├── skills/                          # Skills to install
│   ├── git-workflow/               # Git workflow skill
│   │   ├── .skillfish.json         # Skill metadata
│   │   └── SKILL.md                # Skill documentation
│   └── ...                         # Additional skills
│
├── agents/                          # Agents to install
│   ├── task-manager-agent.md       # Task orchestrator
│   ├── project-navigator-agent.md  # Code navigator
│   └── software-architect.md       # System architect
│
├── templates/                       # Configuration templates
│   ├── settings.json.template      # Main settings template
│   └── settings.local.json.template # Local settings template
│
└── docs/                            # Documentation
    ├── INSTALLATION.md             # Installation guide
    ├── CONFIGURATION.md            # Configuration guide
    ├── TROUBLESHOOTING.md          # Troubleshooting guide
    ├── MULTI-AGENT-COORDINATION-PLAN.md # Agent coordination
    └── PROJECT-STRUCTURE.md        # This file
```

## File Descriptions

### Installation Scripts

#### Install-ClaudeCode.ps1
Main installation script that:
- Installs Claude Code CLI via npm
- Creates configuration files
- Installs skills and agents
- Configures MCP servers
- Sets up self-referential capabilities
- Runs verification tests

**Parameters:**
- `-Model`: Model to configure (default: glm5)
- `-InstallPath`: Installation directory (default: user home)
- `-SkillsPath`: Skills directory (default: .claude/skills)
- `-AgentsPath`: Agents directory (default: .claude/agents)
- `-SkipCLI`: Skip CLI installation
- `-IncludeMCP`: Include MCP server configuration

#### Verify-Installation.ps1
Verification script that checks:
- Claude CLI availability
- Configuration files
- Skills installation
- Agents installation
- MCP server configuration
- Dependencies (Node.js, npm)

#### Update-Skills.ps1
Updates installed skills from their Git repositories.

### Configuration Files

#### config/glm5-config.json
GLM5 model configuration including:
- API endpoints
- Model parameters
- Skill configuration
- Agent configuration
- Permissions
- UI preferences

#### config/skills-repository.json
Manifest of all available skills including:
- Skill metadata
- Dependencies
- Tags and categories
- Installation paths

#### config/agents-manifest.json
Manifest of all available agents including:
- Agent categorization
- Core agents list
- Optional agents list
- File locations

### Skills

#### skills/git-workflow/
Comprehensive Git workflow management skill covering:
- Branching strategies (Git Flow, Trunk-Based, GitHub Flow)
- Common workflows (feature, hotfix, release)
- Advanced operations (rebase, cherry-pick, squash)
- Automation (hooks, aliases)
- Best practices

### Agents

#### agents/task-manager-agent.md
Central orchestrator agent that:
- Analyzes requirements
- Coordinates other agents
- Creates task breakdowns
- Tracks dependencies
- Manages execution sequence

#### agents/project-navigator-agent.md
Project structure expert that:
- Analyzes project layout
- Locates relevant code
- Maps dependencies
- Identifies patterns
- Provides context

#### agents/software-architect.md
System design specialist that:
- Designs architecture
- Plans integrations
- Considers scalability
- Makes tech recommendations
- Documents decisions

### Templates

#### templates/settings.json.template
Template for main Claude Code settings.

#### templates/settings.local.json.template
Template for local/project-specific settings.

### Documentation

#### README.md
Main project documentation with:
- Feature overview
- Installation instructions
- Configuration guide
- Usage examples
- Troubleshooting links

#### docs/INSTALLATION.md
Detailed installation guide including:
- Prerequisites
- Installation methods
- Step-by-step instructions
- Post-configuration
- Verification steps

#### docs/CONFIGURATION.md
Comprehensive configuration guide covering:
- Configuration files
- Model configuration
- Skills management
- Agents management
- Permissions
- MCP servers
- Advanced settings

#### docs/TROUBLESHOOTING.md
Troubleshooting guide with:
- Common issues and solutions
- Error message explanations
- Debug techniques
- Support resources

#### docs/MULTI-AGENT-COORDINATION-PLAN.md
Agent coordination documentation:
- Agent roles and responsibilities
- Coordination patterns
- Handoff protocols
- Self-referential capabilities
- Quality assurance

## Installation Targets

### Files Created by Installer

```
~/.claude/
├── settings.json                   # Main configuration
├── settings.local.json             # Local overrides
├── skills/                         # Installed skills
│   ├── drawio/                    # Diagram creation
│   ├── git-workflow/              # Git automation
│   ├── claude-installer/          # Self-referential
│   └── ...                        # More skills
└── agents/                         # Installed agents
    ├── task-manager-agent.md      # Orchestration
    ├── project-navigator-agent.md # Navigation
    ├── software-architect.md      # Architecture
    └── ...                        # More agents
```

## Key Features

### 1. Automated Installation
- Single command installation
- Interactive prompts
- Error handling
- Progress indicators

### 2. GLM5 Configuration
- Pre-configured for GLM5 model
- Optimized parameters
- API endpoint setup

### 3. Skills Repository
- 10+ built-in skills
- Easy skill addition
- Metadata tracking
- Update mechanism

### 4. Agent Suite
- 44+ specialized agents
- Categorized by domain
- Core and optional agents
- Easy agent management

### 5. Self-Referential
- Can create new skills
- Can modify agents
- Can improve itself
- Meta-capabilities

### 6. MCP Integration
- Chrome DevTools support
- File system access
- Git operations
- Extensible architecture

## Usage Patterns

### Basic Usage

```powershell
# Quick install
.\Install-ClaudeCode.ps1

# Verify installation
.\Verify-Installation.ps1

# Update skills
.\Update-Skills.ps1
```

### Advanced Usage

```powershell
# Custom configuration
.\Install-ClaudeCode.ps1 -Model glm5 -SkillsPath "C:\Skills"

# Skip CLI installation
.\Install-ClaudeCode.ps1 -SkipCLI

# Include MCP servers
.\Install-ClaudeCode.ps1 -IncludeMCP
```

### Post-Installation

```bash
# Start Claude Code
claude

# Use GLM5 model
claude --model glm5

# Use a skill
claude --skill git-workflow "Create a feature branch"

# Use an agent
claude --agent task-manager "Plan a new feature"
```

## Development Workflow

### Adding New Skills

1. Create skill directory in `skills/`
2. Add `.skillfish.json` metadata
3. Create `SKILL.md` documentation
4. Update `config/skills-repository.json`
5. Test installation

### Adding New Agents

1. Create agent file in `agents/`
2. Follow agent file format
3. Update `config/agents-manifest.json`
4. Test agent functionality

### Updating Documentation

1. Update relevant doc file
2. Keep examples current
3. Update table of contents
4. Test instructions

## Maintenance

### Regular Tasks

1. **Update Skills**: Run `Update-Skills.ps1`
2. **Update Agents**: Pull from repositories
3. **Review Logs**: Check `.claude/debug/`
4. **Clean Cache**: Remove old cache files

### Version Management

1. **Tag Releases**: Use semantic versioning
2. **Update Changelog**: Document changes
3. **Test Upgrades**: Verify upgrade path
4. **Backup Configs**: Save user settings

## Support

### Getting Help

1. **Documentation**: Check `docs/` directory
2. **Troubleshooting**: See `TROUBLESHOOTING.md`
3. **Issues**: Report on GitHub
4. **Community**: Join Discord/Slack

### Contributing

1. **Fork Repository**: Create your fork
2. **Create Branch**: Use feature branches
3. **Make Changes**: Follow patterns
4. **Test Thoroughly**: Verify functionality
5. **Submit PR**: Include documentation

## Architecture

### Component Interaction

```
User → Installer Script → Claude CLI
                          ↓
                    Configuration Files
                          ↓
                    Skills & Agents
                          ↓
                    MCP Servers
```

### Self-Referential Loop

```
Installer → Claude Code → Skill: claude-installer
                          ↓
                    Create/Modify Skills/Agents
                          ↓
                    Update Installer
                          ↓
                    Improved Installer
```

## Future Enhancements

### Planned Features

1. **GUI Installer**: Visual installation interface
2. **Auto-Updater**: Automatic update mechanism
3. **Skill Marketplace**: Browse and install skills
4. **Agent Templates**: Quick agent creation
5. **Backup/Restore**: Configuration backup system
6. **Health Monitoring**: Installation health checks

### Community Contributions

We welcome contributions for:
- New skills
- New agents
- Documentation improvements
- Bug fixes
- Feature requests

## License

MIT License - See LICENSE file for details

## Credits

Built with:
- Claude Code CLI
- GLM5 Model
- PowerShell
- Community contributions

---

**Last Updated**: 2025-02-16
**Version**: 1.0.0
**Project**: Claude Code Installer - GLM5 Edition
