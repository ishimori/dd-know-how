# DD-Know-How インポートガイド

自分のプロジェクトに DD-Know-How を導入する手順です。

## 何が手に入るか

| 機能 | 効果 |
|------|------|
| **DD設計書** | 意思決定・タスク・作業ログを1つのMarkdownに集約。セッションをまたいでも経緯が残る |
| **DA批判レビュー** | 各Phase完了前に「どこが壊れるか」を強制的に探す。LLMの楽観バイアスに対抗 |
| **DA品質フィルター** | DAレビューのノイズ（事実誤認・既知事項の再指摘）を4ルールで排除 |
| **9ステップ開発フロー** | DD作成→仕様確認→実装→テスト→レビュー→仕様書同期→コミットの体系的フロー |

## 導入レベル

2段階から選択。**Level 2 を推奨。**

| レベル | コピーするもの | 得られる機能 |
|--------|--------------|-------------|
| Level 1（最小） | テンプレート + 基本ルール | DD手動管理、DAレビュー記録テンプレート |
| **Level 2（標準）** | + `/dd` + `/workflow` スキル | **DDコマンド操作、DA批判レビュー、Phase管理** |

### Level別の機能比較

| コンポーネント | Level 1 | Level 2 |
|---------------|---------|---------|
| DDテンプレート（DA批判レビュー組み込み済み） | ✅ | ✅ |
| DD基本ルール | ✅ | ✅ |
| DDフォルダ構造 | ✅ | ✅ |
| `/dd` スキル（作成・参照・一覧・アーカイブ） | - | ✅ |
| `/workflow` スキル（9ステップ・DA批判レビュー・DA品質フィルター） | - | ✅ |
| CLAUDE.md テンプレート | - | ✅ |

**オプション:**
- 言語別パターン集（`skills/`）— TypeScript、Python等のコーディングパターン

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

# テンプレートと基本ルールをコピー
cp dd-know-how/templates/dd_template.md  doc/templates/
cp dd-know-how/rules/dd-basic-rules.md   doc/templates/
```

これだけで DD 設計書を手動作成できます。テンプレートにはDA批判レビュー記録セクションが組み込み済みです。

#### Level 2（標準構成）— 推奨

Level 1 のファイルに加えて:

```bash
# スキルをコピー
mkdir -p .claude/skills/dd .claude/skills/workflow
cp dd-know-how/.claude/skills/dd/SKILL.md        .claude/skills/dd/
cp dd-know-how/.claude/skills/workflow/SKILL.md   .claude/skills/workflow/

# CLAUDE.md をコピーして編集
cp dd-know-how/CLAUDE.md ./
# → プロジェクト固有の設定（技術スタック、コーディング規約等）を追記
```

**導入後に使えるコマンド:**
- `/dd new タイトル` — DD作成
- `/dd status` — 進捗確認
- `/dd list` — DD一覧
- `/dd archive 番号` — アーカイブ
- `/workflow` — 9ステップフロー・DA批判レビュー起動

#### オプション: 言語別パターン集

```bash
cp -r dd-know-how/skills/ skills/
```

## 導入後のフォルダ構造（Level 2）

```
your-project/
├── .claude/
│   └── skills/
│       ├── dd/
│       │   └── SKILL.md           # DD操作（~120行、軽量）
│       └── workflow/
│           └── SKILL.md           # 9ステップフロー・DA批判レビュー（~270行）
├── doc/
│   ├── DD/                        # DD設計書（進行中）
│   │   ├── DD-001_ログイン機能.md
│   │   └── DD-002_API設計.md
│   ├── templates/
│   │   ├── dd_template.md         # DDテンプレート（DA批判レビュー組み込み済み）
│   │   └── dd-basic-rules.md      # DD基本ルール
│   └── archived/
│       └── DD/                    # アーカイブ済みDD
└── CLAUDE.md                      # プロジェクト設定
```

## DA品質フィルターについて

Level 2 以上で導入される `/workflow` スキルには **DA品質フィルター** が含まれます。DA批判レビュー実行時に自動適用される4ルール:

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
| テンプレート | `doc/templates/` | DDテンプレート・基本ルール |
| アーカイブ | `doc/archived/DD/` | 完了済みDDの保管先 |
| スキル | `.claude/skills/` | Claude Code skills形式（固定） |

パスを変更する場合は、`/dd` スキル内のパス参照も合わせて修正してください。

## 検証チェックリスト

### Level 1
- [ ] `doc/DD/` フォルダが存在する
- [ ] `doc/templates/dd_template.md` が配置されている
- [ ] `doc/archived/DD/` フォルダが存在する

### Level 2（Level 1 に加えて）
- [ ] `/dd new テスト` で DD が `doc/DD/` に作成される
- [ ] `/dd list` で一覧が表示される
- [ ] `/workflow` でフロー管理が起動する
- [ ] CLAUDE.md にプロジェクト固有の設定が記載されている

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
