# DD-Know-How インポートガイド

自分のプロジェクトに DD-Know-How を導入する手順です。

> **Claude Code / Codex 両対応**: 指示ファイルは AGENTS.md が正本（Codex は直接、Claude Code は CLAUDE.md の `@AGENTS.md` インポート経由で読む）。スキルは同一内容を `.claude/skills/`（Claude Code）と `.agents/skills/`（Codex）に配置します。二重管理は発生しません。

## 何が手に入るか

| 機能 | 効果 |
|------|------|
| **DD設計書** | 意思決定・受け入れ基準・タスク・作業ログを1つのMarkdownに集約。セッションをまたいでも経緯が残る |
| **リスク判定 + 完了前チェック** | 認可・DB移行等の危険な変更を起票時に1行で判定。完了前にセルフレビュー1巡（「どこが壊れるか」）と全回帰を強制 |
| **機械検証** | 各Phaseに「コマンド → 期待結果」の検証タスク。LLMの「やったふり」に対抗 |
| **レビューの手動ディスパッチ運用** | レビューをDDタスクに組み込まず、完了報告を見た人間が別モデルへ都度指示（品質と速度のバランスを人間が握る） |

## 導入レベル

2段階から選択。**Level 2 を推奨。**

| レベル | コピーするもの | 得られる機能 |
|--------|--------------|-------------|
| Level 1（最小） | テンプレート + 基本ルール | DD手動管理 |
| **Level 2（標準）** | + `/dd` スキル + 方法論文書 | **DDコマンド操作、Phase管理、ヘルスチェック** |

### Level別の機能比較

| コンポーネント | Level 1 | Level 2 |
|---------------|---------|---------|
| DDテンプレート（受け入れ基準・リスク判定・完了前チェック） | ✅ | ✅ |
| DD作成ガイド（guides.md・基本ルール） | ✅ | ✅ |
| DDフォルダ構造 | ✅ | ✅ |
| `/dd` スキル（作成・参照・一覧・検索・アーカイブ） | - | ✅ |
| DA深掘り手法の参考文書（da-method.md） | - | ✅ |
| AGENTS.md / CLAUDE.md テンプレート | - | ✅ |

## セットアップ

### 方法1: /setup コマンド（推奨）

dd-know-how リポジトリ内で Claude Code を起動し、対象プロジェクトを指定:

```bash
cd dd-know-how
claude
> /setup /path/to/your-project
```

対話的にレベル選択・パス設定が行われます。（Codex の場合は `codex` を起動し `$setup /path/to/your-project`）

### 方法2: 手動セットアップ

以下、`dd-know-how/` は本リポジトリのパス、`your-project/` は導入先のパスです。

#### Level 1（最小構成）

```bash
cd your-project

# フォルダ作成
mkdir -p doc/DD doc/spec doc/templates doc/archived/DD

# テンプレート一式（DDテンプレート・guides.md・coding-standards.md）をコピー
cp dd-know-how/templates/*.md  doc/templates/

# ドキュメントインデックスを配置（doc/ 直下。表内のパスは実配置に合わせて調整）
cp dd-know-how/templates/DOC-MAP.md  doc/DOC-MAP.md

# 知見蓄積ファイルは doc/ 直下に移動（テンプレートではなく実体として使う）
mv doc/templates/engineering-patterns.md doc/templates/decisions.md doc/
```

これだけで DD 設計書を手動作成できます。テンプレートには受け入れ基準・リスク判定・完了前チェックが組み込み済みです。

#### Level 2（標準構成）— 推奨

Level 1 のファイルに加えて:

```bash
# スキルをコピー（.claude = Claude Code 用 / .agents = Codex 用。内容は同一 — 正本は .claude 側）
mkdir -p .claude/skills/dd .agents/skills/dd doc/
cp dd-know-how/.claude/skills/dd/SKILL.md        .claude/skills/dd/
cp dd-know-how/.claude/skills/dd/SKILL.md        .agents/skills/dd/
cp dd-know-how/doc/da-method.md                  doc/
cp dd-know-how/doc/spec-sync-check.md            doc/

# 指示ファイルを作成（AGENTS.md が正本・50行程度。CLAUDE.md は @AGENTS.md ポインタ）
cp dd-know-how/templates/AGENTS.md.snippet ./AGENTS.md
cp dd-know-how/templates/CLAUDE.md.snippet ./CLAUDE.md
# → AGENTS.md の {...} プレースホルダ（プロジェクト説明・技術スタック・コマンド）を埋める
#   CLAUDE.md は編集不要（Claude Code 固有の指示が必要になった時だけ追記する）

# 運用スクリプトとパス設定（INDEX自動生成・ヘルスチェック・DOC-MAP検証）
mkdir -p scripts
cp dd-know-how/templates/scripts/dd-index-gen.sh \
   dd-know-how/templates/scripts/dd-health.sh \
   dd-know-how/templates/scripts/doc-check.sh  scripts/
cp dd-know-how/templates/dd-config.example .dd-config
# → .dd-config の DD_DIR / ARCHIVE_DIR / DOC_DIR を実配置に合わせる
#   （スクリプト本体は編集禁止 — パスは .dd-config だけに書く。上書き更新で消えないため）
```

**導入後に使えるコマンド:**
- `/dd new タイトル` — DD作成
- `/dd list` — DD一覧
- `/dd search キーワード` — DD検索
- `/dd archive 番号` — アーカイブ

## 導入後のフォルダ構造（Level 2）

```
your-project/
├── .claude/
│   └── skills/
│       ├── dd/
│       │   └── SKILL.md           # DD操作（~150行、軽量）— Claude Code 用
│       └── (プロジェクト固有のスキルを追加可能)
├── .agents/
│   └── skills/
│       └── dd/
│           └── SKILL.md           # 同一内容の Codex 用ミラー（dd-update が両方を更新）
├── doc/
│   ├── DOC-MAP.md                 # ドキュメントインデックス（追加・移動時に更新）
│   ├── DD/                        # DD設計書（進行中）
│   │   ├── DD-001_ログイン機能.md
│   │   └── DD-002_API設計.md
│   ├── spec/                      # 仕様書（現在形の正典。DDアーカイブ時に同期チェック）
│   ├── templates/
│   │   ├── dd_template.md         # DDテンプレート（受け入れ基準・リスク判定・完了前チェック）
│   │   ├── dd_template_*.md       # 差分テンプレート（bugfix / tdd / mock / e2e）
│   │   ├── guides.md              # DD作成ガイド（アプローチ選択・基本ルール）
│   │   └── coding-standards.md    # コーディング基準書
│   └── archived/
│       └── DD/                    # アーカイブ済みDD
├── scripts/                       # dd-index-gen.sh / dd-health.sh / doc-check.sh
├── .dd-config                     # パス設定の単一ソース（スクリプト・フックが参照）
├── AGENTS.md                      # プロジェクト設定の正本（全エージェント共通）
└── CLAUDE.md                      # @AGENTS.md ポインタ（Claude Code 用・1行）
```

## da-method.md（参考文書）について

Level 2 以上で導入される `doc/da-method.md` は、深掘りレビューが必要な局面（設計の岐路・リスクありDD・レビュー指示時）のための手法集です。レビュー指摘の質を保つ **品質フィルター4ルール**（検証義務 / 既知事項の除外 / 深刻度の判定基準 / 再現手順の必須化）を含みます。標準フローの必須工程ではありません — 完了前チェックのセルフレビュー1巡と、人間が都度指示するクロスレビューが標準です。

## パス規約

| 項目 | 推奨パス | 備考 |
|------|----------|------|
| DDフォルダ | `doc/DD/` | 進行中のDD設計書を配置 |
| テンプレート | `doc/templates/` | DDテンプレート・作成ガイド・コーディング基準書 |
| アーカイブ | `doc/archived/DD/` | 完了済みDDの保管先 |
| スキル | `.claude/skills/` + `.agents/skills/` | Agent Skills 形式（固定）。前者を Claude Code、後者を Codex が読む — 内容は同一 |
| パス設定 | `.dd-config`（ルート直下） | スクリプト・フックが読む単一ソース |

パスを変更する場合は、`.dd-config` と `/dd` スキル内・AGENTS.md のパス参照も合わせて修正してください（スクリプト本体は修正不要）。

## 検証チェックリスト（必須・スキップ禁止）

### Level 1
- [ ] `doc/DD/` フォルダが存在する
- [ ] `doc/DOC-MAP.md` が配置され、表内のパスが実配置と一致している
- [ ] `doc/spec/` フォルダが存在する
- [ ] `doc/templates/dd_template.md` が配置されている
- [ ] `doc/engineering-patterns.md` と `doc/decisions.md` が doc/ 直下に配置されている
- [ ] `doc/archived/DD/` フォルダが存在する

### Level 2（Level 1 に加えて）
- [ ] `doc/da-method.md` が配置されている
- [ ] `doc/spec-sync-check.md` が配置されている（アーカイブ時の同期チェック手順）
- [ ] AGENTS.md が50行程度で、プロジェクト固有の設定（技術スタック・コマンド）が埋まっている
- [ ] CLAUDE.md の冒頭に `@AGENTS.md` インポート行がある
- [ ] `.agents/skills/dd/SKILL.md` が `.claude/skills/dd/SKILL.md` と同一内容（`diff` で確認）
- [ ] `.dd-config` がルート直下にあり、`DD_DIR` / `ARCHIVE_DIR` が実配置と一致している
- [ ] `bash scripts/dd-index-gen.sh` がエラーなく完走し DD-INDEX.md が生成される

### パス整合性チェック（Level 2 必須）

AGENTS.md と SKILL.md 内のパス参照が、実際のファイル配置と一致しているか `ls` で確認する。**不一致がある場合はファイル内のパスを修正してから再確認する。全パスの存在確認が完了するまでセットアップ完了としないこと。**

| # | 検証対象 | 確認内容 |
|---|---------|---------|
| 1 | AGENTS.md の `テンプレート` 行 | 記載パスに `dd_template.md` が存在するか |
| 2 | SKILL.md の `templates/guides.md` 参照 | 記載パスに `guides.md` が存在するか |
| 3 | SKILL.md の `doc/da-method.md` 参照 | 記載パスに `da-method.md` が存在するか |

```
✓ パス整合性チェック:
  AGENTS.md テンプレート → doc/templates/dd_template.md  ✓ 存在確認
  SKILL.md guides.md    → doc/templates/guides.md        ✓ 存在確認
  SKILL.md da-method.md → doc/da-method.md               ✓ 存在確認
```

## オプション導入

セットアップ後、プロジェクトの性質に応じて以下を追加できる:

| オプション | 内容 | テンプレート |
|-----------|------|-------------|
| **Playwright MCP** | Claudeに「目」を与える。エビデンス取得（guides.md）の前提。`.mcp.json` をプロジェクト直下に配置し、Claude Code 再起動で有効 | `templates/mcp/mcp.json` |
| **Lintヒント基盤** | LintエラーをP規約ID + 修正方針付きでLLMに返し、自己修正ループを作る。PostToolUse hook で編集直後のフィードバックも可能 | `templates/lint/`（手順: `templates/lint/README.md`） |

## 既存導入のアップグレード

既にDD-Know-Howを導入済みのプロジェクトは [UPGRADE-NOTICE.md](doc/UPGRADE-NOTICE.md) を参照。

## トラブルシューティング

### スキルが認識されない
- Claude Code: `.claude/skills/{スキル名}/SKILL.md` の配置を確認（`SKILL.md` が正しいファイル名）
- Codex: `.agents/skills/{スキル名}/SKILL.md` の配置を確認
- エージェントを再起動

### DDの作成先が意図と違う
- `/dd` スキル内のパス設定を確認
- AGENTS.md の DDフォルダ記載と一致しているか確認

### テンプレートが見つからない
- `doc/templates/dd_template.md` の存在を確認
- `/dd` スキル内のテンプレートパス設定を修正
