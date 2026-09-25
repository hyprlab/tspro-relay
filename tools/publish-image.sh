#!/usr/bin/env bash
# Build the Docker image for a tagged version and push it to Docker Hub.
#
#   tools/publish-image.sh 0.3.0     # pushes :0.3.0, :0.3 and :latest
#
# Builds from the tag, not the working tree, so what is pushed is exactly what
# was released. linux/amd64 only: the host's buildx has no arm64 builder, and
# switching to a multi-arch manifest changes what existing installs pull, so
# it is the maintainer's decision, not a default.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:?usage: tools/publish-image.sh X.Y.Z}"
TAG="v$VERSION"
IMAGE="${IMAGE:-hyprlab/tspro-relay}"
PLATFORMS="${PLATFORMS:-linux/amd64}"

git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || { echo "no tag $TAG" >&2; exit 1; }
tagged=$(git show "$TAG:relay.py" | sed -n 's/^__version__ = "\(.*\)"/\1/p')
[ "$tagged" = "$VERSION" ] || { echo "$TAG carries __version__ $tagged, not $VERSION" >&2; exit 1; }
[[ "$VERSION" != *-* ]] || { echo "This project publishes stable versions only." >&2; exit 1; }

minor="${VERSION%.*}"
tags=(-t "$IMAGE:$VERSION" -t "$IMAGE:$minor" -t "$IMAGE:latest")

src=$(mktemp -d)
trap 'rm -rf "$src"' EXIT
git archive "$TAG" | tar -x -C "$src"

echo "Building $IMAGE for $VERSION ($PLATFORMS) from $TAG"
docker buildx build --platform "$PLATFORMS" \
    --label "org.opencontainers.image.version=$VERSION" \
    --label "org.opencontainers.image.revision=$(git rev-parse "$TAG^{commit}")" \
    --label "org.opencontainers.image.source=https://github.com/hyprlab/tspro-relay" \
    "${tags[@]}" --push "$src"

echo "Pushed: ${tags[*]//-t /}"
echo "Docker Hub's tag list lags for minutes; check with: docker buildx imagetools inspect $IMAGE:$VERSION"
