#!/bin/bash

# https://gist.github.com/mohanpedala/1e2ff5661761d3abd0385e8223e16425
set -euxo pipefail

echo "Logging in with personal access token."
export GH_TOKEN=$BACKUP_GITHUB_PAT
gh auth setup-git

echo "Downloading repositories for" $BACKUP_GITHUB_OWNER
gh repo list $BACKUP_GITHUB_OWNER --json "name" --limit 1000 --template '{{range .}}{{ .name }}{{"\n"}}{{end}}' | xargs -L1 -I {} gh repo clone $BACKUP_GITHUB_OWNER/{} -- --no-checkout

# Zip all the repositories with maximum compression
echo "Zipping repositories..."
find  . -maxdepth 1 -type d ! -path . -exec zip -r -9 -q {}.zip {} \;

# Upload zip files to S3
echo "Uploading to S3 bucket" $BACKUP_BUCKET_NAME "in region" $BACKUP_AWS_REGION
# aws s3 sync --quiet --no-follow-symlinks --region=$BACKUP_AWS_REGION . s3://$BACKUP_BUCKET_NAME/github.com/$BACKUP_GITHUB_OWNER/`date "+%Y-%m-%d"`/
aws s3 cp . s3://$BACKUP_BUCKET_NAME/github.com/$BACKUP_GITHUB_OWNER/`date "+%Y-%m-%d"`/ --recursive --exclude "*" --include "*.zip" --quiet --region=$BACKUP_AWS_REGION

echo "Complete."
