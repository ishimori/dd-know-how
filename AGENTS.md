# DD-Know-How プロジェクト設定

このファイルは DD-Know-How をベースにしたプロジェクトの Codex 設定テンプレートです。

## DD設定

- **DDフォルダ**: `doc/DD/`
- **アーカイブ**: `doc/archived/DD/`
- **テンプレート**: `templates/dd_template.md`
- **インデックス**: `doc/DD/DD-INDEX.md`

## 利用可能なスキル

> スキルは `.agents/skills/` に配置されています（skills形式）

### DD管理
- `/dd new タイトル` - 新規DD作成
- `/dd list` - DD一覧
- `/dd log メモ` - ログ追記
- `/dd archive 番号` - アーカイブ
- `/dd search キーワード` - DD検索
- `/dd rebuild-index` - インデックス再構築
- DA メソッド: `doc/da-method.md`（DA品質フィルター・再チェック条件）
- `/setup パス` - 外部プロジェクトへDD導入

## 開発フロー

詳細は `doc/development-flow.md`（5ステップ）を参照。

## プロジェクト固有の設定

```markdown
<!-- プロジェクトに合わせて以下を編集 -->

## 技術スタック
- フロントエンド:
- バックエンド:
- データベース:
- インフラ:

## コーディング規約
- 詳細: `templates/coding-standards.md`（コーディング基準書）
- コードレビュー時はこの基準書に基づいて評価する

## テスト方針
-

## セキュリティ要件
-
```
