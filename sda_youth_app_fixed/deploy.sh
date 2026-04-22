#!/bin/bash
set -e

# Step 0: go to project root
cd /home/martin/sda_youth_app_fixed

# Step 1: Build with correct base href for project site
flutter clean
flutter pub get
flutter build web --release --base-href /sda_youth_app/

# Step 2: Deploy to gh-pages
git checkout gh-pages
git rm -rf .
cp -r build/web/* .
git add .
git commit -m "Automated deploy for /sda_youth_app/ project site"
git push origin gh-pages --force
