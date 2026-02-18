"""
This file contains noncompliant code examples with unused variables.
These should be fixed according to the guidelines.
"""


def hello(name):
    message = "Hello " + name  # Noncompliant - message is unused
    print(name)


def foo():
    print("foo called")


for i in range(10):  # Noncompliant - i is unused
    foo()
