#!/usr/bin/env node
// parse-usage-log.js — agrega un log local de OTel console (`OTEL_METRICS_EXPORTER=console`)
// en un resumen de atribución compartible. Ver SDD/tests/test_usage_summary.sh
// para el contrato de comportamiento.
//
// El formato NO es JSON (claves sin comillas, comas finales) — es la salida de
// util.inspect de Node sobre el objeto de métrica. Se evalúa como expresión JS
// (new Function) en vez de intentar un parser JSON tolerante.
//
// Los contadores son ACUMULATIVOS por sesión: la misma métrica se re-emite en
// cada intervalo de export con el valor total-a-la-fecha, no un delta. Sumar
// todas las líneas sobreestima el costo real en proporción a (duración de la
// sesión / intervalo de export) — medido: un mismo valor repetido 40 veces en
// una sesión de segundos. Por eso se toma el MÁXIMO por (sesión, atribución),
// y recién esos máximos se suman ENTRE sesiones.
'use strict';

const fs = require('fs');

const ATTRIBUTION_FIELDS = [
  'model', 'query_source', 'effort', 'speed',
  'skill.name', 'agent.name', 'plugin.name', 'marketplace.name',
  'mcp_server.name', 'mcp_tool.name', 'type',
];

const TOKEN_TYPES = ['input', 'output', 'cacheRead', 'cacheCreation'];

function splitBlocks(text) {
  const blocks = [];
  let depth = 0;
  let start = -1;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (c === '{') {
      if (depth === 0) start = i;
      depth++;
    } else if (c === '}') {
      depth--;
      if (depth === 0 && start !== -1) {
        blocks.push(text.slice(start, i + 1));
        start = -1;
      }
    }
  }
  return blocks;
}

function evalBlock(blockText) {
  try {
    return new Function('return (' + blockText + ')')();
  } catch (e) {
    return null;
  }
}

function attributionKey(attrs) {
  return ATTRIBUTION_FIELDS
    .map((f) => `${f}=${attrs[f] !== undefined ? attrs[f] : ''}`)
    .join('|');
}

function sourceLabel(attrs) {
  return attrs['skill.name'] || attrs['agent.name'] || attrs['mcp_server.name']
    || attrs['plugin.name'] || '(principal)';
}

function fmtUsd(n) {
  return '$' + n.toFixed(2);
}

function fmtDate(ts) {
  return ts === null ? '?' : new Date(ts * 1000).toISOString().slice(0, 10);
}

function main() {
  const file = process.argv[2];
  if (!file) {
    console.error('uso: parse-usage-log.js <archivo>');
    process.exit(2);
  }

  let text;
  try {
    text = fs.readFileSync(file, 'utf8');
  } catch (e) {
    console.error(`ERROR: no pude leer ${file}: ${e.message}`);
    process.exit(2);
  }

  const sessionMax = { 'claude_code.cost.usage': {}, 'claude_code.token.usage': {} };
  const sessions = new Set();
  let userEmail = '';
  let minTs = null;
  let maxTs = null;

  for (const blockText of splitBlocks(text)) {
    const block = evalBlock(blockText);
    if (!block || !block.descriptor) continue;
    const metric = block.descriptor.name;
    if (!sessionMax[metric]) continue;

    for (const dp of block.dataPoints || []) {
      const attrs = dp.attributes || {};
      const sid = attrs['session.id'] || '(sin-sesion)';
      sessions.add(sid);
      if (attrs['user.email']) userEmail = attrs['user.email'];

      const ts = Array.isArray(dp.endTime) ? dp.endTime[0] : null;
      if (ts !== null) {
        if (minTs === null || ts < minTs) minTs = ts;
        if (maxTs === null || ts > maxTs) maxTs = ts;
      }

      const key = attributionKey(attrs);
      sessionMax[metric][sid] = sessionMax[metric][sid] || {};
      const prev = sessionMax[metric][sid][key];
      if (!prev || dp.value > prev.value) {
        sessionMax[metric][sid][key] = { value: dp.value, attrs };
      }
    }
  }

  const finalTotal = { 'claude_code.cost.usage': {}, 'claude_code.token.usage': {} };
  for (const metric of Object.keys(sessionMax)) {
    for (const sid of Object.keys(sessionMax[metric])) {
      for (const key of Object.keys(sessionMax[metric][sid])) {
        const { value, attrs } = sessionMax[metric][sid][key];
        if (!finalTotal[metric][key]) finalTotal[metric][key] = { value: 0, attrs };
        finalTotal[metric][key].value += value;
      }
    }
  }

  let totalCost = 0;
  const byModel = {};
  const bySource = {};
  const costKeys = finalTotal['claude_code.cost.usage'];
  for (const key of Object.keys(costKeys)) {
    const { value, attrs } = costKeys[key];
    totalCost += value;
    const model = attrs.model || '(desconocido)';
    byModel[model] = (byModel[model] || 0) + value;
    const label = sourceLabel(attrs);
    bySource[label] = (bySource[label] || 0) + value;
  }

  const tokenTotals = { input: 0, output: 0, cacheRead: 0, cacheCreation: 0 };
  const usageKeys = finalTotal['claude_code.token.usage'];
  for (const key of Object.keys(usageKeys)) {
    const { value, attrs } = usageKeys[key];
    if (attrs.type && Object.prototype.hasOwnProperty.call(tokenTotals, attrs.type)) {
      tokenTotals[attrs.type] += value;
    }
  }

  const lines = [];
  lines.push(`# Resumen de consumo — ${userEmail || '(sin email)'}`);
  lines.push(`Periodo: ${fmtDate(minTs)} → ${fmtDate(maxTs)} · ${sessions.size} sesiones`);
  lines.push('');
  lines.push(`## Costo total: ${fmtUsd(totalCost)}`);
  lines.push('');
  lines.push('### Por modelo');
  lines.push('| Modelo | Costo |');
  lines.push('|---|---|');
  for (const model of Object.keys(byModel).sort()) {
    lines.push(`| ${model} | ${fmtUsd(byModel[model])} |`);
  }
  lines.push('');
  lines.push('### Por fuente');
  lines.push('| Fuente | Costo |');
  lines.push('|---|---|');
  for (const label of Object.keys(bySource).sort()) {
    lines.push(`| ${label} | ${fmtUsd(bySource[label])} |`);
  }
  lines.push('');
  lines.push('### Tokens');
  lines.push('| Tipo | Cantidad |');
  lines.push('|---|---|');
  for (const type of TOKEN_TYPES) {
    lines.push(`| ${type} | ${tokenTotals[type]} |`);
  }

  console.log(lines.join('\n'));
}

main();
