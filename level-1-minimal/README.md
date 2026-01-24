# Level 1: 最小構成

DDテンプレートと基本ルールだけで始める最小構成です。

## 導入手順

### 1. フォルダ構成を作成

```
your-project/
└── doc/
    ├── DD/                    # 進行中のDD
    ├── archived/
    │   └── DD/                # 完了したDD
    └── templates/
        └── dd_template.md     # テンプレート
```

### 2. テンプレートを配置

[templates/dd_template.md](templates/dd_template.md) を `doc/templates/` にコピー

### 3. 基本ルールを理解

[rules/dd-basic-rules.md](rules/dd-basic-rules.md) を読んで運用ルールを把握

## 含まれるファイル

| ファイル | 説明 |
|----------|------|
| [templates/dd_template.md](templates/dd_template.md) | DDテンプレート（汎用版） |
| [rules/dd-basic-rules.md](rules/dd-basic-rules.md) | 命名規則、ステータス管理、アーカイブ手順 |

## 基本的な使い方

### DD作成

1. テンプレートをコピー
2. `DD-{番号}_{タイトル}.md` でファイル名をつける
3. `doc/DD/` に配置

```
例: doc/DD/DD-001_ログイン機能の実装.md
```

### DD更新

1. タスク完了時は `[ ]` → `[x]` に変更
2. ログセクションに実施内容を追記

### DD完了

1. 全タスクが完了したらステータスを「完了」に変更
2. `doc/archived/DD/` に移動

## 次のステップ

Level 2に進むと、以下が追加されます：

- `/dd` コマンドで操作を効率化
- 開発フローとの統合
- CLAUDE.mdへの統合

→ [../level-2-standard/README.md](../level-2-standard/README.md)
