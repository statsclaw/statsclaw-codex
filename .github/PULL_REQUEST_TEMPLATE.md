## What does this PR do?

<!-- Briefly describe the change -->

## Related issues

<!-- Link to related issues: Fixes #123, Relates to #456 -->

## Type of change

- [ ] Bug fix
- [ ] New feature / enhancement
- [ ] New language profile
- [ ] New skill
- [ ] Dispatch / wrapper script (`scripts/`)
- [ ] Slash command prompt (`prompts/`)
- [ ] Installer (`install.sh` / `uninstall.sh` / `codex-config.example.toml`)
- [ ] Documentation
- [ ] Upstream sync (pulling a change from `statsclaw/statsclaw`)
- [ ] Brain system (knowledge sharing, distiller, privacy scrub)
- [ ] Other: <!-- describe -->

## Checklist

- [ ] I've read the [Contributing Guide](../CONTRIBUTING.md)
- [ ] Changes are focused on a single concern
- [ ] I've tested with Codex CLI (if applicable)
- [ ] Existing functionality is not broken
- [ ] If this syncs a protocol/skill/agent change from upstream, I've re-applied the Codex primitive substitutions (`Agent` → `scripts/dispatch.sh`, `AskUserQuestion` → numbered-options markdown, `Skill` tool → file reference, `${CLAUDE_PLUGIN_ROOT}` → `${STATSCLAW_CODEX_ROOT}`)
- [ ] If this touches a file that is **shared verbatim with upstream** (profiles, templates, brain-entry schemas), I've opened a paired PR on `statsclaw/statsclaw`
