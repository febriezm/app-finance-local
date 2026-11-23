#!/usr/bin/env python3
"""
Auto Commit Utility for Antigravity & MyFinance Project
Analyzes git working tree, drafts conventional commit messages, runs pre-checks,
and commits changes cleanly.
"""

import argparse
import os
import subprocess
import sys

def run_command(cmd, check=True):
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, shell=True)
    if check and result.returncode != 0:
        print(f"Error running command: {cmd}\n{result.stderr.strip()}")
        sys.exit(result.returncode)
    return result.stdout.strip(), result.stderr.strip(), result.returncode

def get_git_status():
    stdout, _, _ = run_command("git status --porcelain")
    if not stdout:
        return []
    lines = stdout.splitlines()
    changes = []
    for line in lines:
        if len(line) >= 3:
            status = line[:2]
            filepath = line[2:].strip()
            changes.append((status, filepath))
    return changes

def determine_type_and_scope(changes):
    files = [filepath for _, filepath in changes]
    
    # Check scopes
    scopes = set()
    for f in files:
        f_lower = f.lower()
        if "security" in f_lower or "app_lock" in f_lower or "pin" in f_lower:
            scopes.add("security")
        elif "database" in f_lower or "daos" in f_lower or "tables" in f_lower or "sqlite" in f_lower:
            scopes.add("database")
        elif "budget" in f_lower:
            scopes.add("budgets")
        elif "wallet" in f_lower:
            scopes.add("wallets")
        elif "transaction" in f_lower:
            scopes.add("transactions")
        elif "report" in f_lower:
            scopes.add("reports")
        elif "receipt" in f_lower or "ocr" in f_lower:
            scopes.add("receipt-scanner")
        elif "backup" in f_lower or "restore" in f_lower:
            scopes.add("backup")
        elif "skill" in f_lower or ".agent" in f_lower:
            scopes.add("skills")
        elif "web" in f_lower or "build" in f_lower or "pubspec" in f_lower:
            scopes.add("build")

    scope = next(iter(scopes)) if len(scopes) == 1 else "core" if len(scopes) > 1 else "general"

    # Check commit type
    all_tests = all("test" in f.lower() for f in files)
    all_docs = all(f.lower().endswith(".md") or "doc" in f.lower() for f in files)
    has_skills = any("skills" in f.lower() for f in files)
    
    diff_out, _, _ = run_command("git diff -U0", check=False)
    diff_lower = diff_out.lower()
    
    if all_tests:
        c_type = "test"
    elif all_docs:
        c_type = "docs"
    elif has_skills:
        c_type = "feat"
    elif any(k in diff_lower for k in ["fix", "error", "catch", "bug", "crash", "fallback"]):
        c_type = "fix"
    elif any(status == "??" for status, _ in changes):
        c_type = "feat"
    else:
        c_type = "refactor"

    return c_type, scope

def generate_default_message(changes):
    c_type, scope = determine_type_and_scope(changes)
    
    files = [filepath for _, filepath in changes]
    file_count = len(files)
    
    if scope == "skills":
        summary = "add auto-commit skill and automated git workflow"
    elif scope == "security":
        summary = "update app lock security, WebAuthn biometrics, and PIN verification"
    elif scope == "database":
        summary = "update database schema, auto-migrations, and DAO accessors"
    elif scope == "budgets":
        summary = "update budget limits allocation and UI layout"
    elif scope == "wallets":
        summary = "update wallet management and balance calculations"
    else:
        summary = f"update {scope} components across {file_count} files"

    return f"{c_type}({scope}): {summary}"

def main():
    parser = argparse.ArgumentParser(description="Auto commit staged/unstaged changes with conventional messages.")
    parser.add_argument("-m", "--message", help="Commit message override")
    parser.add_argument("--dry-run", action="store_true", help="Preview commit without applying")
    parser.add_argument("--push", action="store_true", help="Push to remote after commit")
    parser.add_argument("--no-verify", action="store_true", help="Skip flutter analyze")
    args = parser.parse_args()

    changes = get_git_status()
    if not changes:
        print("[AutoCommit] Working tree is completely clean. Nothing to commit.")
        return

    print(f"[AutoCommit] Detected {len(changes)} modified/untracked files:")
    for status, filepath in changes:
        print(f"  {status.ljust(2)} {filepath}")

    commit_msg = args.message if args.message else generate_default_message(changes)
    print(f"\n[AutoCommit] Generated Commit Message:")
    print(f"  {commit_msg}")

    if args.dry_run:
        print("\n[AutoCommit] Dry run active. Exiting without staging or committing.")
        return

    if not args.no_verify:
        flutter_bat = r"C:\laragon\puro\envs\stable\flutter\bin\flutter.bat"
        if os.path.exists(flutter_bat):
            print("\n[AutoCommit] Running flutter analyze verification...")
            out, err, code = run_command(f'"{flutter_bat}" analyze', check=False)
            if code != 0:
                print(f"[AutoCommit] Flutter analyze reported issues:\n{out or err}")
                sys.exit(code)
            print("[AutoCommit] Flutter analyze passed cleanly (0 issues)!")

    print("\n[AutoCommit] Staging files (git add -A)...")
    run_command("git add -A")

    print(f"[AutoCommit] Committing with message: {commit_msg}")
    escaped_msg = commit_msg.replace('"', '\\"')
    run_command(f'git commit -m "{escaped_msg}"')

    log_out, _, _ = run_command("git log -1 --oneline")
    print(f"\n[AutoCommit] Successfully committed: {log_out}")

    if args.push:
        print("\n[AutoCommit] Pushing changes to origin...")
        push_out, push_err, p_code = run_command("git push", check=False)
        if p_code == 0:
            print("[AutoCommit] Successfully pushed to remote repository!")
        else:
            print(f"[AutoCommit] Push notice:\n{push_err or push_out}")

if __name__ == "__main__":
    main()
