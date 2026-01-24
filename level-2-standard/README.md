# Level 2: 標準構成

Level 1に加えて、スラッシュコマンドと開発フローを追加した構成です。

## Level 1からの追加要素

| 追加要素 | 効果 |
|----------|------|
| `/dd` コマンド | DDの作成・参照・アーカイブを統一的に操作 |
| 開発フロー | DD作成から完了までの標準プロセス |
| CLAUDE.md統合 | プロジェクト全体でDD運用ルールを共有 |

## 導入手順

### 1. Level 1を完了

[../level-1-minimal/README.md](../level-1-minimal/README.md) の手順を完了してください。

### 2. コマンド定義を配置

[commands/dd.md](commands/dd.md) を `.claude/commands/` にコピー

```
your-project/
└── .claude/
    └── commands/
        └── dd.md
```

### 3. CLAUDE.mdにスニペットを追記

[CLAUDE.md.snippet](CLAUDE.md.snippet) の内容をプロジェクトの `CLAUDE.md` に追記

### 4. 開発フローを確認

[development-flow.md](development-flow.md) で5ステップの開発フローを確認

## 含まれるファイル

| ファイル | 説明 |
|----------|------|
| [README.md](README.md) | このファイル |
| [CLAUDE.md.snippet](CLAUDE.md.snippet) | CLAUDE.mdに追記するスニペット |
| [commands/dd.md](commands/dd.md) | `/dd` コマンド定義 |
| [development-flow.md](development-flow.md) | 5ステップ開発フロー |

## /dd コマンドの使い方

| コマンド | 機能 |
|----------|------|
| `/dd {番号}` | DD参照（DD-001, 001, 1 など柔軟に指定可能） |
| `/dd new タイトル` | 新規DD作成 |
| `/dd list` | 進行中DD一覧 |
| `/dd archive {番号}` | DDをアーカイブ |

**例:**
```
/dd new ログイン機能の実装
→ DD-001_ログイン機能の実装.md を作成

/dd 001
→ DD-001の内容を表示

/dd list
→ 進行中のDD一覧を表示

/dd archive 001
→ DD-001をアーカイブ
```

## 5ステップ開発フロー

```
Step 1: DD作成       → 何を作るか明確化
Step 2: 仕様確認     → 認識合わせ
Step 3: 実装         → コーディング
Step 4: 検証         → テスト・レビュー
Step 5: 完了         → コミット・DDアーカイブ
```

詳細は [development-flow.md](development-flow.md) を参照。

## フォルダ構成（Level 2完了後）

```
your-project/
├── CLAUDE.md                    # DD運用ルールを追記
├── .claude/
│   └── commands/
│       └── dd.md                # /dd コマンド定義
└── doc/
    ├── DD/
    ├── archived/
    │   └── DD/
    └── templates/
        └── dd_template.md
```

## 次のステップ

Level 3に進むと、以下が追加されます：

- 仕様書との同期チェック
- より詳細な9ステップ開発フロー
- 実装前チェックの仕組み

→ [../level-3-full/README.md](../level-3-full/README.md)
