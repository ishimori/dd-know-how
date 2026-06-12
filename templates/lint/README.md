# Lintヒント基盤 — LintエラーをLLMの自己修正ヒントにする

LLMがコードを書く → Lintが「何が悪いか + どう直すか（P規約ID付き）」を返す → LLMがその場で自己修正する、というループを作るためのテンプレート一式。`coding-standards.md` の「機械的強制の対応状況」表の実体がここにある。

## 構成（3層）

| 層 | ファイル | 役割 |
|----|---------|------|
| 1. ルール | `eslint.config.snippet.mjs` / `ruff.snippet.toml` | P規約のうちLint化可能なもの（P01-P03, P19-P22）を有効化。メッセージを書けるルールには修正方針を埋め込み済み |
| 2. ヒント辞書 | `lint-fix-hints.json` | メッセージを変更できないルール向けに ルールID → P規約 → 修正方針 を対応付け |
| 3. 即時フィードバック | `../hooks/post-edit-lint.mjs` | Edit/Write 直後に編集ファイル単独でESLintを実行し、エラー+ヒントをClaudeに返す（PostToolUse hook） |

層1・2だけでも機能する（Claudeが `npm run lint` を実行した時にヒントが効く）。層3を入れるとコミット前ではなく**編集直後**に自己修正が走る。

## 導入手順

### TypeScript プロジェクト

1. `eslint.config.snippet.mjs` を `doc/templates/lint/` 等に配置し、プロジェクトの `eslint.config.js`（Flat Config）にマージ:
   ```js
   import { ddCodingStandards } from './doc/templates/lint/eslint.config.snippet.mjs';
   export default [ /* 既存設定 */, ddCodingStandards ];
   ```
2. `lint-fix-hints.json` を `tools/lint-fix-hints.json` に配置（プロジェクト固有ルールのヒントを追記してよい）
3. （任意・推奨）hook を導入: `post-edit-lint.mjs` を `.claude/hooks/` に配置し、`.claude/settings.json` の `hooks.PostToolUse` に登録（**設定ファイルの編集は人間が行う**）:
   ```json
   {
     "matcher": "Edit|Write",
     "hooks": [{ "type": "command", "command": "node .claude/hooks/post-edit-lint.mjs" }]
   }
   ```
4. （任意）大規模プロジェクトでは型情報ルールを除外した Fast 設定 `tools/eslint-fast.config.js` を用意すると hook が約1.5秒で完走する（型情報付きは10秒超になりHookには不向き。型チェックは build / precheck で実行する）

### Python（FastAPI）プロジェクト

1. `ruff.snippet.toml` の内容を `pyproject.toml` の `[tool.ruff.lint]` にマージ
2. `lint-fix-hints.json` の ruff エントリ（PGH003 / ANN401 / FIX002 / T201 / S608）はそのまま使える

## 運用ルール

- hook を一時的に止めたい場合: 環境変数 `CLAUDE_HOOK_SKIP=1`
- 既存コードが多いプロジェクトでは P02/P03 を `warn` のまま導入し、段階修正後に `error` へ昇格する（coding-standards.md の表と同じ方針）
- ヒント辞書にプロジェクト固有ルールを追加した場合、その知見はDD本体にも書き戻す
