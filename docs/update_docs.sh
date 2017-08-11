#!/bin/bash

make html

PAGURE_ORG_NAME="fedora-python"
DOCS_REPO_NAME="fedora-python"

git clone "ssh://git@pagure.io/docs/$PAGURE_ORG_NAME/$DOCS_REPO_NAME.git"
cp -r _build/html/* $DOCS_REPO_NAME/
(
    cd $DOCS_REPO_NAME
    git add .
    git commit -av
    git push
)

#rm -rfI _build
#rm -rfI $DOCS_REPO_NAME
