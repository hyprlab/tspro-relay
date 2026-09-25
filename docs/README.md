# Documentation

The README is the front door. Everything else lives here, and every file in
this directory is listed below; `tools/check-docs.py` fails if one is not.

| File | What is in it |
| --- | --- |
| [DOCUMENTATION.md](DOCUMENTATION.md) | TLS, connecting the TSP app, environment variables, upgrading, the local test stack |
| [API.md](API.md) | The JSON API the TSP portal calls |
| [SECURITY.md](SECURITY.md) | What the relay defends against, the operator checklist, and how to report a problem |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Commits, prose style, code, credit, issue replies |
| [RELEASING.md](RELEASING.md) | SemVer and the release procedure |
| [CREDITS.md](CREDITS.md) | Who contributed what |

## Where a new piece of documentation goes

| What you have | Where it goes |
| --- | --- |
| Something every new operator needs to get running | The README's install steps, only if it can't wait until after the first start |
| How to set something up, configure or run it | [DOCUMENTATION.md](DOCUMENTATION.md) |
| A change to the API the TSP app calls | [API.md](API.md) |
| A defense, a security caveat, or an operator duty | [SECURITY.md](SECURITY.md) |
| A convention for anyone editing the repository | [CONTRIBUTING.md](CONTRIBUTING.md) |
| A change to how releases are made | [RELEASING.md](RELEASING.md) |
| Credit for somebody's work | [`CONTRIBUTORS`](../CONTRIBUTORS) for the name, [CREDITS.md](CREDITS.md) for the work |
| What changed in a release | [CHANGELOG.md](../CHANGELOG.md) |

A new `docs/*.md` must be added to the first table and linked from somewhere
it will be found. `docs/` holds Markdown only.
