# Releasing

How versions are numbered, when releases happen, and the exact steps. The
policy is the one Hyprlab's other projects follow, without their beta channel:
the relay has a single consumer and a small surface, so every release is a
stable one.

## Versions: strict SemVer

Every release follows [Semantic Versioning 2.0.0](https://semver.org/). The
relay's "public API" is whatever an existing install and the TSP portal depend
on: the JSON API and its responses, the environment variables, the data
volume, the port, and the admin interface's features.

| Bump | When | Examples |
| --- | --- | --- |
| **MAJOR** | Anything an existing install or the TSP portal can't take without help | A changed or removed field or status code in the API; a schema change an older version can't read back; a renamed or removed environment variable; a new required one; a changed volume path or port |
| **MINOR** | New, backward-compatible functionality, or a deprecation | A new endpoint or optional API field; a new setting; a new optional environment variable |
| **PATCH** | Backward-compatible fixes only | A bug fix, a performance fix, a security fix or dependency bump with no behavior change |

The relay is still at `0.y.z`. SemVer allows anything to change in `0.y.z`;
this project applies the table above anyway, so a breaking change takes the
version to `1.0.0`. Moving to `1.0.0` for any other reason is the maintainer's
decision.

`tools/next-version.sh` reads the Conventional Commit types since the last
release and says which bump they call for: `!` or a `BREAKING CHANGE:` footer
is major, `feat` is minor, `fix`, `perf` and `revert` are patch.
`tools/prepare-release.sh` refuses a version that disagrees unless told
`FORCE_VERSION=1`. The tool cannot see everything, so read the commits too:
a `fix` that renames an environment variable is still MAJOR.

**Before any release, say plainly if the requested version does not fit** what
the commits since the last tag contain, and what SemVer calls for instead. The
maintainer decides; a mismatch has to be a decision, not an accident.

A version never counts backwards, and a released version is never reused. The
version lives in one place, `__version__` in `relay.py` (it renders in the UI
footer and `/api/health`), and the newest `CHANGELOG.md` section must match it
(`tools/check-docs.py`).

## When releases happen

1. **Work lands on `main`.** Commits stay local until the maintainer says to
   push or ship. Every user-visible change adds a line under `## Unreleased`.
2. **A release happens only when the maintainer asks** ("ship it", "release
   0.3.0"). It is whatever is on `main`.
3. **Urgent patches** (a crash, data loss, a security hole, a relay that
   can't start, can't sign anyone in or can't deliver mail) ship from `main`
   while it holds nothing else unreleased. If `main` already has unreleased
   work, they ship from a `stable-X.Y` branch instead; see
   [Urgent patches](#urgent-patches).

## Before any release

- `python3 tools/check-docs.py` passes. A release does not go out while it fails.
- The changelog entries are written in the project's prose style
  ([CONTRIBUTING.md](CONTRIBUTING.md#prose-style)): what changed, from the
  operator's side, factual, no marketing and no emoji.
- For a dependency release: `pip-audit` against a fresh venv installed from
  `requirements.txt` is clean.
- The change was tried on the local test stack (`tools/redeploy.sh`).
- Every contributor in the release is in `CONTRIBUTORS` **before** the notes
  are generated, or `tools/release-notes.sh` strips their @.
- `git log origin/main..main --format=%B | grep -iE 'anthropic|claude'` prints
  nothing. The `pre-push` hook checks the same thing.

## Prepare

On `main`, with the changelog's `## Unreleased` section written:

```sh
tools/next-version.sh --why            # what SemVer calls for, and why
tools/prepare-release.sh               # or: tools/prepare-release.sh 0.3.0
```

That runs the checks, turns `## Unreleased` into `## [X.Y.Z] — date`, sets
`__version__`, commits `chore(release): X.Y.Z`, makes the annotated tag
`vX.Y.Z`, and stops. Nothing is pushed. Review with `git show --stat HEAD` and
`tools/release-notes.sh X.Y.Z`.

## Publish

```sh
git push origin main vX.Y.Z
tools/release-notes.sh X.Y.Z > /tmp/notes-X.Y.Z.md
gh release create vX.Y.Z --title "vX.Y.Z" --notes-file /tmp/notes-X.Y.Z.md
tools/publish-image.sh X.Y.Z
```

The release title is the version and nothing else: no name, no tagline. The
body is that version's changelog section plus the generated list of commits;
never hand `CHANGELOG.md` itself to `gh release create`, or every release page
carries the whole history.

`tools/publish-image.sh` builds from the tag with `git archive`, not from the
working tree, and pushes `:X.Y.Z`, `:X.Y` and `:latest`, `linux/amd64` only.
Without it the release reaches nobody: installs run
`hyprlab/tspro-relay:latest`. Docker Hub's tag list lags for minutes after a
push; `docker buildx imagetools inspect hyprlab/tspro-relay:X.Y.Z` is
authoritative.

Then reply to and close every issue the release fixes
([Issue replies](CONTRIBUTING.md#issue-replies)).

## Urgent patches

Only for a crash, data loss, a security hole, or a relay that can't start,
can't sign anyone in or can't deliver mail. If `main` holds nothing unreleased,
release from `main` as usual. Otherwise:

1. Fix it on `main` first, in its own commit, so it cherry-picks cleanly.
2. Cut the branch lazily, from the last release tag, never from main:
   `git branch stable-X.Y vX.Y.Z` (skip if it exists).
3. `git checkout stable-X.Y && git cherry-pick <sha>`, add the changelog line
   under `## Unreleased`, then `tools/prepare-release.sh X.Y.Z+1`.
4. Publish as above, pushing `stable-X.Y` instead of `main`.
5. Merge `stable-X.Y` back into `main`, so the changelog entry survives.
6. Never delete a `stable-X.Y` branch: patch commits may exist only there.

## The Releases page

A possible policy, not yet adopted here: keep only the newest release of each
`X.Y` line, deleting a superseded patch release and its tag once the new one
is live and its notes were generated. Docker image tags are never deleted,
since someone may have pinned one. Confirm with the maintainer before
deleting any release.
