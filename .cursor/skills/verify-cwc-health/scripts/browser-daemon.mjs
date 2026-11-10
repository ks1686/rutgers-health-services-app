import fs from 'node:fs';
import net from 'node:net';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// tel: and sms: stay inside the page. The real window.open is not called.
export const OPEN_STUB = `(() => {
  const opens = [];
  window.__cwcOpens = opens;
  const orig = window.open.bind(window);
  window.open = function open(href, ...rest) {
    const url = String(href ?? '');
    opens.push(url);
    const lowered = url.toLowerCase();
    if (lowered.startsWith('tel:') || lowered.startsWith('sms:')) return null;
    return orig(href, ...rest);
  };
})();`;

export function phoneTapError(msg) {
  if (!msg || msg.cmd !== 'click') return '';
  const name = String(msg.name || '');
  if (name === 'Call' || name === 'Text') return 'refusing to tap a phone or text row';
  if (/911|988|opens your phone/i.test(name)) return 'refusing to tap a phone or text row';
  const expected = String(msg.expectOpen || '');
  if (/^(tel:|sms:)/i.test(expected)) return 'refusing a tel or sms open';
  return '';
}

function assertInside(root, candidate) {
  const rel = path.relative(root, candidate);
  if (
    rel === '' ||
    rel === '..' ||
    rel.startsWith(`..${path.sep}`) ||
    path.isAbsolute(rel)
  ) {
    throw new Error(`refusing to write outside this run evidence folder: ${candidate}`);
  }
}

export function resolveEvidenceFile(file) {
  if (typeof file !== 'string' || file.length === 0 || file.includes('\0')) {
    throw new Error('refusing evidence path');
  }
  const evidence = process.env.CWC_EVIDENCE;
  if (!evidence) throw new Error('CWC_EVIDENCE is not set');
  let root;
  try {
    root = fs.realpathSync(evidence);
  } catch {
    throw new Error('evidence folder is not available');
  }
  const abs = path.resolve(file);
  const parts = abs.split(path.sep).filter(Boolean);
  let current = path.parse(abs).root;
  for (let i = 0; i < parts.length; i += 1) {
    const part = parts[i];
    if (part === '.' || part === '..') throw new Error('refusing evidence path');
    const next = path.join(current, part);
    let st;
    try {
      st = fs.lstatSync(next);
    } catch (err) {
      if (err.code !== 'ENOENT') throw new Error('refusing evidence path');
      const finalPath = path.join(current, part, ...parts.slice(i + 1));
      assertInside(root, finalPath);
      return { root, finalPath };
    }
    if (st.isSymbolicLink()) {
      let target;
      try {
        target = fs.realpathSync(next);
      } catch {
        throw new Error('refusing to follow an evidence symlink');
      }
      const rest = parts.slice(i + 1);
      const finalPath = rest.length === 0 ? target : path.join(target, ...rest);
      assertInside(root, finalPath);
      if (rest.length === 0) return { root, finalPath: target };
      current = target;
      continue;
    }
    current = next;
  }
  assertInside(root, current);
  return { root, finalPath: current };
}

function chmodUp(start, root) {
  let current = start;
  while (current.startsWith(root)) {
    try {
      fs.chmodSync(current, 0o700);
    } catch {
      // The directory may have been removed. The write still has to pass the path check.
    }
    if (current === root) break;
    const next = path.dirname(current);
    if (next === current) break;
    current = next;
  }
}

function evidencePath(file) {
  const { root, finalPath } = resolveEvidenceFile(file);
  fs.mkdirSync(path.dirname(finalPath), { recursive: true, mode: 0o700 });
  const again = resolveEvidenceFile(finalPath);
  const parentReal = fs.realpathSync(path.dirname(again.finalPath));
  const checked = path.join(parentReal, path.basename(again.finalPath));
  assertInside(root, checked);
  chmodUp(parentReal, root);
  return checked;
}

function refuseSymlink(file) {
  try {
    if (fs.lstatSync(file).isSymbolicLink()) {
      throw new Error('refusing to follow an evidence symlink');
    }
  } catch (err) {
    if (err.code !== 'ENOENT') throw err;
  }
}

function writePrivate(file, data) {
  refuseSymlink(file);
  fs.writeFileSync(file, data, { mode: 0o600 });
  fs.chmodSync(file, 0o600);
}

async function launchChrome() {
  const { chromium } = await import('playwright-core');
  const attempts = [
    { channel: 'chrome', args: ['--disable-dev-shm-usage'] },
    {
      executablePath: '/usr/bin/google-chrome',
      args: ['--disable-dev-shm-usage', '--no-sandbox'],
    },
  ];
  let last;
  for (const opts of attempts) {
    try {
      return await chromium.launch({ headless: true, ...opts });
    } catch (err) {
      last = err;
    }
  }
  throw last;
}

async function enableAccessibility(page, logs = []) {
  await page
    .locator('flt-glass-pane, flutter-view')
    .first()
    .waitFor({ state: 'attached', timeout: 45000 })
    .catch(() => {});
  const placeholder = page.locator('flt-semantics-placeholder');
  const appeared = await placeholder
    .waitFor({ state: 'attached', timeout: 30000 })
    .then(() => true)
    .catch(() => false);
  if (!appeared) {
    const ready = await page.locator('flt-semantics[role="button"]').count();
    if (ready > 0) return;
    const dom = await page.evaluate(() => ({
      title: document.title,
      text: (document.body?.innerText || '').slice(0, 500),
      tags: [...document.body.querySelectorAll('*')]
        .slice(0, 30)
        .map((el) => el.tagName),
    }));
    throw new Error(
      `Flutter accessibility placeholder did not appear ${JSON.stringify(dom)} console=${logs.slice(-12).join(' | ')}`,
    );
  }
  await page.evaluate(() => {
    const el = document.querySelector('flt-semantics-placeholder');
    if (!el) return;
    el.dispatchEvent(
      new MouseEvent('click', { bubbles: true, cancelable: true, view: window }),
    );
  });
  await page
    .locator('flt-semantics[role="button"]')
    .first()
    .waitFor({ state: 'attached', timeout: 20000 });
}

async function openApp(page, url) {
  const logs = [];
  page.on('console', (msg) => logs.push(`${msg.type()}: ${msg.text()}`));
  page.on('pageerror', (err) => logs.push(`pageerror: ${err.message}`));
  await page.addInitScript(OPEN_STUB);
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 120000 });
  await enableAccessibility(page, logs);
  await page.getByText('Before you continue', { exact: true }).waitFor({
    timeout: 30000,
  });
}

function locatorFor(page, msg) {
  const exact = msg.exact !== false;
  let root = page;
  if (msg.withinRole) {
    root = page.getByRole(msg.withinRole, {
      name: msg.withinName,
      exact: false,
    });
  }
  return root.getByRole(msg.role, { name: msg.name, exact });
}

async function ariaText(page) {
  return page.locator('body').ariaSnapshot();
}

async function scrollIntoView(page, text) {
  const target = page.getByText(text, { exact: false }).last();
  const viewport = page.viewportSize();
  for (let i = 0; i < 10; i += 1) {
    const box = await target.boundingBox();
    if (
      box &&
      box.height > 0 &&
      box.width > 0 &&
      box.y >= 0 &&
      box.y + Math.min(box.height, 40) <= viewport.height
    ) {
      return { ok: true };
    }
    await page.mouse.move(viewport.width / 2, Math.min(500, viewport.height / 2));
    await page.mouse.wheel(0, 450);
    await page.waitForTimeout(250);
  }
  return { ok: false };
}

async function persistOpens(page) {
  const stateDir = process.env.CWC_STATE;
  if (!stateDir) return;
  let st;
  try {
    st = fs.lstatSync(stateDir);
  } catch {
    return;
  }
  if (st.isSymbolicLink() || !st.isDirectory()) return;
  const opens = await page.evaluate(() => window.__cwcOpens || []);
  const file = path.join(stateDir, 'opens.log');
  try {
    if (fs.lstatSync(file).isSymbolicLink()) return;
  } catch (err) {
    if (err.code !== 'ENOENT') return;
  }
  fs.writeFileSync(file, opens.length ? `${opens.join('\n')}\n` : '', { mode: 0o600 });
  fs.chmodSync(file, 0o600);
}

async function dispatch(page, msg) {
  const blocked = phoneTapError(msg);
  if (blocked) return { ok: false, error: blocked };
  if (msg.expectOpen) {
    return { ok: false, error: 'this helper does not confirm phone opens' };
  }
  if (msg.cmd === 'click') {
    await locatorFor(page, msg).click({ timeout: 20000 });
    return { ok: true, message: `clicked ${msg.role} ${msg.name}` };
  }
  if (msg.cmd === 'fill') {
    await locatorFor(page, msg).fill(msg.value, { timeout: 20000 });
    return { ok: true, message: `filled ${msg.name}` };
  }
  if (msg.cmd === 'expect-text' || msg.cmd === 'expect-absent') {
    const deadline = Date.now() + (msg.timeoutMs || 10000);
    let last = '';
    while (Date.now() < deadline) {
      last = await ariaText(page);
      const found = last.includes(msg.text);
      if (msg.cmd === 'expect-text' && found) {
        return { ok: true, message: `found ${msg.text}` };
      }
      if (msg.cmd === 'expect-absent' && !found) {
        return { ok: true, message: `absent ${msg.text}` };
      }
      await page.waitForTimeout(200);
    }
    return {
      ok: false,
      error:
        msg.cmd === 'expect-text'
          ? `text not in the accessibility tree: ${msg.text}`
          : `text still in the accessibility tree: ${msg.text}`,
      detail: last,
    };
  }
  if (msg.cmd === 'expect-order') {
    const texts = Array.isArray(msg.texts) ? msg.texts.map((item) => String(item)) : [];
    if (texts.length < 2) {
      return { ok: false, error: 'expect-order needs at least two texts' };
    }
    const deadline = Date.now() + (msg.timeoutMs || 10000);
    let last = '';
    while (Date.now() < deadline) {
      last = await ariaText(page);
      let from = 0;
      let ordered = true;
      for (const text of texts) {
        const at = last.indexOf(text, from);
        if (at < 0) {
          ordered = false;
          break;
        }
        from = at + text.length;
      }
      if (ordered) return { ok: true, message: 'order ok' };
      await page.waitForTimeout(200);
    }
    return {
      ok: false,
      error: 'accessibility tree is not in the requested order',
      detail: last,
    };
  }
  if (msg.cmd === 'opens') {
    const opens = await page.evaluate(() => window.__cwcOpens || []);
    return { ok: true, message: opens.length ? opens.join('\n') : '(none)' };
  }
  if (msg.cmd === 'snapshot') {
    const file = evidencePath(msg.path);
    const body = await ariaText(page);
    const header = [
      `url: ${page.url()}`,
      `title: ${await page.title()}`,
      `feature: ${msg.feature || ''}`,
      '',
    ].join('\n');
    writePrivate(file, header + body);
    return { ok: true, message: `wrote ${file}` };
  }
  if (msg.cmd === 'screenshot') {
    const file = evidencePath(msg.path);
    refuseSymlink(file);
    await page.screenshot({ path: file, fullPage: false });
    fs.chmodSync(file, 0o600);
    return { ok: true, message: `wrote ${file}` };
  }
  if (msg.cmd === 'scroll-into-view') {
    const result = await scrollIntoView(page, msg.text);
    if (!result.ok) {
      return {
        ok: false,
        error: `could not scroll ${msg.text} into the viewport`,
        detail: await ariaText(page),
      };
    }
    return { ok: true, message: `visible ${msg.text}` };
  }
  if (msg.cmd === 'reload') {
    await page.reload({ waitUntil: 'domcontentloaded', timeout: 60000 });
    await enableAccessibility(page);
    await page.getByText('Before you continue', { exact: true }).waitFor({
      timeout: 30000,
    });
    return { ok: true, message: 'reloaded' };
  }
  return { ok: false, error: `unknown command ${msg.cmd}` };
}

async function handle(page, msg) {
  const result = await dispatch(page, msg);
  try {
    await persistOpens(page);
  } catch {
    // A failed log write must not hide the command result.
  }
  return result;
}

function runClient() {
  const socketPath = process.argv[3];
  const payload = process.argv[4];
  const sock = net.createConnection(socketPath);
  let buf = '';
  const fail = (message) => {
    process.stderr.write(`${message}\n`);
    process.exit(1);
  };
  sock.setTimeout(90000);
  sock.on('timeout', () => fail('browser command timed out'));
  sock.on('connect', () => sock.write(`${payload}\n`));
  sock.on('data', (chunk) => {
    buf += chunk.toString('utf8');
    const nl = buf.indexOf('\n');
    if (nl < 0) return;
    let response;
    try {
      response = JSON.parse(buf.slice(0, nl));
    } catch (err) {
      fail(`bad browser response: ${err.message}`);
    }
    if (!response.ok) {
      process.stderr.write(`${response.error || 'browser command failed'}\n`);
      if (response.detail) process.stderr.write(`${response.detail}\n`);
      process.exit(1);
    }
    if (response.message) process.stdout.write(`${response.message}\n`);
    process.exit(0);
  });
  sock.on('error', (err) => fail(`browser is not running (${err.message})`));
  sock.on('end', () => {
    if (!buf.includes('\n')) fail(buf || 'empty browser response');
  });
}

async function runSession(mode) {
  const url = process.env.CWC_URL;
  const stateDir = process.env.CWC_STATE;
  if (!url || !stateDir) {
    process.stderr.write('CWC_URL and CWC_STATE are required\n');
    process.exit(1);
  }
  const browser = await launchChrome();
  const context = await browser.newContext({
    viewport: { width: 430, height: 1200 },
    locale: 'en-US',
    deviceScaleFactor: 1,
  });
  const page = await context.newPage();
  try {
    await openApp(page, url);
  } catch (err) {
    await browser.close();
    process.stderr.write(`${err.message}\n`);
    process.exit(1);
  }
  try {
    await persistOpens(page);
  } catch {
    // The session can still serve commands if the log cannot be written.
  }
  if (mode === 'probe') {
    await browser.close();
    process.stdout.write('ready: Before you continue\n');
    process.exit(0);
  }

  const socketPath = path.join(stateDir, 'browser.sock');
  fs.rmSync(socketPath, { force: true });
  const server = net.createServer((conn) => {
    let buf = '';
    let replied = false;
    const reply = (response) => {
      if (replied) return;
      replied = true;
      try {
        conn.write(`${JSON.stringify(response)}\n`);
      } catch (err) {
        process.stderr.write(`browser reply failed: ${err.message}\n`);
      }
      conn.end();
    };
    conn.on('error', (err) => {
      process.stderr.write(`browser socket error: ${err.message}\n`);
    });
    conn.on('data', (chunk) => {
      buf += chunk.toString('utf8');
      const nl = buf.indexOf('\n');
      if (nl < 0) return;
      const line = buf.slice(0, nl);
      buf = buf.slice(nl + 1);
      let msg;
      try {
        msg = JSON.parse(line);
      } catch (err) {
        reply({ ok: false, error: `bad command: ${err.message}` });
        return;
      }
      handle(page, msg).then(reply).catch((err) => {
        reply({ ok: false, error: err.message });
      });
    });
  });
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(socketPath, resolve);
  });
  fs.writeFileSync(path.join(stateDir, 'browser.pid'), String(process.pid));
  process.stdout.write(`browser: ${socketPath}\n`);

  const shutdown = async () => {
    server.close();
    fs.rmSync(socketPath, { force: true });
    await browser.close();
    process.exit(0);
  };
  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
}

async function main() {
  const mode = process.argv[2];
  if (mode === 'check-path') {
    try {
      const found = resolveEvidenceFile(process.argv[3] || '');
      process.stdout.write(`ok ${found.finalPath}\n`);
    } catch (err) {
      process.stderr.write(`${err.message}\n`);
      process.exit(1);
    }
    return;
  }
  if (mode === 'write-text') {
    try {
      const file = evidencePath(process.argv[3] || '');
      writePrivate(file, process.argv[4] ?? '');
      process.stdout.write(`wrote ${file}\n`);
    } catch (err) {
      process.stderr.write(`${err.message}\n`);
      process.exit(1);
    }
    return;
  }
  if (mode === 'client') {
    runClient();
    return;
  }
  if (mode === 'probe' || mode === 'serve') {
    await runSession(mode);
    return;
  }
  process.stderr.write(
    'usage: browser-daemon.mjs probe|serve|client|check-path|write-text\n',
  );
  process.exit(2);
}

const entry = process.argv[1] ? path.resolve(process.argv[1]) : '';
if (entry && entry === fileURLToPath(import.meta.url)) {
  await main();
}
