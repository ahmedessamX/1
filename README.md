# Unused Variables Fix Examples

This repository demonstrates how to identify and fix unused variables in Python code according to Codacy/SonarLint guidelines.

## Contents

- `.github/instructions/codacy.instructions.md` - Documentation explaining the issue and the fix
- `examples/noncompliant.py` - Code with unused variables (before fix)
- `examples/compliant.py` - Fixed code (after fix)

## The Issue

Unused local variables should be removed or used to avoid:
- Code clutter
- Confusion about intent
- Potential bugs from incomplete implementations

## The Fix

1. **Use the variable**: If a variable is assigned but not used, ensure it's used where intended
2. **Remove the variable**: If the variable is not needed, remove it
3. **Use underscore for intentionally unused**: For loop variables or other cases where a variable must be assigned but isn't needed, use `_` to indicate it's intentionally unused

See the [documentation](.github/instructions/codacy.instructions.md) and [examples](examples/) for details.