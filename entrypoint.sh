#!/bin/sh

set -e

git config --global --add safe.directory /github/workspace

git fetch --tags

# Check if the repository is shallow before unshallowing
if git rev-parse --is-shallow-repository; then
  echo "Repository is shallow. Unshallowing..."
  git fetch --prune --unshallow
else
  echo "Repository is complete. Skipping unshallowing."
fi

latest_tag=''

if [ "${INPUT_SEMVER_ONLY}" = 'false' ]; then
  # Get the actual latest tag.
  # If no tags found, suppress an error. In such case stderr will be not stored in latest_tag variable so no additional logic is needed.
  latest_tag=$(git describe --abbrev=0 --tags || true)
else
  # Get the latest tag in the shape of semver.
  for ref in $(git for-each-ref --sort=-creatordate --format '%(refname)' refs/tags); do
    tag="${ref#refs/tags/}"
    if echo "${tag}" | grep -Eq '^v?([0-9]+)\.([0-9]+)\.([0-9]+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+)?$'; then
      latest_tag="${tag}"
      break
    fi
  done
fi

if [ "${latest_tag}" = '' ] && [ "${INPUT_WITH_INITIAL_VERSION}" = 'true' ]; then
  latest_tag="${INPUT_INITIAL_VERSION}"
fi

echo "tag=${latest_tag}" >> "$GITHUB_OUTPUT"
