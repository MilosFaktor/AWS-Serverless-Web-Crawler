#!/bin/bash
set -e


curl -sS -X POST \
-H "Authorization: token $GITHUB_TOKEN" \
-H "Accept: application/vnd.github.v3+json" \
"https://api.github.com/repos/MilosFaktor/aws-hands-on-lab-SAA/statuses/$CODEBUILD_RESOLVED_SOURCE_VERSION" \
-d '{"state":"success","description":"Pipeline successfully tested and manually approved. ","context":"post-approval-gate"}'

