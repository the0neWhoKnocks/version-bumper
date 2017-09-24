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
REPO_URL=$(git config --get remote.origin.url)
REPO_URL=$(node -p "'$REPO_URL'.replace(/^git@/,'https://').replace('.com:','.com/').replace(/\.git$/,'')")

# build out what the version would be based on what the user chooses
MAJOR=$(node -p "var nums='$VERSION'.split('.'); nums[0]=+nums[0]+1; nums[1]=0; nums[2]=0; nums.join('.')")
MINOR=$(node -p "var nums='$VERSION'.split('.'); nums[1]=+nums[1]+1; nums[2]=0; nums.join('.')")
PATCH=$(node -p "var nums='$VERSION'.split('.'); nums[2]=+nums[2]+1; nums.join('.')")

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
  # get previous tag info so that the changelog can be updated.
  if [[ $(git tag -l) != "" ]]; then
    latestTag=$(git tag -l | tail -n1)
    #echo "Latest tag: $latestTag"
  fi

  # get a list of changes between tags
  if [[ "$latestTag" != "" ]]; then
    filename="./CHANGELOG.md"
    newContent=""
    touch "$filename"

    #changes=$(git log "v3.1.0".."v4.0.0" --oneline)
    changes=$(git log "$latestTag"..HEAD --oneline)
    formattedChanges=""
    while read -r line; do
      if [[ "$formattedChanges" != "" ]]; then
        formattedChanges="$formattedChanges,'$line'"
      else
        formattedChanges="'$line'"
      fi
    done < <(echo -e "$changes")
    formattedChanges="[$formattedChanges]"

    newContent=$(node -pe "
      let changes = $formattedChanges;
      for(let i=0; i<changes.length; i++){
        changes[i] = changes[i].replace(/^([a-z0-9]+)\s/i, \"- [\$1]($REPO_URL/commit/\$1) \");
      }
      changes.join('\n');
    ")

    # add changes to top of logs
    if [[ "$newContent" != "" ]]; then
      echo $'\n'"## $newVersion"$'\n'"$newContent"$'\n'"$(cat "$filename")" > "$filename"
    fi
  fi

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
  git commit -m "v$newVersion"$'\n\n'"$changes"
  handleError $? "Couldn't commit new files"
  git tag -a "v$newVersion" -m "v$newVersion"$'\n\n'"$changes"
  handleError $? "Couldn't create tag for new version"

  # run a second push with no hooks in the background so that the new commit gets pushed up.
  nohup sleep 1 && git push --no-verify --follow-tags &>/dev/null &
fi
