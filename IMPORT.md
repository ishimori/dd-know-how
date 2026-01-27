# DD設計書ノウハウ集 - インポート規約

このドキュメントでは、dd-know-how を外部プロジェクトに導入する際のパス規約と手順を定義します。

## 推奨フォルダ構造

外部プロジェクトに導入後の推奨構造:

```
your-project/
├── .claude/
│   └── commands/           # Claude Code スキル（コマンド定義）
│       └── dd.md           # /dd コマンド
│
├── docs/                   # ドキュメントルート（推奨）
│   ├── DD/                 # DD設計書
│   │   ├── DD-001_xxx.md
│   │   └── DD-002_xxx.md
│   ├── templates/
│   │   └── dd_template.md  # DDテンプレート
│   └── archived/
│       └── DD/             # アーカイブ済みDD
│
└── CLAUDE.md               # プロジェクトルール
```

## パス規約

### DDフォルダ

| 優先度 | パス | 条件 |
|--------|------|------|
| 1 | `docs/DD/` | `docs/` フォルダが存在する場合（推奨） |
| 2 | `doc/DD/` | `doc/` フォルダが存在する場合 |
| 3 | カスタム | ユーザー指定 |

### 関連フォルダ

DDフォルダの親ディレクトリを基準に配置:

| 項目 | 相対パス | 例（docs/DD/ の場合） |
|------|----------|------------------------|
| テンプレート | `../templates/` | `docs/templates/dd_template.md` |
| アーカイブ | `../archived/DD/` | `docs/archived/DD/` |

### コマンド定義

**固定パス**: `.claude/commands/`

Claude Code のスキル定義は常にこのパスに配置します。

## セットアップ方法

### 方法1: /setup コマンドを使用（推奨）

1. dd-know-how リポジトリをクローンまたはダウンロード
2. dd-know-how ディレクトリで Claude Code を起動
3. `/setup /path/to/your-project` を実行
4. 対話的に設定を選択

```bash
# 例
cd dd-know-how
claude
# Claude Code 内で
/setup /home/user/my-project
```

### 方法2: 手動セットアップ

#### Level 1（最小構成）

```bash
# 対象プロジェクトで実行
mkdir -p docs/DD docs/templates docs/archived/DD

# dd-know-how からテンプレートをコピー
cp dd-know-how/level-1-minimal/templates/dd_template.md docs/templates/
```

#### Level 2（標準構成）

```bash
# Level 1 の手順に加えて
mkdir -p .claude/commands

# コマンド定義をコピー
cp dd-know-how/level-2-standard/commands/dd.md .claude/commands/

# CLAUDE.md にスニペットを追記
cat dd-know-how/level-2-standard/CLAUDE.md.snippet >> CLAUDE.md
```

#### Level 3（フル構成）

```bash
# Level 2 までの手順に加えて
cp dd-know-how/level-3-full/commands/dd.md .claude/commands/  # 上書き
cp dd-know-how/level-3-full/commands/review.md .claude/commands/
cp dd-know-how/level-3-full/commands/review-spec.md .claude/commands/
```

## パス設定のカスタマイズ

コピーしたファイル内のパス参照を変更する場合:

### dd.md 内のパス

```markdown
# 変更前（デフォルト）
doc/DD/
doc/templates/dd_template.md
doc/archived/DD/

# 変更後の例（docs/ を使用する場合）
docs/DD/
docs/templates/dd_template.md
docs/archived/DD/
```

### CLAUDE.md 内のパス

```markdown
# 変更前
DDファイルは `doc/DD/` に配置

# 変更後の例
DDファイルは `docs/DD/` に配置
```

## 既存プロジェクトとの統合

### docs/ と doc/ の両方が存在する場合

1. プロジェクトの慣習を確認（どちらがメインか）
2. メインのドキュメントフォルダに DD を配置
3. 一貫性のため、どちらかに統一することを推奨

### 既存の DD や設計書がある場合

1. 既存の命名規則を確認
2. 可能であれば本ノウハウ集の規則に移行
3. 移行が難しい場合は、テンプレートをカスタマイズ

## 検証チェックリスト

セットアップ後、以下を確認:

- [ ] DDフォルダが正しいパスに存在する
- [ ] テンプレートファイルが配置されている
- [ ] アーカイブフォルダが作成されている
- [ ] `/dd new テスト` で新規DDが作成できる（Level 2以上）
- [ ] CLAUDE.md にDD運用ルールが記載されている

## トラブルシューティング

### /dd コマンドが認識されない

- `.claude/commands/dd.md` が存在するか確認
- Claude Code を再起動

### DDの作成先が意図と違う

- `dd.md` 内のパス設定を確認
- `CLAUDE.md` の記載と一致しているか確認

### テンプレートが見つからない

- テンプレートファイルのパスを確認
- `dd.md` 内のテンプレートパス設定を修正
