# Cleanup Todos Process Document

Please use the `trello` cli to cleanup the todos in my todo list.

Look in my trello board with the name "Personal" and look in the "To Do Today" list. Please make sure
there are no duplicates. Remove anything that is a duplicate. Then archive anything in the "Done" list.

## Practical Notes

- The `Personal` board ID is `5c0ddac9ab8dcf474ffe25fd`.
- The `To Do Today` list ID is `5c0ddadd92a8a03d59cbdacf`.
- The `Done` list ID is `66476c045eaf400eb830ac3e`.
- `trello sync` may fail if any accessible board has too many cards. If that happens, use the configured `~/.trello-cli/default/config.json` credentials for direct Trello API calls instead of relying on the CLI name cache.
- When removing duplicates from `To Do Today`, compare exact card names after trimming whitespace. Keep the newest card by `dateLastActivity` and archive the older copies.
- Archive cards by setting `closed=true`; do not permanently delete cards.
- After cleanup, verify `To Do Today` has no duplicate open card names and `Done` has zero open cards.

## Direct API Example

Use this pattern when the `trello` CLI cache cannot resolve board or list names:

```sh
node -e 'const fs=require("fs"); const cfg=JSON.parse(fs.readFileSync(`${process.env.HOME}/.trello-cli/default/config.json`,"utf8")); const auth={key:cfg.apiKey,token:cfg.token}; async function req(path, method="GET", params={}){const qs=new URLSearchParams({...auth,...params}); const r=await fetch(`https://api.trello.com/1${path}?${qs}`,{method}); if(!r.ok) throw new Error(`${method} ${path}: ${r.status} ${await r.text()}`); return r.text().then(t=>t?JSON.parse(t):null);} (async()=>{const todayList="5c0ddadd92a8a03d59cbdacf"; const doneList="66476c045eaf400eb830ac3e"; const today=await req(`/lists/${todayList}/cards`,"GET",{filter:"open",fields:"id,name,dateLastActivity,pos"}); const byName=new Map(); for(const card of today){const key=card.name.trim(); if(!byName.has(key)) byName.set(key,[]); byName.get(key).push(card);} for(const cards of byName.values()){cards.sort((a,b)=>new Date(b.dateLastActivity)-new Date(a.dateLastActivity) || b.pos-a.pos); for(const card of cards.slice(1)){await req(`/cards/${card.id}/closed`,"PUT",{value:"true"});}} const done=await req(`/lists/${doneList}/cards`,"GET",{filter:"open",fields:"id,name"}); for(const card of done){await req(`/cards/${card.id}/closed`,"PUT",{value:"true"});}})().catch(e=>{console.error(e.message); process.exit(1);})'
```

Verification command:

```sh
node -e 'const fs=require("fs"); const cfg=JSON.parse(fs.readFileSync(`${process.env.HOME}/.trello-cli/default/config.json`,"utf8")); const auth={key:cfg.apiKey,token:cfg.token}; async function get(path, params={}){const qs=new URLSearchParams({...auth,...params}); const r=await fetch(`https://api.trello.com/1${path}?${qs}`); if(!r.ok) throw new Error(`${r.status} ${await r.text()}`); return r.json();} (async()=>{const today=await get("/lists/5c0ddadd92a8a03d59cbdacf/cards",{filter:"open",fields:"id,name"}); const done=await get("/lists/66476c045eaf400eb830ac3e/cards",{filter:"open",fields:"id,name"}); const counts={}; for(const c of today){const key=c.name.trim(); counts[key]=(counts[key]||0)+1;} const duplicates=Object.entries(counts).filter(([,count])=>count>1).map(([name,count])=>({name,count})); console.log(JSON.stringify({todayOpenCount:today.length,duplicates,doneOpenCount:done.length},null,2));})().catch(e=>{console.error(e.message); process.exit(1);})'
```
