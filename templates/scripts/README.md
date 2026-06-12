# 運用スクリプト

このディレクトリにはドキュメント運用を機械検証するスクリプトが置かれている。

## ファイル

- `dd-index-gen.sh` — DD-INDEX.md の全量再生成（Bash 版・技術スタック非依存）
- `doc-check.sh` — DOC-MAP.md と doc/ 配下の整合性チェック（孤児ドキュメント・リンク切れ検出）

## 使い方

```bash
bash scripts/dd-index-gen.sh
# または明示的にパス指定:
bash scripts/dd-index-gen.sh --dd-dir doc/DD --archive-dir doc/archived/DD

bash scripts/doc-check.sh            # 終了コード 0=整合 / 1=ERRORあり
bash scripts/doc-check.sh --doc-dir doc
```

`dd-index-gen.sh` は `/dd rebuild-index` からも呼び出される。
`doc-check.sh` は precheck（lint・テストと並ぶDD完了前の集約チェック）への組み込みを推奨。

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

下記の TypeScript 版は、.sh 版と**出力フォーマット・終了コード・コマンドライン引数を完全に同一**に保つよう作られている。`/dd rebuild-index` 側の呼び出しコマンドを `bash scripts/dd-index-gen.sh` から `npx tsx scripts/dd-index-gen.ts` に差し替えるだけで置き換え可能。

`templates/scripts/dd-index-gen.ts` として保存し、`package.json` に `tsx` がない場合は `npm i -D tsx` で導入する。

```typescript
// dd-index-gen.ts — DD-INDEX.md の全量再生成（Node 版）
//
// DDフォルダとアーカイブの全DDファイルからメタデータを抽出し、
// DD-INDEX.md を生成する。冪等（何度実行しても同じ結果）。
//
// .sh 版で Windows + Git Bash + 数百件で遅くなる問題への対応。
// 出力フォーマット・終了コード・コマンドライン引数は .sh 版を忠実に踏襲。
//
// 使い方:
//   npx tsx scripts/dd-index-gen.ts
//   npx tsx scripts/dd-index-gen.ts --dd-dir doc/DD --archive-dir doc/archived/DD

import { existsSync, readdirSync, readFileSync, writeFileSync } from 'node:fs'
import { join, basename } from 'node:path'

// --- Parse arguments ---
let ddDir = 'doc/DD'
let archiveDir = 'doc/archived/DD'
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
  console.error(`ERROR: DD directory not found: ${ddDir}`)
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

| DD | 件名 | ステータス |
|----|------|-----------|

## 保留・見送り

| DD | 件名 | 理由 |
|----|------|------|

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
type Entry = {
  location: 'active' | 'archived'
  ddNumber: string
  title: string
  status: string
  sortKey: number
}

const META_ROW = /^\| *(\d{4}-\d{2}-\d{2})[^\n]*$/m

const extractEntry = (filepath: string, location: 'active' | 'archived'): Entry => {
  const fname = basename(filepath, '.md')
  const sepIdx = fname.indexOf('_')
  const ddNumber = sepIdx > 0 ? fname.slice(0, sepIdx) : fname
  const title = sepIdx > 0 ? fname.slice(sepIdx + 1) : '(タイトルなし)'

  // ステータス抽出: 先頭 6 行のメタデータテーブル行（| YYYY-MM-DD ... |）の 4 番目のフィールド
  let status = 'N/A'
  try {
    const content = readFileSync(filepath, 'utf-8')
    const lines = content.split(/\r?\n/).slice(0, 6)
    for (const line of lines) {
      if (META_ROW.test(line)) {
        const fields = line.split('|').map((s) => s.trim())
        // .sh 版の awk は FS='|' で先頭の '|' により最初のフィールドが空、4 番目がステータス
        // 例: '| 2026-05-12 | 2026-05-12 | 完了 |' → ['', '2026-05-12', '2026-05-12', '完了', '']
        if (fields.length >= 5 && fields[4] !== '') {
          status = fields[4]
        } else if (fields[3] !== undefined && fields[3] !== '') {
          status = fields[3]
        }
        break
      }
    }
  } catch {
    // ファイル読み込み失敗時は status = 'N/A' のまま
  }

  // ソートキー: DD番号から先頭のアルファベットプレフィックス（DD-、DD○-）を除去し、最初の数値部分
  // 例: 'DD-139-2' → '139', 'DD-099-10' → '099'
  const numericPart = ddNumber.replace(/^DD[A-Z]*-/, '').split('-')[0]
  const sortKey = Number(numericPart) || 0

  return { location, ddNumber, title, status, sortKey }
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
const activeEntries = entries.filter((e) => e.location === 'active').sort(sortFn)
const archivedEntries = entries.filter((e) => e.location === 'archived').sort(sortFn)

const lines: string[] = []
lines.push('# DD 索引')
lines.push('')
lines.push('> `npx tsx scripts/dd-index-gen.ts` で自動生成。手動編集禁止。')
lines.push('')

// 進行中
lines.push('## 進行中')
lines.push('')
lines.push('| DD | 件名 | ステータス |')
lines.push('|----|------|-----------|')
for (const e of activeEntries) {
  lines.push(`| ${e.ddNumber} | ${e.title} | ${e.status} |`)
}
lines.push('')

// 保留・見送り（自動検出不可、手動キュレーション用の空セクション）
lines.push('## 保留・見送り')
lines.push('')
lines.push('| DD | 件名 | 理由 |')
lines.push('|----|------|------|')
lines.push('')

// 完了済み
lines.push('## 完了済み')
lines.push('')
lines.push('| DD | 件名 | 主な成果 |')
lines.push('|----|------|---------|')
for (const e of archivedEntries) {
  lines.push(`| ${e.ddNumber} | ${e.title} | |`)
}

writeFileSync(indexFile, lines.join('\n') + '\n')

console.log(`DD-INDEX.md updated: ${indexFile} (${total} 件: active=${activeEntries.length}, archived=${archivedEntries.length})`)
```
