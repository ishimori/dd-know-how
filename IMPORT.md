# DD-Know-How インポートガイド

このドキュメントでは、DD-Know-How を外部プロジェクトに導入する手順を説明します。

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

#### Standard 構成

```bash
# 対象プロジェクトで実行
mkdir -p .claude/commands agents skills doc/DD doc/templates doc/archived/DD

# dd-know-how からコピー
cp dd-know-how/.claude/commands/* .claude/commands/
cp dd-know-how/agents/* agents/
cp -r dd-know-how/skills/* skills/
cp dd-know-how/templates/dd_template.md doc/templates/
cp dd-know-how/CLAUDE.md ./

# CLAUDE.md を編集してプロジェクト固有の設定を追加
```

#### Full 構成（追加コマンド含む）

Standard 構成と同じ手順で、すべてのコマンドとエージェントがコピーされます。

CLAUDE.md 内の設定を `full` に変更:

```markdown
## DD設定
- **フロー**: full（9ステップ）
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

- [ ] DDフォルダが正しいパスに存在する
- [ ] テンプレートファイルが配置されている
- [ ] アーカイブフォルダが作成されている
- [ ] `/dd new テスト` で新規DDが作成できる
- [ ] `/plan` `/tdd` `/code-review` が動作する
- [ ] CLAUDE.md にプロジェクト設定が記載されている

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

### エージェントが見つからない

- `agents/` ディレクトリが存在するか確認
- ファイル名が正しいか確認（例: `tdd-guide.md`）
