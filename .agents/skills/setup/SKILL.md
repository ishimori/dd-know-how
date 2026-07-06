---
name: setup
description: DD設計書セットアップコマンド
---

# DD設計書セットアップコマンド

外部プロジェクトにDD設計書の仕組みを導入するコマンドです。

## 使い方

```
/setup {対象プロジェクトのパス}
```

**例:**
- `/setup /path/to/my-project`
- `/setup ../my-other-project`
- `/setup` （カレントディレクトリ以外のプロジェクトを対話で指定）

## 前提条件

このコマンドは **dd-know-how リポジトリ内** で実行します。
（dd-know-how がセットアップのソースとなります）

## セットアップ手順

### 1. 対象プロジェクトの確認

引数でパスが指定された場合:
- そのパスが存在し、ディレクトリであることを確認
- 確認できない場合はエラーメッセージを表示

引数がない場合:
- ユーザーに対象プロジェクトのパスを質問

### 2. 導入レベルの選択

ユーザーに導入レベルを確認:

| レベル | 内容 | 推奨ケース |
|--------|------|------------|
| Level 1（最小） | テンプレート + 基本ルール | まず試したい |
| Level 2（標準） | + /dd コマンド + DA メソッド文書 | 通常利用 |

### 3. DDフォルダの配置先を決定

対象プロジェクトのフォルダ構造を確認し、以下の優先順位で提案:

1. `doc/` フォルダが存在 → `doc/DD/` を提案
2. `docs/` フォルダが存在 → `docs/DD/` を提案
3. どちらもない → `doc/DD/`（推奨）またはカスタムパスを選択させる

**ユーザーに確認**: 「DDフォルダを {提案パス} に作成します。よろしいですか？」

カスタムパスを指定したい場合はユーザー入力を受け付ける。

### 4. ファイルのコピー

確定した設定に基づき、以下のファイルをコピー:

#### Level 1（最小構成）
```
{対象プロジェクト}/
├── {DDフォルダ}/              # 例: doc/DD/
│   ├── DD-INDEX.md           # ← templates/DD-INDEX.md（検索インデックス）
│   └── (空、またはサンプルDD)
├── {DDフォルダ}/../DOC-MAP.md  # ← templates/DOC-MAP.md（ドキュメントインデックス。実パスに合わせて表内を調整）
├── {DDフォルダ}/../templates/
│   ├── dd_template.md        # ← templates/dd_template.md
│   ├── dd_template_bugfix.md # ← templates/dd_template_bugfix.md（差分テンプレート）
│   ├── dd_template_tdd.md    # ← templates/dd_template_tdd.md（差分テンプレート）
│   ├── dd_template_mock.md   # ← templates/dd_template_mock.md（差分テンプレート）
│   ├── dd_template_e2e.md    # ← templates/dd_template_e2e.md（差分テンプレート）
│   ├── guides.md             # ← templates/guides.md（アプローチ選択ガイド）
│   └── coding-standards.md   # ← templates/coding-standards.md（コーディング基準書）
└── {DDフォルダ}/../archived/DD/
    └── (空フォルダ)
```

#### Level 2（標準構成）- Level 1 に加えて
```
{対象プロジェクト}/
├── .agents/
│   ├── hooks/
│   │   ├── post-bash-dd-archive-reminder.sh  # ← templates/hooks/（アーカイブ時INDEX更新リマインダー）
│   │   ├── pre-edit-guard.sh                 # ← templates/hooks/（重要ファイル編集ガード）
│   │   └── post-edit-lint.mjs                # ← templates/hooks/（Lint即時フィードバック。ステップ7bで導入を選択した場合のみ）
│   └── skills/
│       └── dd/
│           └── SKILL.md      # ← skills/dd/SKILL.md
├── scripts/
│   ├── dd-index-gen.sh       # ← templates/scripts/（INDEX全量再生成スクリプト）
│   └── dd-update.sh          # ← templates/scripts/（Pull型更新の呼び出し口。本体は dd-know-how 側）
├── .dd-config                # ← templates/dd-config.example から生成（ステップ8: 機械向けパス設定の単一ソース）
└── AGENTS.md                 # ← templates/AGENTS.md.snippet をベースに作成（ステップ6）
```

### 5. Hooks の設定（Level 2 のみ）

> ⚠️ **本章の Hooks（`settings.json` の `PreToolUse`/`PostToolUse`）は Claude Code 互換ハーネスでのみ有効。** 素の Codex CLI（`AGENTS.md` + `~/.codex/config.toml` 方式）にはこの tool-matcher フック機構が無いため、下記 JSON はそのままでは適用できない。Codex CLI 単体で運用する場合は本章をスキップしてよい（DDフロー自体はフックなしでも成立する）。

以下の推奨設定をユーザーに表示する。**設定ファイルの編集はLLMが行ってはならない。人間が手動で設定すること。**

Hooks はLLMの行動を制限するガードレールであり、LLM自身が設定・変更すべきではない。

```
📋 Hooks の設定が必要です。
以下の JSON を .agents/settings.json（チーム共有）または
.agents/settings.local.json（個人設定）の "hooks" キーに追加してください。

既存の PreToolUse / PostToolUse 配列がある場合は末尾に追加してください。
```

推奨設定:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash .agents/hooks/pre-edit-guard.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash .agents/hooks/post-bash-dd-archive-reminder.sh",
            "timeout": 5
          }
        ]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "node .agents/hooks/post-edit-lint.mjs",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
```

> `PostToolUse` の `Edit|Write` エントリは、Lintヒント基盤（ステップ7b）の導入を選択した場合のみ追加する。

**⛔ LLMによる settings.json / settings.local.json の編集は禁止。** ユーザーが設定完了を報告するまで待つこと。

### 6. AGENTS.md の作成・更新

`templates/AGENTS.md.snippet` をベースに作成する。**全体を50行程度に収めること**（AGENTS.md は全セッションのコンテキストに常駐するため、詳細は doc/ 配下に置き、AGENTS.md はポインタ集に徹する）。

- **存在しない場合**: スニペットをコピーし、`{...}` プレースホルダ（プロジェクト説明・技術スタック・コマンド）を対象プロジェクトの実体（package.json / pyproject.toml 等）から埋める。実体から判断できない項目はユーザーに確認する
- **存在する場合**: スニペットのうち「DD設定」「コーディング規約」「ドキュメント更新義務」セクションのみ末尾に追記（重複チェック）。既存内容の削除・要約はユーザーの合意なしに行わない
- 50行を大きく超える内容（コマンドの詳細説明・運用手順など）は doc/ 配下のドキュメントに移し、AGENTS.md からはパスで参照する

### 7. オプション導入の提案

レベル・技術スタックに応じて以下を提案する。**いずれも任意 — ユーザーの合意を得てから実施する。**

#### 7a. Playwright MCP（推奨 — Codexに「目」を与える）

エビデンス取得（guides.md）は Playwright MCP を前提としている。利用可能か確認し、未導入なら:

1. `templates/mcp/mcp.json` を対象プロジェクト直下に `.mcp.json` としてコピー（既存の `.mcp.json` がある場合は `mcpServers.playwright` エントリをマージ）
2. ユーザーに伝える: **Codex の再起動後に有効**になること、初回利用時にブラウザバイナリのダウンロードが走ること
3. 再起動後の動作確認: `browser_navigate` で任意のページが開ければOK

#### 7b. Lintヒント基盤（TypeScript / Python プロジェクト向け）

Lintエラーを「P規約ID + 修正方針」付きでLLMに返し、自己修正ループを作る仕組み。詳細手順は `templates/lint/README.md` に従う:

1. `templates/lint/` 一式を `{テンプレートフォルダ}/lint/` にコピー
2. ヒント辞書を `tools/lint-fix-hints.json` にコピー
3. ESLint（TS）/ ruff（Python）の設定にスニペットをマージ
4. `templates/hooks/post-edit-lint.mjs` を `.agents/hooks/` にコピー。**settings.json への hook 登録はステップ5と同様、人間が行う**

### 8. パス設定の調整

**機械向け（スクリプト・フックの単一ソース）**: `templates/dd-config.example` をプロジェクトルート直下に `.dd-config` としてコピーし、`DD_DIR` / `ARCHIVE_DIR` / `DOC_DIR` を確定した実パスに設定する（Level 2）。

**⛔ scripts/・hooks/ 内のパス書き換えは禁止** — 全プロジェクト共通の配布物であり、パスは実行時に `.dd-config` から読む。直接書き換えると次回アップグレード（上書きコピー）で設定が消える。

**人間・LLM向けドキュメント**: コピーしたファイル内のパス参照を実配置に合わせて更新:

- `doc/DD/` → 実際のDDフォルダパス（AGENTS.md・SKILL.md・DOC-MAP.md）
- `doc/templates/` → 実際のテンプレートフォルダパス
- `doc/archived/DD/` → 実際のアーカイブフォルダパス

> `.dd-config` と AGENTS.md「DD設定」は同じ値を指すこと（食い違うと機械とLLMの挙動が割れる）。

### 9. パス整合性チェック（必須・スキップ禁止）

セットアップ完了前に、以下のパス参照が実際のファイル配置と一致しているか検証する。**不一致がある場合はセットアップを完了せず、修正してから再検証する。**

| # | 検証対象 | 確認内容 |
|---|---------|---------|
| 1 | AGENTS.md の `テンプレート` 行 | 記載パスに `dd_template.md` が存在するか |
| 2 | SKILL.md の `templates/guides.md` 参照 | 記載パスに `guides.md` が存在するか |
| 3 | SKILL.md の `doc/da-method.md` 参照 | 記載パスに `da-method.md` が存在するか |
| 4 | テンプレートフォルダ | `coding-standards.md` が存在するか |
| 5 | DDフォルダ | `DD-INDEX.md` が存在するか |
| 6 | `.agents/hooks/` | `pre-edit-guard.sh` と `post-bash-dd-archive-reminder.sh` が存在するか（Level 2） |
| 7 | `scripts/` | `dd-index-gen.sh` が存在するか（Level 2） |
| 8 | doc/ 直下 | `DOC-MAP.md` が存在し、表内のパスが実配置と一致しているか |
| 9 | AGENTS.md | 50行程度に収まっているか、`doc/DOC-MAP.md` への参照があるか |
| 10 | `.dd-config`（ルート直下） | 存在し、`DD_DIR` / `ARCHIVE_DIR` の指す実フォルダが存在するか（Level 2） |

**検証手順:**
1. 対象プロジェクトの AGENTS.md からテンプレートパスを読み取る
2. SKILL.md 内のパス参照を全て抽出する
3. 各パスに対して `ls` でファイルの存在を確認する
4. 不一致があればファイル内のパスを修正し、再度確認する
5. Level 2 なら `bash scripts/dd-index-gen.sh` を一度実行し、エラーなく完走して DD-INDEX.md が生成されることを確認する（`.dd-config` の実効テスト）

```
✓ パス整合性チェック:
  AGENTS.md テンプレート → doc/templates/dd_template.md  ✓ 存在確認
  SKILL.md guides.md    → doc/templates/guides.md        ✓ 存在確認
  SKILL.md da-method.md → doc/da-method.md               ✓ 存在確認
  coding-standards.md   → doc/templates/coding-standards.md ✓ 存在確認
  DD-INDEX.md           → doc/DD/DD-INDEX.md                ✓ 存在確認
  pre-edit-guard.sh     → .agents/hooks/pre-edit-guard.sh   ✓ 存在確認 (Level 2)
  dd-index-gen.sh       → scripts/dd-index-gen.sh           ✓ 存在確認 (Level 2)
  .dd-config            → DD_DIR="doc/DD" / ARCHIVE_DIR="doc/archived/DD" ✓ 実在確認 (Level 2)
  DOC-MAP.md            → doc/DOC-MAP.md                    ✓ 存在確認
```

**全パスの存在が確認できるまで次のステップに進まないこと。**

### 10. 完了報告

セットアップ完了後、以下を表示:

```
✓ DD設計書のセットアップが完了しました

【配置されたファイル】
- DDフォルダ: {DDフォルダパス}
- ドキュメントインデックス: doc/DOC-MAP.md
- テンプレート: {テンプレートパス}
- アーカイブ: {アーカイブパス}
- パス設定: .dd-config（Level 2）
- スキル: {スキルパス}（Level 2以上）
- AGENTS.md: {作成 or 追記}（50行程度）

【次のステップ】
1. `.agents/settings.json` にHooks設定を追加（ステップ5参照、Level 2の場合）
2. Playwright MCP を導入した場合: Codex を再起動して有効化
3. `/dd new 最初のDD` で新規DDを作成
4. development-flow.md で開発フローを確認
5. フロントエンド実装を含む場合: Modern Web Guidance の利用を検討
   （coding-standards.md「補完ツール」セクション参照。npx で直接利用可能）
6. 以後の更新はこのプロジェクト側から `bash scripts/dd-update.sh` で取り込めます（Pull型）
```

## パス規約（推奨）

| 項目 | 推奨パス | 代替パス |
|------|----------|----------|
| DDフォルダ | `doc/DD/` | `docs/DD/` |
| テンプレート | `doc/templates/` | `docs/templates/` |
| アーカイブ | `doc/archived/DD/` | `docs/archived/DD/` |
| スキル | `.agents/skills/` | （固定） |
| フック | `.agents/hooks/` | （固定） |
| スクリプト | `scripts/` | （任意） |
| パス設定 | `.dd-config`（ルート直下） | （固定） |

## 注意事項

- 既存ファイルがある場合は上書き前に確認
- AGENTS.md への追記は重複チェックを行う
- Git管理下の場合、変更をコミットするか確認
