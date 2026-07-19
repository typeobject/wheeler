// Verifies the semantic documentation bundle before exposing inert pages to Docusaurus.
import {createHash} from 'node:crypto';
import {cp, lstat, mkdir, readFile, readdir, rm, writeFile} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import path from 'node:path';

const docsRoot = path.dirname(fileURLToPath(import.meta.url));
const repository = path.resolve(docsRoot, '..');
const bundle = path.join(docsRoot, '.generated-bundle');
const generatedDocs = path.join(docsRoot, '.generated-docs');
const generatedStatic = path.join(docsRoot, '.generated-static');

await Promise.all([
  rm(bundle, {recursive: true, force: true}),
  rm(generatedDocs, {recursive: true, force: true}),
  rm(generatedStatic, {recursive: true, force: true}),
]);

const command = spawnSync(
    path.join(repository, 'bootstrap', 'gradlew'),
    [
      '-p',
      'bootstrap',
      '-q',
      ':tools:wheeler',
      '--args=docs docs/docs'
        + ' --wheeler wheeler-core/src/main/wheeler'
        + ' --wheeler wheeler-compiler/src/main/wheeler'
        + ' --wheeler wheeler-runtime/src/main/wheeler'
        + ' --wheeler wheeler-package/src/main/wheeler'
        + ' --wheeler wheeler-examples/src/main/wheeler'
        + ' -o docs/.generated-bundle',
    ],
    {cwd: repository, encoding: 'utf8', stdio: ['ignore', 'pipe', 'inherit']});
if (command.status !== 0) {
  process.stderr.write(command.stdout ?? '');
  process.exit(command.status ?? 1);
}

const manifestBytes = await readFile(path.join(bundle, 'manifest.json'));
const manifest = JSON.parse(manifestBytes.toString('utf8'));
if (manifest.profile !== 'wheeler-doc-bundle-1' || !Array.isArray(manifest.files)) {
  throw new Error('documentation bundle has an unsupported manifest profile');
}
const expected = new Set(['manifest.json']);
for (const entry of manifest.files) {
  if (typeof entry.path !== 'string' || !/^[A-Za-z0-9._/-]+$/.test(entry.path)
      || entry.path.startsWith('/') || entry.path.split('/').includes('..')) {
    throw new Error(`documentation bundle has an invalid path: ${entry.path}`);
  }
  if (expected.has(entry.path)) {
    throw new Error(`documentation bundle repeats ${entry.path}`);
  }
  const bytes = await readFile(path.join(bundle, entry.path));
  if (sha256(bytes) !== entry.sha256) {
    throw new Error(`documentation bundle digest mismatch: ${entry.path}`);
  }
  expected.add(entry.path);
}
const actual = new Set(await filesBelow(bundle));
if (actual.size !== expected.size || [...actual].some(file => !expected.has(file))) {
  throw new Error('documentation bundle contains an unmanifested file');
}

await mkdir(generatedDocs, {recursive: true});
await cp(path.join(bundle, 'pages'), generatedDocs, {recursive: true});
await mkdir(generatedStatic, {recursive: true});
const publication = {
  adapterIdentity: sha256(await readFile(fileURLToPath(import.meta.url))),
  bundleIdentity: sha256(manifestBytes),
  nodeIdentity: process.version,
  rendererLockIdentity: sha256(await readFile(path.join(docsRoot, 'package-lock.json'))),
};
await writeFile(
    path.join(generatedStatic, 'publication-manifest.json'),
    `${JSON.stringify(publication)}\n`,
    'utf8');

async function filesBelow(root) {
  const result = [];
  async function visit(directory) {
    for (const name of (await readdir(directory)).sort()) {
      const absolute = path.join(directory, name);
      const information = await lstat(absolute);
      if (information.isDirectory()) {
        await visit(absolute);
      } else if (information.isFile()) {
        result.push(path.relative(root, absolute).split(path.sep).join('/'));
      } else {
        throw new Error(`documentation bundle contains a special file: ${absolute}`);
      }
    }
  }
  await visit(root);
  return result;
}

function sha256(bytes) {
  return createHash('sha256').update(bytes).digest('hex');
}
