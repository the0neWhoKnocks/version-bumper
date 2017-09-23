#!/bin/bash

function handleError {
  if [ $1 -ne 0 ]; then
    echo;
    echo "[ ERROR ] $2"
    exit $1
  fi
}

# give options for skipping bump, or 3 bump options
echo "[ BUMP ] versions ========================"
# get current version number
VERSION=$(node -pe "require('./package.json').version")

# build out what the version would be based on what the user chooses
MAJOR=$(node -pe "var nums = '$VERSION'.split('.'); nums[0]=+nums[0]+1; nums[1]=0; nums[2]=0; nums.join('.')")
MINOR=$(node -pe "var nums = '$VERSION'.split('.'); nums[1]=+nums[1]+1; nums[2]=0; nums.join('.')")
PATCH=$(node -pe "var nums = '$VERSION'.split('.'); nums[2]=+nums[2]+1; nums.join('.')")

# Allows for reading input below during actual git call - assigns stdin to keyboard
exec < /dev/tty

echo;
echo " Choose what version to bump to"
echo;
echo " (1) Patch - $PATCH"
echo " (2) Minor - $MINOR"
echo " (3) Major - $MAJOR"
echo " (4) Don't bump the version"
echo;

read selectedOption

case $selectedOption in
  1)
    bump="patch"
    newVersion="$PATCH"
    ;;
  2)
    bump="minor"
    newVersion="$MINOR"
    ;;
  3)
    bump="major"
    newVersion="$MAJOR"
    ;;
esac
# close stdin
exec <&-

echo;
if [[ "$bump" != "" ]]; then
  npm version --no-git-tag-version $bump
  handleError $? "Couldn't bump version number."

  echo;
  echo "[ COMPILE ] code ========================="
  echo;
  npm run compile
  handleError $? "Couldn't compile with new version."

  echo;
  echo "[ COMMIT ] bumped version ================"
  echo;
  git add -u
  handleError $? "Couldn't add new files"
  git commit -m "Bumped version to $newVersion"
  handleError $? "Couldn't commit new files"

  # run a second push with no hooks in the background so that the new commit gets pushed up.
  nohup sleep 1 && git push --no-verify &>/dev/null &
fi
