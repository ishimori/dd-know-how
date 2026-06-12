/**
 * PostToolUse Hook: post-edit-lint.mjs
 *
 * Edit/Write 直後に編集ファイル単独で ESLint を実行し、エラーを
 * 修正ヒント付きで Claude にフィードバックする（exit 2 = Claudeに表示）。
 * 「編集 → その場でP規約付きエラー → 自己修正」のループをセッション内で閉じる。
 *
 * 設計判断（nanairoware3 での運用評価より）:
 *   - tsc は実行しない: 型チェックは遅く（10秒超）Hookには侵襲的すぎる。
 *     型チェックは build / precheck で実行する運用に留める。
 *   - 型情報依存ルール（recommendedTypeChecked）を除外した Fast 設定を推奨
 *     （tools/eslint-fast.config.js があればそれを優先使用、〜1.5s）。
 *     無ければプロジェクト標準の eslint 設定で実行する。
 *   - ヒント辞書 tools/lint-fix-hints.json があれば ruleId → 修正方針 を付記。
 *
 * 一時無効化: 環境変数 CLAUDE_HOOK_SKIP=1
 * 配置先: .claude/hooks/post-edit-lint.mjs
 */

import { resolve, extname } from 'node:path';
import { existsSync, readFileSync } from 'node:fs';

if (process.env.CLAUDE_HOOK_SKIP === '1') process.exit(0);

function readStdin() {
  return new Promise((res) => {
    let data = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', (chunk) => (data += chunk));
    process.stdin.on('end', () => res(data));
  });
}

const raw = await readStdin();
let input;
try {
  input = JSON.parse(raw);
} catch {
  process.exit(0);
}

const rawFilePath = input.tool_input?.file_path;
if (!rawFilePath) process.exit(0);

// MSYS / Cygwin スタイル（/c/repo/...）を Windows パス（C:/repo/...）へ変換
const filePath = rawFilePath.replace(/^\/([a-z])\//i, (_, drive) => `${drive.toUpperCase()}:/`);
const normalized = filePath.replace(/\\/g, '/');
const ext = extname(normalized).toLowerCase();

// 除外: 生成物・依存物・lint対象外の拡張子
const EXCLUDE_DIRS = ['/node_modules/', '/dist/', '/build/', '/.next/', '/generated/'];
if (EXCLUDE_DIRS.some((d) => normalized.includes(d))) process.exit(0);

const ESLINT_EXTENSIONS = new Set(['.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs']);
if (!ESLINT_EXTENSIONS.has(ext)) process.exit(0);

const projectRoot = resolve(import.meta.dirname, '..', '..');

// ヒント辞書（任意）: tools/lint-fix-hints.json
let hints = {};
try {
  const hintsPath = resolve(projectRoot, 'tools', 'lint-fix-hints.json');
  if (existsSync(hintsPath)) {
    hints = JSON.parse(readFileSync(hintsPath, 'utf8'));
  }
} catch {
  // ヒント読み込み失敗時はヒントなしで続行
}

try {
  const { ESLint } = await import('eslint');

  // Fast 設定があれば優先（型情報ルール除外で高速）。無ければ標準設定。
  const fastConfig = resolve(projectRoot, 'tools', 'eslint-fast.config.js');
  const options = { cwd: projectRoot };
  if (existsSync(fastConfig)) options.overrideConfigFile = fastConfig;

  const eslint = new ESLint(options);

  // eslint 設定の ignores 対象なら何もしない
  if (await eslint.isPathIgnored(filePath)) process.exit(0);

  const results = await eslint.lintFiles([filePath]);
  const errorMessages = results.flatMap((r) =>
    r.messages
      .filter((m) => m.severity === 2) // error のみ（warn は通知しない）
      .map((m) => {
        const base = `${r.filePath}:${m.line}:${m.column} ${m.ruleId}: ${m.message}`;
        const hint = hints[m.ruleId];
        return hint ? `${base}\n  → 修正ヒント: ${hint}` : base;
      })
  );

  if (errorMessages.length > 0) {
    process.stderr.write(
      `[post-edit-lint] ESLint エラー（編集ファイル単独）:\n${errorMessages.join('\n')}\n`
    );
    process.exit(2); // exit 2 → Claude にフィードバックされる
  }
} catch {
  // ESLint 自体のエラー（未導入・設定不備等）で開発を止めない
}

process.exit(0);
