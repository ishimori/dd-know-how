# 運用スクリプト

このディレクトリにはドキュメント運用を機械検証するスクリプトが置かれている。

## ファイル

- `dd-index-gen.sh` — DD-INDEX.md の全量再生成（Bash 版・技術スタック非依存）
- `dd-health.sh` — DD運用ヘルスチェック（クローズ漏れ・滞留・ログ形骸化・DA雛形残置・ステータス語彙lintの静的分析。`--dd DD-NNN` で単一DDの即時チェック）
- `doc-check.sh` — DOC-MAP.md と doc/ 配下の整合性チェック（孤児ドキュメント・リンク切れ検出）
- `codex-review.sh` — Codexレビュー自動実行（**任意**。サブスク認証のCodex CLI導入時のみ。別モデル視点で実装差分をレビューさせAPI課金なし。`--check` で利用可否判定・トークン消費なし）

## パス設定（.dd-config）

全スクリプトは**自己位置からプロジェクトルートを解決**するため、どのディレクトリから実行してもよい（CWD非依存）。DD フォルダ等のパスは**ルート直下の `.dd-config`**（`templates/dd-config.example` 参照）から読む。

**⛔ スクリプト本体にプロジェクト固有のパスを書かないこと** — スクリプトは dd-know-how からの上書き更新で差し替わる配布物であり、設定は `.dd-config` だけが生き残る。

## 使い方

```bash
bash scripts/dd-index-gen.sh
# または明示的にパス指定（引数が .dd-config より優先）:
bash scripts/dd-index-gen.sh --dd-dir doc/DD --archive-dir doc/archived/DD

bash scripts/doc-check.sh            # 終了コード 0=整合 / 1=ERRORあり
bash scripts/doc-check.sh --doc-dir doc

bash scripts/dd-health.sh                     # 全体レポート（Markdown を stdout に出力）
bash scripts/dd-health.sh --dd DD-042 --new   # 作成直後のセルフチェック（DA雛形は正常扱い）
bash scripts/dd-health.sh --dd DD-042         # アーカイブ前チェック（ログ・DA記入も見る）
bash scripts/dd-health.sh --strict            # ⚠️があれば終了コード1（precheck組み込み用）
```

`dd-index-gen.sh` は `/dd rebuild-index` からも呼び出される。DD-INDEX の「進行中」「保留・見送り」「完了済み」はヘッダ表のステータス（固定6種: 検討中/進行中/確認待ち/保留/見送り/完了）と配置から自動分類され、補足列（4列目）が「補足」「理由」「主な成果」に流用される。
`doc-check.sh` は precheck（lint・テストと並ぶDD完了前の集約チェック）への組み込みを推奨。
`codex-review.sh` は Codex CLI が使える環境でのみ有効（任意機能）。`/dd` の新規作成フローが `--check` で自動判定し、使えなければCodexレビュータスクを省く。詳細は `templates/guides.md` §Codexレビューゲート。

---

## パフォーマンスについての気付き

`dd-index-gen.sh` は単一 `awk` で一括処理する作りになっており、200 件程度までは1秒以内で完了する。

ただし **Windows + Git Bash の組み合わせ** では、DD 件数が増えるとプロセス fork コストが累積して急激に遅くなる実例がある。

### 実例

ある社内プロジェクト（TypeScript ベース）では:

- DD 件数: **357 件**
- 環境: Windows 11 / Git Bash
- 実行時間: **約 27 秒**

実用に耐えなくなったため、Node.js (TypeScript) に移植して解決した。Linux / macOS や WSL 上では同じ件数でも .sh 版で問題ないと考えられる（fork コストが Windows 比で桁違いに低いため）。

### TS 版に移植すべきか判断する目安

以下が **すべて当てはまる** なら移植を検討する価値がある:

1. プロジェクトが TypeScript / Node.js を既に使っている（`tsx` などが導入済み）
2. 開発者の多くが **Windows + Git Bash** で作業している
3. DD 件数が **100 件を超える、または超えそう** で、体感で遅いと感じる

裏返すと、Linux/macOS/WSL 中心のチームや、件数が少ないプロジェクトでは .sh 版のままで何の問題もない。早すぎる移植は不要。

### 移植する場合の参考実装

下記の TypeScript 版は、.sh 版と**出力フォーマット・終了コード・コマンドライン引数・.dd-config の解釈を同一**に保つよう作られている。`/dd rebuild-index` 側の呼び出しコマンドを `bash scripts/dd-index-gen.sh` から `npx tsx scripts/dd-index-gen.ts` に差し替えるだけで置き換え可能。

`templates/scripts/dd-index-gen.ts` として保存し、`package.json` に `tsx` がない場合は `npm i -D tsx` で導入する。

> 旧版のTS移植をお使いの場合は下記で全面差し替えを推奨（旧版には「4列ヘッダ表で補足をステータスと誤読する」「完了済みの主な成果列が常に空になる」問題がある）。

```typescript
// dd-index-gen.ts — DD-INDEX.md の全量再生成（Node 版）
//
// DDフォルダとアーカイブの全DDファイルからメタデータを抽出し、
// DD-INDEX.md を生成する。冪等（何度実行しても同じ結果）。
//
// .sh 版で Windows + Git Bash + 数百件で遅くなる問題への対応。
// 出力フォーマット・終了コード・コマンドライン引数・.dd-config の解釈は .sh 版を忠実に踏襲。
//
// 使い方（どのディレクトリから実行してもよい・CWD非依存）:
//   npx tsx scripts/dd-index-gen.ts
//   npx tsx scripts/dd-index-gen.ts --dd-dir doc/DD --archive-dir doc/archived/DD

import { existsSync, readdirSync, readFileSync, writeFileSync } from 'node:fs'
import { join, basename, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

// --- プロジェクトルート解決と .dd-config 読み込み（CWD非依存） ---
// スクリプト自身の位置からルートを求める（想定配置: {ルート}/scripts/）。
const scriptDir = dirname(fileURLToPath(import.meta.url))
let projectRoot = dirname(scriptDir)
if (!existsSync(join(projectRoot, '.dd-config'))) {
  // scripts/ がルート直下にない配置向けフォールバック: 上方に .dd-config を探索
  let p = scriptDir
  for (;;) {
    if (existsSync(join(p, '.dd-config'))) {
      projectRoot = p
      break
    }
    const parent = dirname(p)
    if (parent === p) break
    p = parent
  }
}
process.chdir(projectRoot)

// .dd-config はシェル変数定義（KEY="value"）。必要な3キーだけ素朴にパースする
const config: Record<string, string> = {}
if (existsSync('.dd-config')) {
  for (const line of readFileSync('.dd-config', 'utf-8').split(/\r?\n/)) {
    const m = line.match(/^\s*(DD_DIR|ARCHIVE_DIR|DOC_DIR)\s*=\s*"?([^"#]*?)"?\s*(#.*)?$/)
    if (m && m[2].trim() !== '') config[m[1]] = m[2].trim()
  }
}

// --- Default paths（.dd-config が無い場合の既定値） ---
let ddDir = (config.DD_DIR ?? 'doc/DD').replace(/\/+$/, '')
let archiveDir = (config.ARCHIVE_DIR ?? 'doc/archived/DD').replace(/\/+$/, '')
// .dd-config なしで既定が外れている場合の救済: docs/ 配置を自動検出
if (!existsSync('.dd-config') && !existsSync(ddDir) && existsSync('docs/DD')) {
  ddDir = 'docs/DD'
  if (existsSync('docs/archived/DD')) archiveDir = 'docs/archived/DD'
}

// --- Parse arguments（引数が .dd-config より優先） ---
const argv = process.argv.slice(2)
for (let i = 0; i < argv.length; i++) {
  const a = argv[i]
  if (a === '--dd-dir') {
    ddDir = argv[++i]
  } else if (a === '--archive-dir') {
    archiveDir = argv[++i]
  } else {
    console.error(`Unknown option: ${a}`)
    process.exit(1)
  }
}

const indexFile = join(ddDir, 'DD-INDEX.md')

// --- Validate directories ---
if (!existsSync(ddDir)) {
  console.error(`ERROR: DDフォルダが見つかりません: ${ddDir}（基準: ${projectRoot}）`)
  console.error('  対処: プロジェクトルート直下に .dd-config を作成し、実パスを設定してください。例:')
  console.error('    DD_DIR="doc/DD"')
  console.error('    ARCHIVE_DIR="doc/archived/DD"')
  console.error('  （一時的な指定は --dd-dir / --archive-dir 引数でも可）')
  process.exit(1)
}

// --- Collect DD files ---
const collectDdFiles = (dir: string): string[] => {
  if (!existsSync(dir)) return []
  return readdirSync(dir)
    .filter((f) => f.startsWith('DD-') && f.endsWith('.md') && f !== 'DD-INDEX.md')
    .map((f) => join(dir, f))
}

const ddFiles = collectDdFiles(ddDir)
const archiveFiles = collectDdFiles(archiveDir)
const total = ddFiles.length + archiveFiles.length

const EMPTY_INDEX = `# DD 索引

> \`npx tsx scripts/dd-index-gen.ts\` で自動生成。手動編集禁止。

## 進行中

| DD | 件名 | ステータス | 補足 |
|----|------|-----------|------|

## 保留・見送り

| DD | 件名 | ステータス | 理由 |
|----|------|-----------|------|

## 完了済み

| DD | 件名 | 主な成果 |
|----|------|---------|
`

if (total === 0) {
  writeFileSync(indexFile, EMPTY_INDEX)
  console.log(`DD-INDEX.md updated: ${indexFile} (0 件)`)
  process.exit(0)
}

// --- Extract metadata from each file ---
type Section = 'active' | 'hold' | 'archived'
type Entry = {
  section: Section
  ddNumber: string
  title: string
  status: string
  hosoku: string
  sortKey: number
}

const META_ROW = /^\| *(\d{4}-\d{2}-\d{2})[^\n]*$/m

const extractEntry = (filepath: string, location: 'active' | 'archived'): Entry => {
  const fname = basename(filepath, '.md')
  const sepIdx = fname.indexOf('_')
  const ddNumber = sepIdx > 0 ? fname.slice(0, sepIdx) : fname
  const title = sepIdx > 0 ? fname.slice(sepIdx + 1) : '(タイトルなし)'

  // ステータス・補足抽出: 先頭 6 行のメタデータテーブル行（| YYYY-MM-DD ... |）から
  // .sh 版の awk は FS='|' の $4 / $5 に相当（先頭の '|' により fields[0] が空になるため
  // fields[3] = ステータス、fields[4] = 補足。3列の旧ヘッダ表では補足は空）
  let status = 'N/A'
  let hosoku = ''
  try {
    const content = readFileSync(filepath, 'utf-8')
    const lines = content.split(/\r?\n/).slice(0, 6)
    for (const line of lines) {
      if (META_ROW.test(line)) {
        const fields = line.split('|').map((s) => s.trim())
        if (fields[3]) status = fields[3]
        if (fields[4]) hosoku = fields[4]
        break
      }
    }
  } catch {
    // ファイル読み込み失敗時は status = 'N/A' のまま
  }

  // セクション判定: ステータスが 保留/見送り で始まれば hold（配置に関わらず優先）
  const section: Section = /^(保留|見送り)/.test(status) ? 'hold' : location

  // ソートキー: DD番号から先頭のアルファベットプレフィックス（DD-、DD○-）を除去し、最初の数値部分
  // 例: 'DD-139-2' → '139', 'DD-099-10' → '099'
  const numericPart = ddNumber.replace(/^DD[A-Z]*-/, '').split('-')[0]
  const sortKey = Number(numericPart) || 0

  return { section, ddNumber, title, status, hosoku, sortKey }
}

const entries: Entry[] = [
  ...ddFiles.map((f) => extractEntry(f, 'active')),
  ...archiveFiles.map((f) => extractEntry(f, 'archived')),
]

// --- Build output ---
// ソート: sortKey 降順、同 sortKey 内では ddNumber の ASCII 昇順
// （ASCII では `-` (0x2D) < `_` (0x5F) なので、'DD-118-1' < 'DD-118' となり、
// 子 DD（DD-118-1）が親 DD（DD-118）より先に来る）
const sortFn = (a: Entry, b: Entry): number => {
  if (b.sortKey !== a.sortKey) return b.sortKey - a.sortKey
  return a.ddNumber < b.ddNumber ? -1 : a.ddNumber > b.ddNumber ? 1 : 0
}
const activeEntries = entries.filter((e) => e.section === 'active').sort(sortFn)
const holdEntries = entries.filter((e) => e.section === 'hold').sort(sortFn)
const archivedEntries = entries.filter((e) => e.section === 'archived').sort(sortFn)

const lines: string[] = []
lines.push('# DD 索引')
lines.push('')
lines.push('> `npx tsx scripts/dd-index-gen.ts` で自動生成。手動編集禁止。')
lines.push('')

// 進行中
lines.push('## 進行中')
lines.push('')
lines.push('| DD | 件名 | ステータス | 補足 |')
lines.push('|----|------|-----------|------|')
for (const e of activeEntries) {
  lines.push(`| ${e.ddNumber} | ${e.title} | ${e.status} | ${e.hosoku} |`)
}
lines.push('')

// 保留・見送り（固定語彙 保留/見送り のステータスを自動検出）
lines.push('## 保留・見送り')
lines.push('')
lines.push('| DD | 件名 | ステータス | 理由 |')
lines.push('|----|------|-----------|------|')
for (const e of holdEntries) {
  lines.push(`| ${e.ddNumber} | ${e.title} | ${e.status} | ${e.hosoku} |`)
}
lines.push('')

// 完了済み（「主な成果」は補足を優先し、無ければステータスを流用 = 旧運用の後方互換）
lines.push('## 完了済み')
lines.push('')
lines.push('| DD | 件名 | 主な成果 |')
lines.push('|----|------|---------|')
for (const e of archivedEntries) {
  lines.push(`| ${e.ddNumber} | ${e.title} | ${e.hosoku || e.status} |`)
}

writeFileSync(indexFile, lines.join('\n') + '\n')

console.log(
  `DD-INDEX.md updated: ${indexFile} (${total} 件: active=${activeEntries.length}, hold=${holdEntries.length}, archived=${archivedEntries.length})`
)
```
