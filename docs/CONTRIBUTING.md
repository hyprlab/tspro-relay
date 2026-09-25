# Contributing

The conventions anyone editing this repository follows, human or AI. Bug
reports, ideas and pull requests are all welcome, and a clear bug report is
often as useful as a patch.

## Setting up

```sh
git config core.hooksPath tools/git-hooks     # once per clone or worktree
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
tools/redeploy.sh                             # relay + Mailpit on localhost
```

The hooks enforce the commit rules below and run the documentation check.
Without `core.hooksPath` they silently do nothing, so set it in every clone
and every worktree.

`tools/redeploy.sh` builds the image from the working tree and runs it with a
Mailpit sink ([the local test stack](DOCUMENTATION.md#local-end-to-end-test)),
so every message the relay sends can be read at http://127.0.0.1:8027. Try a
change there before calling it done.

## Commits

**The history is the maintainer's.** Commits carry no AI tool attribution: no
`Co-Authored-By:` line for Claude or any other assistant, no "Generated with"
footer, no session line, in a commit, a tag message, a pull request body or a
release body. The [AI notice](../README.md#ai-notice) declares how the project
is built, once, for the whole repository. One stray trailer puts the tool on
GitHub's Contributors panel, and removing it again means rewriting history
(this repository's history was rewritten for that reason on 2026-09-25).

A `Co-Authored-By:` trailer is still how a **person** is credited, with the
GitHub noreply address that resolves to their profile (see
[Credit](#credit)).

Subjects follow [Conventional Commits](https://www.conventionalcommits.org):
`type(area): summary`, lower case after the colon, imperative, no full stop,
72 characters at most and ideally nearer 50.

- Types: `feat`, `fix`, `perf`, `refactor`, `docs`, `build`, `ci`, `test`,
  `style`, `chore`, `revert`. A `!` after the type (`feat(api)!:`) marks a
  breaking change. The type is not decoration: `tools/next-version.sh` reads
  it to decide the next version ([RELEASING.md](RELEASING.md)).
- The area is where the change lives: `api`, `smtp`, `auth`, `settings`,
  `log`, `ui`, `db`, `docker`, `deps`, `docs`, `release`, `ci`. Leave it out
  only when there is no single place.
- A dependency bump that clears an advisory or fixes a bug is `fix(deps)`,
  since installs need it; one that changes nothing they see is `build(deps)`.
- An issue number goes at the end: `fix(api): reject an empty recipient list (#12)`.
- Releases: `chore(release): 0.3.0`.

The body is optional and short: why the change exists, never what the diff
already says. Past 100 words the detail belongs in `docs/` or `CHANGELOG.md`,
or the commit wants splitting. **Each body paragraph is one line, not
wrapped:** GitHub keeps every line break in a body, so text wrapped at 72
breaks a second time on a phone. Write it with `git commit -F -` and a heredoc.

No em dashes in commit messages: a colon, a comma or a full stop replaces
them.

`tools/git-hooks/commit-msg` refuses the attribution lines, em dashes, a
subject without a type, and an overlong subject or body. `pre-push` refuses to
publish any commit or tag carrying attribution.

## CLAUDE.md and .claude/

Both are local only: listed in `.git/info/exclude`, not `.gitignore`, so the
repository never names the tool. Never `git add -f` them; the `pre-commit`
hook refuses them. A new worktree does not get them: symlink `CLAUDE.md` into
it before working there.

## Prose style

Documentation, the changelog, release notes, UI text and issue replies:

- Factual, plain language. Say what the relay does, not what it enables you
  to do. No marketing, no superlatives, no "finally", no emoji.
- American spelling in anything the relay shows: color, behavior, canceled.
- Changelog lines describe the change from the operator's side. How it was
  built belongs in the commit.
- Comments in code explain *why*, not *what*.

## Documentation

The README is the front door and has a 200-line ceiling. Before writing a word
of documentation, decide where it goes: the table in
[docs/README.md](README.md) says. After touching any `.md`, run:

```sh
python3 tools/check-docs.py
```

It checks every relative link and anchor, that every `docs/*.md` is indexed,
that `docs/` holds Markdown only, the README's length, and the changelog's
shape and version.

Every user-visible change adds a line under `## Unreleased` in `CHANGELOG.md`.
Every release, patches included, gets a section. `CHANGELOG.md` is the only
release record: GitHub release bodies are generated from it.

## Code

- Match what is there: one `relay.py`, server-rendered templates, one
  `static/app.js`. JSON routes answer `{"ok": false, "error": "..."}`; errors
  from the upstream SMTP server stay out of API responses and go to the
  Transaction Log.
- Schema changes are additive: a new column is an `ALTER TABLE` in
  `init_db()`, guarded by a `PRAGMA table_info` check and tolerant of the
  "duplicate column name" race between gunicorn workers. A change an older
  version can't read back is a MAJOR release.
- Anything a user or API caller supplied is rendered with Jinja's escaping or
  `textContent`, never `|safe` or `innerHTML`. No inline scripts: the
  Content-Security-Policy forbids them.
- A new environment variable goes in `docker-compose.yml`, the README's
  compose example if every install needs it, and the table in
  [DOCUMENTATION.md](DOCUMENTATION.md#environment-variables). Renaming or
  removing one is a MAJOR release.
- Dependencies are pinned as a floor and a next-major ceiling. When auditing,
  install the requirements into a fresh venv and run `pip-audit` on what
  resolved: a stale ceiling can block a security fix.
- Run `tools/redeploy.sh` and try the change, sending through Mailpit where
  mail is involved, before saying it works.

## Credit

Outside pull requests land as commits on `main` made by the maintainer,
crediting the author with a trailer that uses their GitHub noreply address:

```
Co-Authored-By: Jane Doe <12345678+janedoe@users.noreply.github.com>
```

Get the id with `gh api users/<login> --jq .id`. An address taken from their
own commit may not be linked to their account, and then they never appear as a
contributor; that can't be fixed after a tagged release without rewriting
history.

Add them to [`CONTRIBUTORS`](../CONTRIBUTORS) (their name and `@login`) and
describe the work in [CREDITS.md](CREDITS.md). Close the pull request with a
comment saying what was taken, what changed and what was left out.

In release notes an `@` is for people whose code, art or translation is in the
release. Reporters and requesters are named without the `@`: an @ notifies
someone and reads as authorship. `tools/release-notes.sh` strips the @ from any
handle not in `CONTRIBUTORS`.

## Issue replies

Every reply to an issue or pull request written by an agent begins with
`*Agentic reply:*` in italics, then a blank line, then the reply.

- A reply saying something is done is one or two sentences: what changed from
  the operator's side, and which version carries it. How it was built is in
  the commit and the changelog.
- No thanks, no pleasantries, no em dashes. Plain, brief, human.
- Anything the user has to do (send a log, try something, check a setting) is
  a numbered list, one request per item.
- Reply once the image is pushed, not before, then close the issue.

```
*Agentic reply:*

Fixed in 0.3.0: a message with an empty recipient list is now refused with a 400 instead of reaching the SMTP server.

Update with `docker compose pull && docker compose up -d`.
```

Only a reply that asks for something or explains a decline runs longer.
