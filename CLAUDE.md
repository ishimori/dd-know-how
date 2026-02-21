# DD-Know-How プロジェクト設定

このファイルは DD-Know-How をベースにしたプロジェクトの Claude Code 設定テンプレートです。

## DD設定

- **フロー**: full（9ステップ）
- **DDフォルダ**: `doc/DD/`
- **アーカイブ**: `doc/archived/DD/`
- **テンプレート**: `templates/dd_template.md`

## 利用可能なスキル

> スキルは `.claude/skills/` に配置されています（skills形式）

### DD管理
- `/dd new タイトル` - 新規DD作成
- `/dd status` - 進捗確認
- `/dd list` - DD一覧
- `/dd log メモ` - ログ追記
- `/dd archive 番号` - アーカイブ
- `/workflow` - 9ステップ開発フロー・Phase管理・DA批判レビュー・GEM分析
- `/setup パス` - 外部プロジェクトへDD導入

## 参考パターン集（言語別）

| 言語 | ファイル | 内容 |
|------|---------|------|
| TypeScript | `skills/typescript/backend.md` | バックエンド設計パターン |
| TypeScript | `skills/typescript/frontend.md` | フロントエンド設計パターン |
| Python | `skills/python/streamlit.md` | Streamlitアプリ開発パターン |

新しい言語を追加する場合は `skills/{言語}/` にファイルを追加。

## 開発フロー

### Standard（5ステップ）
1. DD作成
2. 実装
3. テスト
4. レビュー
5. コミット・アーカイブ

### Full（9ステップ）
1. DD作成
2. 仕様確認
3. 実装前チェック
4. コーディング
5. テスト作成
6. コード検証
7. レビュー
8. 仕様書同期
9. コミット・アーカイブ

詳細は `doc/development-flow.md` または `doc/development-flow-full.md` を参照。

## プロジェクト固有の設定

```markdown
<!-- プロジェクトに合わせて以下を編集 -->

## 技術スタック
- フロントエンド:
- バックエンド:
- データベース:
- インフラ:

## コーディング規約
-

## テスト方針
-

## セキュリティ要件
-
```
