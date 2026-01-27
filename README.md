# DD-Know-How

DD（Design Document）設計書による開発管理と、品質を担保するためのエージェント・スキル集です。

## 特徴

- **DDドリブン開発**: 意思決定の記録 + タスク管理 + ログを一元化
- **品質エージェント**: TDD、コードレビュー、セキュリティ監査を自動化
- **ワークフロー**: 5ステップ（Standard）または9ステップ（Full）の開発フロー

## なぜDDを使うのか

### よくある問題

- 「なぜこの設計にしたんだっけ？」→ 3ヶ月後に思い出せない
- 「この機能、仕様書に書いてある？」→ 実装と仕様がズレている
- 「今どこまで進んでるの？」→ タスクの進捗が見えない

### DDで解決

DDは「意思決定の記録」＋「タスク管理」＋「ログ」を1つのファイルにまとめます。

```
問題発生 → 検討 → 決定 → 実装 → 完了
    ↓       ↓      ↓      ↓      ↓
   DD作成  検討内容 決定事項 ログ追記 アーカイブ
```

## フォルダ構成

```
dd-know-how/
├── .claude/
│   └── commands/           # スラッシュコマンド定義
│       ├── dd.md           # /dd - DD管理
│       ├── plan.md         # /plan - 計画立案
│       ├── tdd.md          # /tdd - テスト駆動開発
│       ├── code-review.md  # /code-review - レビュー
│       ├── review.md       # /review - 規約チェック
│       └── review-spec.md  # /review-spec - 実装前チェック
├── agents/                 # エージェント定義
│   ├── planner.md          # 計画立案
│   ├── tdd-guide.md        # TDDガイド
│   ├── code-reviewer.md    # コードレビュー
│   ├── security-reviewer.md # セキュリティ監査
│   ├── database-reviewer.md # DB設計・最適化
│   └── architect.md        # アーキテクチャ設計
├── skills/                 # スキル（言語別パターン集）
│   ├── typescript/
│   │   ├── backend.md      # バックエンドパターン
│   │   └── frontend.md     # フロントエンドパターン
│   └── python/
│       └── streamlit.md    # Streamlitパターン
├── rules/
│   └── dd-basic-rules.md   # DD基本ルール
├── templates/
│   └── dd_template.md      # DDテンプレート
├── doc/                   # ドキュメント
│   ├── development-flow.md       # Standard（5ステップ）
│   ├── development-flow-full.md  # Full（9ステップ）
│   ├── spec-sync-check.md        # 仕様書同期チェック
│   ├── customization/            # カスタマイズガイド
│   └── examples/                 # 実例集
├── CLAUDE.md               # プロジェクト設定テンプレート
├── IMPORT.md               # 外部プロジェクトへの導入手順
└── README.md               # このファイル
```

## クイックスタート

### 1. このリポジトリをクローン

```bash
git clone https://github.com/xxx/dd-know-how.git
cd dd-know-how
```

### 2. Claude Code を起動

```bash
claude
```

### 3. DD を作成

```
/dd new ログイン機能の実装
```

## 利用可能なコマンド

| コマンド | 説明 |
|---------|------|
| `/dd new タイトル` | 新規DD作成 |
| `/dd status` | 現在の進捗を表示 |
| `/dd list` | DD一覧を表示 |
| `/dd log メモ` | DDにログを追記 |
| `/dd archive 番号` | DDをアーカイブ |
| `/plan` | 実装計画を立案 |
| `/tdd` | テスト駆動開発を開始 |
| `/code-review` | コードレビューを実行 |
| `/review` | 規約チェックを実行 |
| `/review-spec` | 実装前チェックを検証 |

## 開発フロー

### Standard（5ステップ）

日常的な開発タスク向け。

1. **DD作成** - タスクの目的と背景を記録
2. **実装** - コーディング
3. **テスト** - テスト作成・実行
4. **レビュー** - コードレビュー
5. **コミット・アーカイブ** - 完了処理

### Full（9ステップ）

重要な機能開発向け。仕様確認・実装前チェック・仕様書同期を追加。

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Step 4/9: コーディング
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 1. DD作成       ✅ 2. 仕様確認     ✅ 3. 実装前チェック
▶️ 4. コーディング  ⬜ 5. テスト作成   ⬜ 6. コード検証
⬜ 7. レビュー      ⬜ 8. 仕様書同期   ⬜ 9. コミット
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

詳細は [doc/development-flow-full.md](doc/development-flow-full.md) を参照。

## エージェント

| エージェント | 用途 | 呼び出し例 |
|-------------|------|-----------|
| `planner` | 実装計画の立案 | `/plan` |
| `tdd-guide` | テスト駆動開発 | `/tdd` |
| `code-reviewer` | コード品質レビュー | `/code-review` |
| `security-reviewer` | セキュリティ監査 | 直接呼び出し |
| `database-reviewer` | DB設計・クエリ最適化 | 直接呼び出し |
| `architect` | アーキテクチャ設計 | 直接呼び出し |

## スキル（言語別パターン集）

| 言語 | ファイル | 内容 |
|------|---------|------|
| TypeScript | `typescript/backend.md` | API設計、リポジトリパターン、キャッシュ、認証 |
| TypeScript | `typescript/frontend.md` | コンポーネント設計、状態管理、パフォーマンス最適化 |
| Python | `python/streamlit.md` | Streamlitアプリ開発パターン |

新しい言語・フレームワークを追加する場合は `skills/{言語}/` にファイルを追加してください。

## 外部プロジェクトへの導入

自分のプロジェクトに DD-Know-How を導入する方法：

### /setup コマンドを使用（推奨）

```bash
cd dd-know-how
claude
# Claude Code 内で
/setup /path/to/your-project
```

手動セットアップの詳細は [IMPORT.md](IMPORT.md) を参照。

### 導入後のフォルダ構造

```
your-project/
├── .claude/
│   └── commands/
│       ├── dd.md
│       ├── plan.md
│       ├── tdd.md
│       └── code-review.md
├── agents/
├── skills/
├── doc/
│   ├── DD/                 # DD設計書
│   ├── templates/
│   └── archived/DD/
└── CLAUDE.md
```

## カスタマイズ

- テンプレートのカスタマイズ: [doc/customization/template-sections.md](doc/customization/template-sections.md)
- フローのカスタマイズ: [doc/customization/development-flow-variants.md](doc/customization/development-flow-variants.md)
- 他のAI環境での使用: [doc/customization/other-environments.md](doc/customization/other-environments.md)

## 複数人での運用

チームでDDを運用する場合、識別子プレフィックスで番号衝突を防げます。

| メンバー | 識別子 | DD番号例 |
|----------|--------|----------|
| 石森 | I | DDI-001, DDI-002 |
| 斉藤 | SA | DDSA-001, DDSA-002 |

## 関連プロジェクト

本プロジェクトの一部のエージェント・スキルは [everything-claude-code](https://github.com/affaan-m/everything-claude-code) から移植しています。

| コンポーネント | 移植元 |
|---------------|--------|
| `planner.md` | everything-claude-code/agents/ |
| `tdd-guide.md` | everything-claude-code/agents/ |
| `code-reviewer.md` | everything-claude-code/agents/ |
| `security-reviewer.md` | everything-claude-code/agents/ |
| `architect.md` | everything-claude-code/agents/ |

統合の詳細な設計については [dd-integration.md](https://github.com/ishimori/everything-claud-code/blob/main/manual/dd-integration/dd-integration.md) (private Repository) を参照してください。

## ライセンス

MIT License
