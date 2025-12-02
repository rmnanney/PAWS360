#!/usr/bin/env node
const fs = require('fs');

// Simple metrics calculator — accepts runs.json and computes some aggregates
const runsPath = process.argv[2] || 'runs.json';
const outPath = process.argv[3] || 'monitoring/ci-cd-dashboard/data/metrics.json';

if (!fs.existsSync(runsPath)) {
  console.error('runs.json not found — please provide output from GitHub API');
  process.exit(0);
}

const raw = fs.readFileSync(runsPath, 'utf8');
const runsData = JSON.parse(raw);
const runs = runsData.workflow_runs || [];

const minutesTotal = runs.reduce((sum, r) => sum + ((r.run_duration_ms || 0) / 60000 || 0), 0);
const scheduledMinutes = runs.reduce((sum, r) => sum + ((r.run_duration_ms || 0) / 60000 || 0) * ((r.event === 'schedule') ? 1 : 0), 0);

const byWorkflow = {};
const byDayMap = new Map();
for (const r of runs) {
  const w = r.name || r.workflow_name || 'unknown';
  byWorkflow[w] = (byWorkflow[w] || 0) + ((r.run_duration_ms || 0) / 60000 || 0);
  const d = (new Date(r.created_at || r.run_started_at || Date.now())).toISOString().slice(0,10);
  byDayMap.set(d, (byDayMap.get(d) || 0) + ((r.run_duration_ms || 0) / 60000 || 0));
}

const by_day = Array.from(byDayMap.entries()).map(([date, minutes])=>({date, minutes})).sort((a,b)=>a.date.localeCompare(b.date));

const out = {
  last_updated: new Date().toISOString(),
  total_minutes_this_month: Math.round(minutesTotal),
  scheduled_minutes_this_month: Math.round(scheduledMinutes),
  scheduled_percentage: minutesTotal > 0 ? Math.round((scheduledMinutes / minutesTotal) * 100) : 0,
  by_workflow: byWorkflow,
  by_day,
};

fs.writeFileSync(outPath, JSON.stringify(out, null, 2));
console.log('metrics written to', outPath);
