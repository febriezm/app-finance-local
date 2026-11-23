---
name: auto-commit
description: >-
  Automate git staging, conventional commit message generation, pre-commit validation,
  and clean atomic commits. Use whenever the user asks to commit changes, auto commit,
  save progress to git, stage and commit, create meaningful commit messages, or when
  finishing a feature/bugfix and committing to source control.
---

# Auto Commit Skill

Standardized, intelligent Git commit workflow that inspects working tree changes, validates code health, drafts semantic Conventional Commit messages, and commits changes atomically.

---

## Quick Start / Procedure

When instructed to commit or auto-commit:

1. **Check Status & Diffs**:
   ```powershell
   git status --short
   git diff --stat
   ```

2. **Run Pre-Commit Verification**:
   - Ensure no temporary scratch or debug files are staged (e.g., temporary scripts, logs).
   - If Dart/Flutter project, verify analyzer passes:
     ```powershell
     & "C:\laragon\puro\envs\stable\flutter\bin\flutter.bat" analyze
     ```

3. **Stage Modified & Untracked Files**:
   - Stage tracked and new project files:
     ```powershell
     git add -A
     ```
   - If files should be excluded (e.g. temporary scratch files), unstage them:
     ```powershell
     git reset HEAD <unwanted-file>
     ```

4. **Construct Conventional Commit Message**:
   Follow the format:
   ```
   <type>(<scope>): <short imperative description>

   [optional body with details/bullets]
   ```
   Refer to [Conventional Commits Reference](./references/conventional_commits.md) for taxonomy.

5. **Execute Commit**:
   ```powershell
   git commit -m "<type>(<scope>): <summary>"
   ```
   Or for multi-line commits:
   ```powershell
   git commit -m "<type>(<scope>): <summary>" -m "<bullet 1>" -m "<bullet 2>"
   ```

6. **Verify Commit**:
   ```powershell
   git log -1 --stat
   git status
   ```

---

## Automated Script Helper

A dedicated Python script is available to inspect changes and execute commits automatically:

```powershell
& "C:\laragon\bin\python\python-3.10\python.exe" .agents\skills\auto-commit\scripts\auto_commit.py
```

### Script Flags:
- `--dry-run`: Preview staged files and generated commit message without committing.
- `-m, --message "..."`: Override message while maintaining automatic staging.
- `--no-verify`: Skip `flutter analyze` pre-check.
- `--push`: Automatically push to `origin <current-branch>` after committing.

---

## Commit Taxonomy Rules

| Type | When to Use | Example |
| :--- | :--- | :--- |
| **`feat`** | New user-facing feature or screen | `feat(security): add 6-digit PIN app lock and WebAuthn biometrics` |
| **`fix`** | Bug fix, crash prevention, or regression fix | `fix(database): add auto-migration for app_settings table to resolve minified:aX` |
| **`style`** | UI/UX polish, theme, colors, typography, paddings | `style(budgets): fix bottom category overlap when numeric keyboard appears` |
| **`refactor`**| Code refactoring without behavior changes | `refactor(storage): introduce ResilientWebStorage wrapper for Safari IndexedDB` |
| **`perf`** | Performance enhancement, query optimization | `perf(wallets): optimize reactive balance stream calculations` |
| **`test`** | Adding or correcting unit/widget/integration tests | `test(app-lock): add unit tests for PIN hashing and biometric fallback` |
| **`chore`** | Build setup, dependencies, scripts, git configs | `chore(build): update post_build script and asset synchronization` |
| **`docs`** | Documentation, blueprints, comments | `docs(readme): update local preview instructions for iOS Safari` |

---

## Guardrails & Best Practices

1. **Never commit secrets**: Check that `.env`, API keys, or private tokens are not staged.
2. **Never commit broken code**: Always run `flutter analyze` before committing.
3. **Atomic commits**: Group related changes together. Avoid mega-commits that combine unrelated refactorings with feature work.
4. **Imperative mood**: Write `"add feature"`, `"fix bug"`, not `"added"` or `"fixes"`.
5. **No empty commits**: Verify `git status` has actual changes before running `git commit`.
