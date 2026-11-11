// Extrae de los .htm del manual (UTF-16LE) el bloque "Alternate Syntax:
// DEFINE <CTRL> ... END <CTRL>" y emite una linea por control con las
// claves separadas por coma, en el orden en que aparecen.
const fs = require('fs');
const files = process.argv.slice(2);
const results = {};
for (const f of files) {
  const buf = fs.readFileSync(f);
  let html;
  if (buf[0] === 0xFF && buf[1] === 0xFE) html = buf.toString('utf16le');
  else html = buf.toString('latin1');
  html = html.replace(/<script[\s\S]*?<\/script>/gi, ' ');
  html = html.replace(/<style[\s\S]*?<\/style>/gi, ' ');
  html = html.replace(/<br\s*\/?>/gi, '\n');
  html = html.replace(/<\/(p|div|li|tr|h\d|pre)>/gi, '\n');
  html = html.replace(/<[^>]+>/g, ' ');
  html = html.replace(/&nbsp;/g, ' ').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&').replace(/&quot;/g, '"');
  html = html.replace(/[ \t]+/g, ' ');

  // Find "Alternate Syntax" section or last DEFINE block
  let altIdx = html.search(/Alternate\s+Syntax/i);
  let searchFrom = altIdx >= 0 ? altIdx : 0;

  const m = /DEFINE\s+([A-Z]+)\s*<([^>]*)>?/.exec(html.substring(searchFrom));
  if (!m) continue;
  const ctrl = m[1];
  const startAt = searchFrom + m.index;

  // Find END <same ctrl> from startAt
  const endRegex = new RegExp('END\\s+' + ctrl + '\\b', 'i');
  const sub = html.substring(startAt);
  const endMatch = endRegex.exec(sub);
  const block = endMatch ? sub.substring(0, endMatch.index) : sub.substring(0, 5000);

  // Extract keys: lines starting with a known property keyword (uppercase word)
  // or ON <word>
  const keys = [];
  // Skip the DEFINE <CTRL> line
  const afterHeader = block.replace(/^DEFINE\s+[A-Z]+[^\n]*\n/, '');
  const tokens = afterHeader.split(/[\n]+/).map(s => s.trim()).filter(s => s);
  for (const tok of tokens) {
    // "ON GOTFOCUS" or "ONCLICK" or "PARENT <...>" etc.
    let mt = tok.match(/^ON\s+([A-Z]+)\b/i);
    if (mt) { keys.push('ON' + mt[1].toUpperCase()); continue; }
    mt = tok.match(/^([A-Z][A-Z0-9]+)\b/i);
    if (mt) keys.push(mt[1].toUpperCase());
  }
  // Deduplicate preserving first occurrence
  const uniq = [];
  for (const k of keys) if (uniq.indexOf(k) < 0) uniq.push(k);

  results[ctrl] = uniq;
}

// Emit Harbour source
const lines = [];
lines.push('/* Canonical property order extracted from HMG manual (Alternate Syntax).');
lines.push(' * Source: C:\\hmg.3.6\\doc\\data\\*.htm  (UTF-16LE).');
lines.push(' * Auto-generated — do not edit by hand; re-run _extract_manual.cjs.');
lines.push(' */');
lines.push('#ifndef IDE_MANUAL_ORDER_CH');
lines.push('#define IDE_MANUAL_ORDER_CH');
lines.push('');
lines.push('FUNCTION _ManualPropOrder ( cControlType )');
lines.push('LOCAL aMap');
lines.push('');
lines.push('	aMap := ;');
lines.push('		{ ;;');
for (const [k, v] of Object.entries(results)) {
  lines.push('		  ' + JSON.stringify(k).replace(/"/g, "'") + ' => { ' + v.map(x => "'" + x + "'").join(' , ') + ' } ;;');
}
// trim trailing ;; on last
lines[lines.length - 1] = lines[lines.length - 1].replace(/ ;;$/, ' }');
lines.push('		}');
lines.push('');
lines.push('RETURN HB_VAL( aMap, HMG_UPPER(ALLTRIM(cControlType)) )');
lines.push('');
lines.push('#endif');
lines.push('');

fs.writeFileSync('C:/hmg.3.6/SOURCE/unicode/Source/IDE_ManualOrder.ch', lines.join('\r\n'), 'latin1');
console.log('Wrote Include/IDE_ManualOrder.ch with ' + Object.keys(results).length + ' controls.');
console.log(Object.keys(results).join(', '));
