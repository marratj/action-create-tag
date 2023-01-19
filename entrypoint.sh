#!/bin/bash
set -eu

# Apply hotfix for 'fatal: unsafe repository' error (see #10)
git config --global --add safe.directory "${GITHUB_WORKSPACE}"

cd "${GITHUB_WORKSPACE}" || exit

if [ -z "${INPUT_TAG}" ]; then
  echo "[action-create-tag] No-tag was supplied! Please supply a tag."
  exit 1
fi

# Set up variables.
TAG="${INPUT_TAG}"
MESSAGE="${INPUT_MESSAGE:-Release ${TAG}}"
FORCE_TAG="${INPUT_FORCE_PUSH_TAG:-false}"
SHA=${INPUT_COMMIT_SHA:-${GITHUB_SHA}}
INCLUDE_SUBMODULES="${INPUT_INCLUDE_SUBMODULES:-false}"
ONLY_SUBMODULE="${INPUT_ONLY_SUBMODULE:-}"

git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"

if [ "${INCLUDE_SUBMODULES}" = 'true' ]; then
  git submodule foreach git config user.name "${GITHUB_ACTOR}"
  git submodule foreach git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
fi

echo "GITHUB_SHA=${GITHUB_SHA}"
echo "INPUT_COMMIT_SHA=${INPUT_COMMIT_SHA}"
echo "SHA=${SHA}"

FORCE_SWITCH=""
if [ "${FORCE_TAG}" = 'true' ]; then
  FORCE_SWITCH="--force"
fi
echo "FORCE_SWITCH=${FORCE_SWITCH}"

# Create tag
echo "[action-create-tag] Create tag '${TAG}'."

if [ -n "${ONLY_SUBMODULE}" ]; then
  git config --global --add safe.directory /github/workspace/${ONLY_SUBMODULE}
  pushd ${ONLY_SUBMODULE}
  git tag ${FORCE_SWITCH} -a "${TAG}" -m "${MESSAGE}"
  popd
else
  git tag ${FORCE_SWITCH} -a "${TAG}" "${SHA}" -m "${MESSAGE}"
  if [ "${INCLUDE_SUBMODULES}" = 'true' ]; then
    git submodule foreach git tag ${FORCE_SWITCH} -a "${TAG}" -m "${MESSAGE}"
  fi
fi

# Set up remote url for checkout@v1 action.
if [ -n "${INPUT_GITHUB_TOKEN}" ]; then
  git remote set-url origin "https://${GITHUB_ACTOR}:${INPUT_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
fi

# Push tag
echo "[action-create-tag] Push tag '${TAG}'."

if [ -n "${ONLY_SUBMODULE}" ]; then
  pushd ${ONLY_SUBMODULE}
  git push origin "${TAG}" ${FORCE_SWITCH}
  popd
else
  git push ${FORCE_SWITCH} origin "${TAG}"
  if [ "${INCLUDE_SUBMODULES}" = 'true' ]; then
    git submodule foreach git push origin "${TAG}" ${FORCE_SWITCH}
  fi
fi