#!/bin/bash

# Template repository URL
SOURCE_URL=git@github.com:joseleite550/idempiere-plugin-template.git
REPOSITORY_NAME="idempiere-plugin-template"
FOLDER_NAME="template"
IDEMPIERE_DIR="idempiere"

read -p "Enter the name of the new plugin: " PLUGIN_NAME

if [ -z "$PLUGIN_NAME" ]; then
  echo "[ERROR] Invalid name. Aborting."
  exit 1
fi

# Check if iDempiere repository exists
if [ ! -d "$IDEMPIERE_DIR" ]; then
  echo "[WARNING] iDempiere repository was not found in the current directory."
  read -p "Continue creating the plugin without iDempiere? (y/n): " CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "[INFO] Plugin creation canceled."
    exit 0
  fi
fi

if [ ! -d "$REPOSITORY_NAME" ]; then
  echo "[INFO] Cloning the template repository..."
  git clone "$SOURCE_URL"
fi

if [ ! -d "$REPOSITORY_NAME" ]; then
  echo "[ERROR] Failed to clone the template repository. Aborting."
  exit 1
fi

echo "[INFO] Creating new plugin structure: '$PLUGIN_NAME'"

mv $REPOSITORY_NAME $FOLDER_NAME

SOURCE_RAW="$FOLDER_NAME"
DEST_RAW="$PLUGIN_NAME"
SOURCE=`echo $FOLDER_NAME | sed 's/\./\\\\./g'`
DEST=`echo $PLUGIN_NAME | sed 's/\./\\\\./g'`

# Copy files and folders
IFSOLD=$IFS
IFS=$'\n'
for files in $(find $SOURCE_RAW);
do
  filename=$(sed "s/$SOURCE/$DEST/g" <<<"$files")
  if [ -d $files ]; 
  then
    mkdir -p $filename
    echo "[INFO] Created directory: $filename"
  fi
  if [ -f $files ]; 
  then
    rsync -a $files $filename
    echo "[INFO] Copied file: $filename"
  fi
done
IFS=$IFSOLD

cd $DEST_RAW

rm -rf .git
echo "[INFO] Removed old Git repository."

grep -rl $SOURCE_RAW . | xargs sed -i "s/$SOURCE/$DEST/g"
echo "[INFO] Updated references from '$SOURCE' to '$DEST'."

echo "[INFO] Running Maven build..."
mvn verify -Didempiere.target="org.$PLUGIN_NAME.p2.targetplatform"

cd ..

rm -rf $FOLDER_NAME
echo "[INFO] Removed temporary folder: $FOLDER_NAME"

echo "[SUCCESS] New plugin '$PLUGIN_NAME' created successfully."
