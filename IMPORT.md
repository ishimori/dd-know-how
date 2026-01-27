# DD-Know-How インポートガイド

このドキュメントでは、DD-Know-How を外部プロジェクトに導入する手順を説明します。

## 導入レベル

DD-Know-Howは3つのレベルから選択できます。まずはLevel 1で試し、必要に応じてLevel 2以上に拡張するのがおすすめです。

| レベル | 内容 | 推奨ケース |
|--------|------|------------|
| Level 1（最小） | テンプレート + 基本ルール | まず試したい、手動運用 |
| Level 2（標準） | + /dd コマンド + 開発フロー | 通常利用（推奨） |
| Level 3（フル） | + 仕様書連携 + レビューコマンド | 厳密な運用、大規模チーム |

### Level別の機能比較

| コンポーネント | Level 1 | Level 2 | Level 3 |
|---------------|---------|---------|---------|
| DDテンプレート | ✅ | ✅ | ✅ |
| DDフォルダ構造 | ✅ | ✅ | ✅ |
| /dd コマンド | - | ✅ | ✅ |
| /plan, /tdd, /code-review | - | ✅ | ✅ |
| エージェント定義（agents/） | - | ✅ | ✅ |
| CLAUDE.md | - | ✅ | ✅ |
| /review, /review-spec | - | - | ✅ |
| 仕様書同期チェック | - | - | ✅ |

**オプション（全レベル共通）:**
- スキル（skills/）- 言語別のコーディングパターン集

### コマンドとエージェントの依存関係

Level 2以上のコマンドはエージェントを呼び出すため、**コマンドとエージェントはセットでインポート**してください。

| コマンド | 必須エージェント | 説明 |
|----------|-----------------|------|
| /plan | planner.md | 実装計画の立案 |
| /tdd | tdd-guide.md | テスト駆動開発のガイド |
| /code-review | code-reviewer.md | コード品質レビュー |

> ⚠️ **注意**: エージェントがないとコマンドが正常に動作しません。

### どのレベルを選ぶべきか？

- **Level 1**: DD設計書の概念を試したい、既存のワークフローを大きく変えたくない
- **Level 2**: Claude Codeでの開発を効率化したい、コマンドで操作したい（ほとんどのケースで推奨）
- **Level 3**: 仕様書との整合性を厳密に管理したい、レビュープロセスを強化したい

## 推奨フォルダ構造

外部プロジェクトに導入後の推奨構造:

```
your-project/
├── .claude/
│   └── commands/           # スラッシュコマンド
│       ├── dd.md
│       ├── plan.md
│       ├── tdd.md
│       ├── code-review.md
│       ├── review.md
│       └── review-spec.md
├── agents/                 # エージェント定義
│   ├── planner.md
│   ├── tdd-guide.md
│   ├── code-reviewer.md
│   ├── security-reviewer.md
│   ├── database-reviewer.md
│   └── architect.md
├── skills/                 # スキル（言語別パターン集）
│   ├── typescript/
│   │   ├── backend.md
│   │   └── frontend.md
│   └── python/
│       └── streamlit.md
├── doc/
│   ├── DD/                 # DD設計書
│   │   ├── DD-001_xxx.md
│   │   └── DD-002_xxx.md
│   ├── templates/
│   │   └── dd_template.md
│   └── archived/
│       └── DD/             # アーカイブ済みDD
└── CLAUDE.md               # プロジェクト設定
```

## セットアップ方法

### 方法1: /setup コマンドを使用（推奨）

1. dd-know-how リポジトリで Claude Code を起動
2. `/setup /path/to/your-project` を実行
3. 対話的に設定を選択

```bash
cd dd-know-how
claude
# Claude Code 内で
/setup /path/to/your-project
```

### 方法2: 手動セットアップ

#### Level 1（最小構成）

```bash
# 対象プロジェクトで実行
mkdir -p doc/DD doc/templates doc/archived/DD

# dd-know-how からコピー
cp dd-know-how/templates/dd_template.md doc/templates/
```

Level 1では、DDテンプレートを使って手動でDD設計書を作成・管理します。

#### Level 2（標準構成）

```bash
# 対象プロジェクトで実行
mkdir -p .claude/commands agents doc/DD doc/templates doc/archived/DD

# dd-know-how からコピー（コマンド）
cp dd-know-how/.claude/commands/dd.md .claude/commands/
cp dd-know-how/.claude/commands/plan.md .claude/commands/
cp dd-know-how/.claude/commands/tdd.md .claude/commands/
cp dd-know-how/.claude/commands/code-review.md .claude/commands/

# dd-know-how からコピー（エージェント）※必須
cp dd-know-how/agents/planner.md agents/
cp dd-know-how/agents/tdd-guide.md agents/
cp dd-know-how/agents/code-reviewer.md agents/

# dd-know-how からコピー（テンプレート・設定）
cp dd-know-how/templates/dd_template.md doc/templates/
cp dd-know-how/CLAUDE.md ./

# CLAUDE.md を編集してプロジェクト固有の設定を追加
```

> ⚠️ **重要**: `/plan`, `/tdd`, `/code-review` コマンドを使用するには、対応するエージェントが必須です。

#### Level 3（フル構成）

```bash
# Level 2 のファイルに加えて
cp dd-know-how/.claude/commands/review.md .claude/commands/
cp dd-know-how/.claude/commands/review-spec.md .claude/commands/

# 仕様書フォルダを作成（必要に応じて）
mkdir -p doc/spec
```

CLAUDE.md 内の設定を `full` に変更:

```markdown
## DD設定
- **フロー**: full（9ステップ）
```

#### オプション: 追加エージェント・スキル

必須エージェント以外にも、用途に応じて追加できます:

```bash
# 追加エージェント（任意）
cp dd-know-how/agents/security-reviewer.md agents/   # セキュリティ監査
cp dd-know-how/agents/database-reviewer.md agents/   # DB設計・クエリ最適化
cp dd-know-how/agents/architect.md agents/           # アーキテクチャ設計

# スキル（言語別パターン集、任意）
mkdir -p skills
cp -r dd-know-how/skills/* skills/
```

## パス規約

### DDフォルダ

| 優先度 | パス | 条件 |
|--------|------|------|
| 1 | `doc/DD/` | `doc/` フォルダが存在する場合（推奨） |
| 2 | `doc/DD/` | `doc/` フォルダが存在する場合 |
| 3 | カスタム | ユーザー指定 |

### 関連フォルダ

DDフォルダの親ディレクトリを基準に配置:

| 項目 | 相対パス | 例（doc/DD/ の場合） |
|------|----------|------------------------|
| テンプレート | `../templates/` | `doc/templates/dd_template.md` |
| アーカイブ | `../archived/DD/` | `doc/archived/DD/` |

## パス設定のカスタマイズ

コピーしたファイル内のパス参照を変更する場合:

### dd.md 内のパス

```markdown
# 変更前（デフォルト）
doc/DD/
doc/templates/dd_template.md
doc/archived/DD/

# 変更後の例（doc/ を使用する場合）
doc/DD/
doc/templates/dd_template.md
doc/archived/DD/
```

### CLAUDE.md 内のパス

```markdown
# 変更前
- **DDフォルダ**: `doc/DD/`

# 変更後の例
- **DDフォルダ**: `doc/DD/`
```

## 検証チェックリスト

セットアップ後、以下を確認:

### Level 1
- [ ] DDフォルダが正しいパスに存在する
- [ ] テンプレートファイルが配置されている
- [ ] アーカイブフォルダが作成されている

### Level 2以上（Level 1に加えて）
- [ ] `/dd new テスト` で新規DDが作成できる
- [ ] `agents/` に必須エージェントが配置されている（planner.md, tdd-guide.md, code-reviewer.md）
- [ ] `/plan` `/tdd` `/code-review` が動作する
- [ ] CLAUDE.md にプロジェクト設定が記載されている

### Level 3（Level 2に加えて）
- [ ] `/review` `/review-spec` が動作する
- [ ] 仕様書フォルダが設定されている

## トラブルシューティング

### コマンドが認識されない

- `.claude/commands/` にファイルが存在するか確認
- Claude Code を再起動

### DDの作成先が意図と違う

- `dd.md` 内のパス設定を確認
- `CLAUDE.md` の記載と一致しているか確認

### テンプレートが見つからない

- テンプレートファイルのパスを確認
- `dd.md` 内のテンプレートパス設定を修正

### エージェントが見つからない（Level 2以上）

- `agents/` ディレクトリが存在するか確認
- 必須エージェントが配置されているか確認:
  - `/plan` → `agents/planner.md`
  - `/tdd` → `agents/tdd-guide.md`
  - `/code-review` → `agents/code-reviewer.md`
- ファイル名が正しいか確認（例: `tdd-guide.md`）
