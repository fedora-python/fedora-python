#!/bin/bash

make html

DOCS_REPO_NAME="fedora-python"

git clone "ssh://git@pagure.io/docs/$DOCS_REPO_NAME.git"
cp -r _build/html/* $DOCS_REPO_NAME/
(
    cd $DOCS_REPO_NAME
    git add .
    git commit -av
    git push
)

#rm -rfI _build
#rm -rfI $DOCS_REPO_NAME
