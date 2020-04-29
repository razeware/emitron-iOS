#!/usr/bin/env bash

# This will create a copy of the template xcconfig file required
# to build the app.

DIRECTORY="Emitron/Emitron/Configuration"
STAGES=(development beta production)
for STAGE in "${STAGES[@]}"
do
  FILE="$DIRECTORY/secrets.$STAGE.xcconfig"
  echo $FILE
  if [ -f $FILE ]; then
    echo "$FILE already exists. Skipping."
  else
    echo "Creating $FILE..."
    cp $DIRECTORY/secrets.template.xcconfig $FILE
  fi
done
