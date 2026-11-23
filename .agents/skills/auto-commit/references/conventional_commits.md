# Conventional Commits Reference Guide

This document defines the commit message conventions used across the project to maintain a clean, semantic Git history.

---

## 1. Commit Structure

```text
<type>(<scope>): <summary in imperative mood>

[optional body: explanation of why the change was made]

[optional footer: closes #123, breaking changes, etc.]
```

### Constraints:
- **Header Line**: Limit to 72 characters.
- **Case**: Lowercase type and scope. Summary starts with lowercase or lowercase keyword.
- **Punctuation**: No period at the end of the summary line.
- **Mood**: Imperative ("add", "fix", "update", "refactor").

---

## 2. Common Scopes in MyFinance

- `security`: App Lock, PIN, biometrics, WebAuthn, Secure Enclave.
- `database`: Drift SQLite, tables, DAOs, migrations, `AppDatabase`.
- `wallets`: Wallet management, balances, ledger, transfers.
- `transactions`: Mutasi, categories, expense/income entry sheets.
- `budgets`: Monthly budgeting, category limits, alerts.
- `reports`: Financial reports, cashflow charts, PDF & CSV export.
- `receipt-scanner`: OCR, camera, Tesseract, receipt drafts.
- `backup`: JSON backup, export, import, restore validation.
- `ui`: App theme, Apple design tokens, navigation, Cupertino widgets.
- `build`: Flutter Web, canvaskit, WASM, post_build, server scripts.

---

## 3. Examples

### Good:
```text
fix(security): resolve minified:aX crash on Safari iPhone via auto-migration

- Add CREATE TABLE IF NOT EXISTS in beforeOpen for app_settings and budget_category_limits
- Bump schemaVersion to 2 with defensive onUpgrade handler
- Wrap AppLockController.init in try/catch to guard unawaited async startup
```

```text
feat(security): add 6-digit PIN keypad with Apple design styling

- Implement PinKeypad and PinDotsIndicator with fluid haptic feedback
- Store salted SHA-256 hash locally in SQLite app_settings
- Support WebAuthn platform authenticator with graceful PIN fallback
```

### Bad:
- `update stuff` *(Vague, no type or scope)*
- `fixed bugs and made it work` *(Past tense, non-conventional)*
- `WIP` *(Non-descriptive)*
