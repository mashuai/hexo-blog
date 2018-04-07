#!/bin/sh
git add .
git commit -m 'auto commit'
git push origin master

echo "generate to html"

hexo g

echo "deploy to coding"
cp _config.coding.yml _config.yml
hexo d

echo "deploy to github"
cp _config.github.yml _config.yml
hexo d
