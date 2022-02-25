---
name: Bug report
about: Create a report to help us improve
---

## Bug description

Please describe clearly and concisely what the bug is.
Also mention the expected behavior (what you expected to happen but didn't).

## Steps to reproduce

Describe a sequence of steps to reproduce the behavior, ideally in the form of a
self-contained, copy-pasteable block of code.
This code should not depend on external variables available in your session and
should minimize the use of external packages.
If possible, use dummy inline data, e.g.`df = (x=[1, 2], y=[3, 4], c=["a", "b"])`,
instead of attaching a file with the dataset you were using when the problem occurred.

## Error reporting

If the bug is an unexpected error, please include the error message and the
entirety of the stack trace.

## Images

If applicable, add images of the plots you obtained to help explain your problem.

## Version info

Please include the output of `versioninfo()` and `Pkg.status()` for the environment
where the issue occurred.

## Before opening an issue

Make sure you are on the latest release of AlgebraOfGraphics and Makie.
Make sure no other issue exists describing the same problem you have encountered.
