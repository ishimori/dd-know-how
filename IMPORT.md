# DD-Know-How インポートガイド

自分のプロジェクトに DD-Know-How を導入する手順です。

## 何が手に入るか

| 機能 | 効果 |
|------|------|
| **DD設計書** | 意思決定・タスク・作業ログを1つのMarkdownに集約。セッションをまたいでも経緯が残る |
| **DA批判レビュー** | 各Phase完了前に「どこが壊れるか」を強制的に探す。LLMの楽観バイアスに対抗 |
| **DA品質フィルター** | DAレビューのノイズ（事実誤認・既知事項の再指摘）を4ルールで排除 |
| **実装前詳細化（2段階方式）** | 計画段階での過剰設計を避けつつ、規模/複雑度シグナルに該当するPhaseのみ実装直前に詳細設計を強制。いきあたりばったりの実装を防ぐ |

## 導入レベル

2段階から選択。**Level 2 を推奨。**

| レベル | コピーするもの | 得られる機能 |
|--------|--------------|-------------|
| Level 1（最小） | テンプレート + 基本ルール | DD手動管理、DAレビュー記録テンプレート |
| **Level 2（標準）** | + `/dd` スキル + DA メソッド文書 | **DDコマンド操作、DA批判レビュー、Phase管理** |

### Level別の機能比較

| コンポーネント | Level 1 | Level 2 |
|---------------|---------|---------|
| DDテンプレート（DA批判レビュー組み込み済み） | ✅ | ✅ |
| DD作成ガイド（guides.md・基本ルール） | ✅ | ✅ |
| DDフォルダ構造 | ✅ | ✅ |
| `/dd` スキル（作成・参照・一覧・検索・アーカイブ） | - | ✅ |
| DA メソッド文書（DA品質フィルター・再チェック条件） | - | ✅ |
| CLAUDE.md テンプレート | - | ✅ |

## セットアップ

### 方法1: /setup コマンド（推奨）

dd-know-how リポジトリ内で Claude Code を起動し、対象プロジェクトを指定:

```bash
cd dd-know-how
claude
> /setup /path/to/your-project
```

対話的にレベル選択・パス設定が行われます。

### 方法2: 手動セットアップ

以下、`dd-know-how/` は本リポジトリのパス、`your-project/` は導入先のパスです。

#### Level 1（最小構成）

```bash
cd your-project

# フォルダ作成
mkdir -p doc/DD doc/templates doc/archived/DD

# テンプレート一式（DDテンプレート・guides.md・coding-standards.md）をコピー
cp dd-know-how/templates/*.md  doc/templates/

# ドキュメントインデックスを配置（doc/ 直下。表内のパスは実配置に合わせて調整）
cp dd-know-how/templates/DOC-MAP.md  doc/DOC-MAP.md
```

これだけで DD 設計書を手動作成できます。テンプレートにはDA批判レビュー記録セクションが組み込み済みです。

#### Level 2（標準構成）— 推奨

Level 1 のファイルに加えて:

```bash
# スキルをコピー
mkdir -p .claude/skills/dd doc/
cp dd-know-how/.claude/skills/dd/SKILL.md        .claude/skills/dd/
cp dd-know-how/doc/da-method.md                  doc/

# CLAUDE.md をスニペットから作成（50行程度に収める。詳細は doc/ に置きポインタで参照）
cp dd-know-how/templates/CLAUDE.md.snippet ./CLAUDE.md
# → {...} プレースホルダ（プロジェクト説明・技術スタック・コマンド）を埋める
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
│       │   └── SKILL.md           # DD操作（~120行、軽量）
│       └── (プロジェクト固有のスキルを追加可能)
├── doc/
│   ├── DOC-MAP.md                 # ドキュメントインデックス（追加・移動時に更新）
│   ├── DD/                        # DD設計書（進行中）
│   │   ├── DD-001_ログイン機能.md
│   │   └── DD-002_API設計.md
│   ├── templates/
│   │   ├── dd_template.md         # DDテンプレート（DA批判レビュー組み込み済み）
│   │   ├── dd_template_*.md       # 差分テンプレート（bugfix / tdd / mock / e2e）
│   │   ├── guides.md              # DD作成ガイド（アプローチ選択・基本ルール）
│   │   └── coding-standards.md    # コーディング基準書
│   └── archived/
│       └── DD/                    # アーカイブ済みDD
└── CLAUDE.md                      # プロジェクト設定
```

## DA品質フィルターについて

Level 2 以上で導入される `doc/da-method.md` には **DA品質フィルター** が含まれます。DA批判レビュー実行時に自動適用される4ルール:

| # | ルール | 目的 |
|---|--------|------|
| 1 | **検証義務** | 指摘前にコード確認 or 実行で事実確認。推測だけの指摘を防ぐ |
| 2 | **既知事項の除外** | TODO/FIXME、Phase X 対応予定、別DDスコープアウト済みは除外 |
| 3 | **深刻度の判定基準** | 高=今壊れる、中=条件付きで壊れる、低=改善提案 |
| 4 | **再現手順の必須化** | 高/中には「何をすると→何が起きるか」を必ず記載 |

DDテンプレートの記録テーブルにも品質フィルターのガイドと再現手順列が組み込まれているため、Level 1 でも意識的に活用できます。

## パス規約

| 項目 | 推奨パス | 備考 |
|------|----------|------|
| DDフォルダ | `doc/DD/` | 進行中のDD設計書を配置 |
| テンプレート | `doc/templates/` | DDテンプレート・作成ガイド・コーディング基準書 |
| アーカイブ | `doc/archived/DD/` | 完了済みDDの保管先 |
| スキル | `.claude/skills/` | Claude Code skills形式（固定） |

パスを変更する場合は、`/dd` スキル内のパス参照も合わせて修正してください。

## 検証チェックリスト（必須・スキップ禁止）

### Level 1
- [ ] `doc/DD/` フォルダが存在する
- [ ] `doc/DOC-MAP.md` が配置され、表内のパスが実配置と一致している
- [ ] `doc/templates/dd_template.md` が配置されている
- [ ] `doc/archived/DD/` フォルダが存在する

### Level 2（Level 1 に加えて）
- [ ] `doc/da-method.md` が配置されている
- [ ] CLAUDE.md が50行程度で、プロジェクト固有の設定（技術スタック・コマンド）が埋まっている

### パス整合性チェック（Level 2 必須）

CLAUDE.md と SKILL.md 内のパス参照が、実際のファイル配置と一致しているか `ls` で確認する。**不一致がある場合はファイル内のパスを修正してから再確認する。全パスの存在確認が完了するまでセットアップ完了としないこと。**

| # | 検証対象 | 確認内容 |
|---|---------|---------|
| 1 | CLAUDE.md の `テンプレート` 行 | 記載パスに `dd_template.md` が存在するか |
| 2 | SKILL.md の `templates/guides.md` 参照 | 記載パスに `guides.md` が存在するか |
| 3 | SKILL.md の `doc/da-method.md` 参照 | 記載パスに `da-method.md` が存在するか |

```
✓ パス整合性チェック:
  CLAUDE.md テンプレート → doc/templates/dd_template.md  ✓ 存在確認
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
- `.claude/skills/{スキル名}/SKILL.md` の配置を確認（`SKILL.md` が正しいファイル名）
- Claude Code を再起動

### DDの作成先が意図と違う
- `/dd` スキル内のパス設定を確認
- CLAUDE.md の DDフォルダ記載と一致しているか確認

### テンプレートが見つからない
- `doc/templates/dd_template.md` の存在を確認
- `/dd` スキル内のテンプレートパス設定を修正
