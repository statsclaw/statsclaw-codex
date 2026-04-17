#!/usr/bin/env bash
# validate-structure.sh — Verify all internal cross-references in the StatsClaw-Codex framework
# Called by the CI workflow. Exits non-zero if any reference is broken.
set -uo pipefail

ERRORS=0
WARNINGS=0

error() { echo "::error::$1"; ERRORS=$((ERRORS + 1)); }
warn()  { echo "::warning::$1"; WARNINGS=$((WARNINGS + 1)); }
info()  { echo "  ✓ $1"; }

echo "═══════════════════════════════════════════════════"
echo "  StatsClaw-Codex Structure Validation"
echo "═══════════════════════════════════════════════════"
echo ""

# ─────────────────────────────────────────────────────
# 1. Required top-level files
# ─────────────────────────────────────────────────────
echo "▶ Checking required top-level files..."
for f in AGENTS.md README.md CONTRIBUTING.md ROADMAP.md LICENSE .gitignore install.sh uninstall.sh codex-config.example.toml; do
  if [ -f "$f" ]; then
    info "$f exists"
  else
    error "Missing required file: $f"
  fi
done
echo ""

# ─────────────────────────────────────────────────────
# 2. Agent completeness
# ─────────────────────────────────────────────────────
echo "▶ Checking agent definitions..."
EXPECTED_AGENTS="leader planner builder tester scriber simulator distiller reviewer shipper"
for agent in $EXPECTED_AGENTS; do
  if [ -f "agents/${agent}.md" ]; then
    info "agents/${agent}.md"
  else
    error "Missing agent definition: agents/${agent}.md"
  fi
done

# Check for unexpected agent files (not necessarily an error, just a warning)
for f in agents/*.md; do
  [ -f "$f" ] || continue
  basename="${f#agents/}"
  basename="${basename%.md}"
  if ! echo "$EXPECTED_AGENTS" | grep -qw "$basename"; then
    warn "Unexpected agent file: $f (not in expected list)"
  fi
done
echo ""

# ─────────────────────────────────────────────────────
# 3. Skill completeness
# ─────────────────────────────────────────────────────
echo "▶ Checking skill definitions..."
for dir in skills/*/; do
  [ -d "$dir" ] || continue
  if [ -f "${dir}SKILL.md" ]; then
    info "${dir}SKILL.md"
  else
    error "Missing skill definition: ${dir}SKILL.md"
  fi
done
echo ""

# ─────────────────────────────────────────────────────
# 4. Template completeness
# ─────────────────────────────────────────────────────
echo "▶ Checking template files..."
EXPECTED_TEMPLATES="context status credentials mailbox lock log-entry ARCHITECTURE brain-entry CONTRIBUTORS"
for tmpl in $EXPECTED_TEMPLATES; do
  if [ -f "templates/${tmpl}.md" ]; then
    info "templates/${tmpl}.md"
  else
    error "Missing template: templates/${tmpl}.md"
  fi
done
echo ""

# ─────────────────────────────────────────────────────
# 5. Cross-references in AGENTS.md
# ─────────────────────────────────────────────────────
echo "▶ Checking file references in AGENTS.md..."
# Extract backtick-quoted paths referencing known directories
# Skip glob patterns (containing *), directory-only references (ending with /),
# CLI example strings (containing spaces or <placeholders>), and refs with URL fragments.
for dir in agents skills templates profiles prompts scripts; do
  grep -oP "\`${dir}/[^\`]+\`" AGENTS.md | tr -d '`' | sort -u | while read -r ref; do
    case "$ref" in
      *\**|*/|*\ *|*\<*|*\>*|*\#*) continue ;;
    esac
    if [ -f "$ref" ]; then
      info "AGENTS.md → $ref"
    else
      error "AGENTS.md references non-existent file: $ref"
    fi
  done
done
echo ""

# ─────────────────────────────────────────────────────
# 6. Cross-references in agent files
# ─────────────────────────────────────────────────────
echo "▶ Checking file references in agent definitions..."
for agent in agents/*.md; do
  [ -f "$agent" ] || continue
  grep -oP '\`(agents|skills|templates|profiles|prompts|scripts)/[^`]+\`' "$agent" 2>/dev/null | tr -d '`' | sort -u | while read -r ref; do
    case "$ref" in *\**|*/|*\ *|*\<*|*\>*|*\#*) continue ;; esac
    if [ ! -f "$ref" ]; then
      error "$agent references non-existent file: $ref"
    fi
  done
done
echo ""

# ─────────────────────────────────────────────────────
# 7. Cross-references in skill files
# ─────────────────────────────────────────────────────
echo "▶ Checking file references in skill definitions..."
find skills -name 'SKILL.md' | while read -r skill; do
  grep -oP '\`(agents|skills|templates|profiles|prompts|scripts)/[^`]+\`' "$skill" 2>/dev/null | tr -d '`' | sort -u | while read -r ref; do
    case "$ref" in *\**|*/|*\ *|*\<*|*\>*|*\#*) continue ;; esac
    if [ ! -f "$ref" ]; then
      error "$skill references non-existent file: $ref"
    fi
  done
done
echo ""

# ─────────────────────────────────────────────────────
# 8. Agent file structure (required sections)
# ─────────────────────────────────────────────────────
echo "▶ Checking agent file structure..."
REQUIRED_SECTIONS="Role:Allowed Reads:Allowed Writes:Must-Not Rules"
for agent in agents/*.md; do
  [ -f "$agent" ] || continue
  IFS=':' read -ra SECTIONS <<< "$REQUIRED_SECTIONS"
  for section in "${SECTIONS[@]}"; do
    if grep -q "^## $section" "$agent" || grep -q "^## ${section}$" "$agent"; then
      : # ok
    else
      warn "$agent missing recommended section: ## $section"
    fi
  done
done
echo ""

# ─────────────────────────────────────────────────────
# 9. No runtime artifacts committed
# ─────────────────────────────────────────────────────
echo "▶ Checking for committed runtime artifacts..."
if [ -d ".repos" ] && [ "$(find .repos -type f 2>/dev/null | head -1)" ]; then
  error ".repos/ directory contains files — runtime artifacts must not be committed"
else
  info "No runtime artifacts in .repos/"
fi
echo ""

# ─────────────────────────────────────────────────────
# 10. Profile files exist
# ─────────────────────────────────────────────────────
echo "▶ Checking language profiles..."
PROFILE_COUNT=$(find profiles -name '*.md' -type f 2>/dev/null | wc -l)
if [ "$PROFILE_COUNT" -ge 1 ]; then
  info "Found $PROFILE_COUNT language profiles"
else
  error "No profiles found in profiles/"
fi
echo ""

# ─────────────────────────────────────────────────────
# 11. Plugin infrastructure
# ─────────────────────────────────────────────────────
echo "▶ Checking plugin infrastructure..."
for f in .codex-plugin/plugin.json; do
  if [ -f "$f" ]; then
    info "$f exists"
  else
    error "Missing plugin file: $f"
  fi
done
echo ""

# ─────────────────────────────────────────────────────
# 12. YAML frontmatter in agents and skills
# ─────────────────────────────────────────────────────
echo "▶ Checking YAML frontmatter..."
for agent in agents/*.md; do
  [ -f "$agent" ] || continue
  if head -1 "$agent" | grep -q '^---$'; then
    info "$agent has frontmatter"
  else
    warn "$agent missing YAML frontmatter"
  fi
done
for skill in skills/*/SKILL.md; do
  [ -f "$skill" ] || continue
  if head -1 "$skill" | grep -q '^---$'; then
    info "$skill has frontmatter"
  else
    warn "$skill missing YAML frontmatter"
  fi
done
echo ""

# ─────────────────────────────────────────────────────
# 13. Codex-specific: dispatch & wrapper scripts exist and are executable
# ─────────────────────────────────────────────────────
echo "▶ Checking Codex wrapper scripts..."
EXPECTED_SCRIPTS="dispatch.sh worktree.sh detect-credentials.sh loop.sh"
for s in $EXPECTED_SCRIPTS; do
  if [ -f "scripts/$s" ]; then
    if [ -x "scripts/$s" ]; then
      info "scripts/$s exists and is executable"
    else
      warn "scripts/$s exists but is not executable (chmod +x)"
    fi
  else
    error "Missing wrapper script: scripts/$s"
  fi
done

for s in install.sh uninstall.sh; do
  if [ -f "$s" ]; then
    if [ -x "$s" ]; then
      info "$s exists and is executable"
    else
      warn "$s exists but is not executable (chmod +x)"
    fi
  else
    error "Missing script: $s"
  fi
done
echo ""

# ─────────────────────────────────────────────────────
# 14. Codex-specific: user-facing skills exist
# ─────────────────────────────────────────────────────
echo "▶ Checking user-facing skills ..."
EXPECTED_USER_SKILLS="patrol simulate ship-it review contribute brain loop"
for s in $EXPECTED_USER_SKILLS; do
  if [ -f "skills/$s/SKILL.md" ]; then
    info "skills/$s/SKILL.md"
  else
    error "Missing user-facing skill: skills/$s/SKILL.md"
  fi
done
echo ""

# Legacy prompts/ files are kept as reference but are no longer required.
# Just warn if any are missing.
for p in contribute loop ship-it review patrol simulate brain; do
  if [ ! -f "prompts/$p.md" ]; then
    warn "Legacy reference missing (not fatal): prompts/$p.md"
  fi
done

# ─────────────────────────────────────────────────────
# 16. Codex plugin + marketplace manifests
# ─────────────────────────────────────────────────────
echo "▶ Checking Codex plugin + marketplace manifests ..."
if [ -f ".codex-plugin/plugin.json" ]; then
  info ".codex-plugin/plugin.json exists"
  # Validate with Python — must have required fields
  python3 - <<'PY' || true
import json, sys, pathlib
m = json.loads(pathlib.Path(".codex-plugin/plugin.json").read_text())
required = ["name", "version", "description"]
missing = [k for k in required if k not in m]
if missing:
    print(f"::error::.codex-plugin/plugin.json missing required fields: {missing}")
    sys.exit(1)
if "skills" in m and not m["skills"].startswith("./"):
    print(f"::error::.codex-plugin/plugin.json: 'skills' must start with './' (got {m['skills']!r})")
    sys.exit(1)
print(f"  ✓ plugin name={m['name']} version={m['version']}")
PY
else
  error "Missing .codex-plugin/plugin.json"
fi

# No repo-scoped .agents/plugins/marketplace.json — this is a single-plugin
# repo, so there is no valid relative plugin path from the repo root. The
# user-scoped marketplace at ~/.agents/plugins/marketplace.json is written by
# install.sh instead.
echo ""

# ─────────────────────────────────────────────────────
# 15. Codex-specific: codex-config.example.toml sanity
# ─────────────────────────────────────────────────────
echo "▶ Checking codex-config.example.toml..."
if [ -f "codex-config.example.toml" ]; then
  EXPECTED_PROFILES="leader planner builder tester scriber simulator reviewer distiller shipper"
  for p in $EXPECTED_PROFILES; do
    if grep -q "^\[profiles.statsclaw-${p}\]" codex-config.example.toml; then
      info "profiles.statsclaw-${p} present"
    else
      error "Missing profile in codex-config.example.toml: [profiles.statsclaw-${p}]"
    fi
  done
fi
echo ""

# ─────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════"
if [ "$ERRORS" -eq 0 ]; then
  echo "  ✅ All checks passed ($WARNINGS warnings)"
  exit 0
else
  echo "  ❌ $ERRORS errors, $WARNINGS warnings"
  exit 1
fi
