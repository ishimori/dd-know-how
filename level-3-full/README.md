# Level 3: フル構成

Level 2に加えて、仕様書連携と詳細な9ステップ開発フローを追加した完全構成です。

## Level 2からの追加要素

| 追加要素 | 効果 |
|----------|------|
| 仕様書同期チェック | DDの変更が仕様書に反映されているか自動確認 |
| 9ステップ開発フロー | より詳細なプロセス管理 |
| 実装前チェック | 仕様書・既存コードを事前確認 |
| `/review` コマンド | コード・ドキュメントの規約チェック |
| `/review-spec` コマンド | 実装前チェックの検証 |

## 導入手順

### 1. Level 2を完了

[../level-2-standard/README.md](../level-2-standard/README.md) の手順を完了してください。

### 2. コマンド定義を更新

[commands/dd.md](commands/dd.md) で Level 2 の `/dd` コマンドを置き換え

### 3. 仕様書フォルダを整備

```
your-project/
└── doc/
    └── spec/                  # 仕様書フォルダ
        ├── 01_システム概要.md
        ├── 02_機能一覧.md
        ├── 03_画面仕様/
        │   └── ...
        └── 04_テーブル定義.md
```

### 4. 開発フローを確認

[development-flow-9steps.md](development-flow-9steps.md) で9ステップの開発フローを確認

## 含まれるファイル

| ファイル | 説明 |
|----------|------|
| [README.md](README.md) | このファイル |
| [commands/dd.md](commands/dd.md) | `/dd` コマンド（仕様書連携付き） |
| [commands/review.md](commands/review.md) | `/review` コマンド（規約チェック） |
| [commands/review-spec.md](commands/review-spec.md) | `/review-spec` コマンド（実装前チェック検証） |
| [development-flow-9steps.md](development-flow-9steps.md) | 9ステップ開発フロー |
| [spec-sync-check.md](spec-sync-check.md) | 仕様書同期チェックの詳細 |

## 9ステップ開発フロー

```
Step 1: DD作成          「〇〇機能を作りたい」
Step 2: 仕様確認        ユーザー承認を得る
Step 3: 実装前チェック  仕様書・既存コードを確認
Step 4: コーディング    規約に従って実装
Step 5: テスト作成      必要に応じてテストを作成
Step 6: コード検証      Lint + セルフチェック + 動作確認
Step 7: レビュー        コードレビュー
Step 8: 仕様書同期      DDの変更を仕様書に反映
Step 9: コミット        git commit → /dd archive
```

詳細は [development-flow-9steps.md](development-flow-9steps.md) を参照。

## 仕様書同期チェック

`/dd archive` 実行時に自動で仕様書同期チェックが実行されます。

**チェック内容:**
- DDで追加・変更した機能が仕様書に記載されているか
- 新しい画面が画面仕様書に記載されているか
- テーブル変更がテーブル定義に反映されているか

**出力例:**
```
## 仕様書同期チェック結果

| 変更内容 | 関連仕様書 | 反映状況 |
|----------|-----------|----------|
| ログイン画面を追加 | 03_画面仕様/login.md | ✅ 反映済 |
| usersテーブルにカラム追加 | 04_テーブル定義.md | ⚠️ 要確認 |
```

詳細は [spec-sync-check.md](spec-sync-check.md) を参照。

## フォルダ構成（Level 3完了後）

```
your-project/
├── CLAUDE.md
├── .claude/
│   └── commands/
│       ├── dd.md              # 仕様書連携付き版
│       ├── review.md          # 規約チェック
│       └── review-spec.md     # 実装前チェック検証
└── doc/
    ├── DD/
    ├── archived/
    │   └── DD/
    ├── templates/
    │   └── dd_template.md
    └── spec/                  # 仕様書フォルダ
        ├── 01_システム概要.md
        ├── 02_機能一覧.md
        ├── 03_画面仕様/
        └── 04_テーブル定義.md
```

## カスタマイズ

仕様書のフォルダ構成をプロジェクトに合わせて調整できます。

→ [../customization/README.md](../customization/README.md)
