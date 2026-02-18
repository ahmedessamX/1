# Unused Local Variables

## Description
The fix for this issue is straightforward. Once you ensure the unused variable is not part of an incomplete implementation leading to bugs, you just need to remove it.

## Noncompliant Code Example

```python
def hello(name):
    message = "Hello " + name  # Noncompliant - message is unused
    print(name)

for i in range(10):  # Noncompliant - i is unused
    foo()
```

## Compliant Solution

```python
def hello(name):
    message = "Hello " + name
    print(message)

for _ in range(10):
    foo()
```

## Parameters

Following parameter values can be set in the SonarLint:Rules user settings. In connected mode, server side configuration overrides local settings.

### regex

Regular expression used to identify variable name to ignore.

**Default value:** `(_[a-zA-Z0-9_]*|dummy|unused|ignored)`
