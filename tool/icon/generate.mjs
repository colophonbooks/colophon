// Colophon のアプリアイコンを各 OS 向けに書き出す。
//
// 使い方（リポジトリのルートで）:
//   npm install --prefix tool/icon
//   node tool/icon/generate.mjs
//
// 図柄と色はこのファイルが唯一の原本。直したらこのスクリプトを実行し、書き出されたファイルごとコミットする。
// 描画には puppeteer（Chrome）を使う。インストール済みの Chrome を使うときは CHROME_PATH を指定する。
import { mkdirSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const puppeteer = require(process.env.PUPPETEER_MODULE ?? 'puppeteer');
const repo = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const appId = 'io.github.colophonbooks.colophon';

// A1b「洋書の装丁・薄水」: 深緑・紺・えんじの本に金の帯、オレンジの付箋、淡い水色の台座
const C = {
  plate: '#D8EAF2', shelf: '#B8D2DF',
  books: [['#2F5D50', '#C9A75A'], ['#25395C', '#C9A75A'], ['#8C2F39', '#D9B86A']],
  tab: ['#E9A23B', '#C98417'],
};

// detail: full（96px 以上）/ mid（48〜64px: 付箋の折り返しを省く）/ small（40px 以下: 帯と棚も省く）
// frame: grid（台座 824/1024。macOS・Linux の標準の余白）/ tight（台座を枠いっぱいに近づける）
// shadow: macOS の大きいサイズだけ、台座の下に影を落とす
function svg({ detail, frame, shadow = false }) {
  const [b1, b2, b3] = C.books;
  const full = detail === 'full', small = detail === 'small';
  const band = (x, y, w, h, c) => (small ? '' : `<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${c}"/>`);
  const viewBox = frame === 'tight' ? '76 76 872 872' : '0 0 1024 1024';
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox}">` +
    (shadow ? '<defs><filter id="s" x="-10%" y="-10%" width="120%" height="125%"><feDropShadow dx="0" dy="10" stdDeviation="12" flood-color="#000" flood-opacity="0.28"/></filter></defs>' : '') +
    `<rect x="100" y="100" width="824" height="824" rx="185" fill="${C.plate}"${shadow ? ' filter="url(#s)"' : ''}/>` +
    (small ? '' : `<rect x="210" y="742" width="604" height="30" rx="15" fill="${C.shelf}"/>`) +
    `<rect x="238" y="352" width="156" height="400" rx="20" fill="${b1[0]}"/>` +
    band(238, 412, 156, 26, b1[1]) + band(238, 672, 156, 26, b1[1]) +
    `<rect x="488" y="132" width="132" height="190" rx="14" fill="${C.tab[0]}"/>` +
    (full ? `<path d="M584 132 h22 a14 14 0 0 1 14 14 v22 z" fill="${C.tab[1]}"/>` : '') +
    `<rect x="414" y="250" width="178" height="502" rx="20" fill="${b2[0]}"/>` +
    band(414, 318, 178, 26, b2[1]) + band(414, 670, 178, 26, b2[1]) +
    `<g transform="rotate(-11 786 752)"><rect x="628" y="372" width="146" height="380" rx="20" fill="${b3[0]}"/>` +
    band(628, 432, 146, 24, b3[1]) + band(628, 676, 146, 24, b3[1]) + '</g></svg>\n';
}

const detailFor = (px) => (px >= 96 ? 'full' : px >= 48 ? 'mid' : 'small');

const targets = [
  // Windows: 表示倍率 100〜250% とエクスプローラーの各表示で使われるサイズ
  ...[16, 20, 24, 32, 40, 48, 64, 256].map((px) => ({ kind: 'ico', px, detail: detailFor(px), frame: 'tight' })),
  // macOS: AppIcon.appiconset（Contents.json が参照するファイル名）
  ...[16, 32, 64, 128, 256, 512, 1024].map((px) => ({
    out: `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_${px}.png`,
    px, detail: detailFor(px), frame: 'grid', shadow: px >= 64,
  })),
  // Linux: hicolor テーマ。小さいサイズは台座を詰めて、縮みすぎないようにする
  ...[16, 24, 32, 48, 64, 128, 256, 512].map((px) => ({
    out: `installer/linux/icons/hicolor/${px}x${px}/apps/${appId}.png`,
    px, detail: detailFor(px), frame: px <= 32 ? 'tight' : 'grid',
  })),
];

const browser = await puppeteer.launch({
  ...(process.env.CHROME_PATH ? { executablePath: process.env.CHROME_PATH } : {}),
  args: ['--no-sandbox'],
});
const page = await browser.newPage();
async function render(t) {
  await page.setViewport({ width: t.px, height: t.px, deviceScaleFactor: 1 });
  const markup = svg(t).replace('<svg ', `<svg width="${t.px}" height="${t.px}" `);
  await page.setContent(`<html><body style="margin:0;background:transparent">${markup}</body></html>`);
  return page.screenshot({ type: 'png', omitBackground: true, clip: { x: 0, y: 0, width: t.px, height: t.px } });
}

const write = (rel, data) => {
  const path = join(repo, rel);
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, data);
  console.log(rel);
};

const icoImages = [];
for (const t of targets) {
  const png = await render(t);
  if (t.kind === 'ico') icoImages.push({ px: t.px, png });
  else write(t.out, png);
}
await browser.close();

// .ico は PNG 圧縮のエントリを並べる（Windows Vista 以降・Inno Setup が読める形式）
function ico(images) {
  const header = Buffer.alloc(6);
  header.writeUInt16LE(0, 0);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(images.length, 4);
  let offset = 6 + 16 * images.length;
  const entries = images.map(({ px, png }) => {
    const e = Buffer.alloc(16);
    e.writeUInt8(px >= 256 ? 0 : px, 0);
    e.writeUInt8(px >= 256 ? 0 : px, 1);
    e.writeUInt16LE(1, 4);
    e.writeUInt16LE(32, 6);
    e.writeUInt32LE(png.length, 8);
    e.writeUInt32LE(offset, 12);
    offset += png.length;
    return e;
  });
  return Buffer.concat([header, ...entries, ...images.map((i) => i.png)]);
}
write('windows/runner/resources/app_icon.ico', ico(icoImages));

// 原本の SVG と、Linux のアイコンテーマ用の拡大縮小できる版（中身は同じ）
const master = svg({ detail: 'full', frame: 'grid' });
write('tool/icon/colophon.svg', master);
write(`installer/linux/icons/hicolor/scalable/apps/${appId}.svg`, master);
