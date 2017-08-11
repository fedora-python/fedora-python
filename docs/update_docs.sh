#!/bin/bash

make html

git clone "ssh://git@pagure.io/docs/$1.git"
cp -r _build/html/* $1/
(
    cd $1
    git add .
    git commit -av
    git push
)

rm -rfI _build
rm -rfI $1
