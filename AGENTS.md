# DD-Know-How プロジェクト設定

全エージェント共通の正本です（Codex はこのファイルを直接、Claude Code は CLAUDE.md の `@AGENTS.md` インポート経由で読む）。

## DD設定

- **DDフォルダ**: `doc/DD/`
- **アーカイブ**: `doc/archived/DD/`
- **テンプレート**: `templates/dd_template.md`
- **インデックス**: `doc/DD/DD-INDEX.md`
- **パス設定**: ルート直下 `.dd-config`（スクリプト・フックはここを読む。`templates/dd-config.example` 参照）
- **ステータス**: 固定6種（検討中/進行中/確認待ち/保留/見送り/完了）+ 補足列（語彙ルール: `templates/guides.md` §3）

## 利用可能なスキル

> スキル正本は `.claude/skills/`（Claude Code が読む）。`.agents/skills/`（Codex が読む）は `bash tools/skills-sync.sh` が生成する同一内容のミラー — 直接編集しない。

### DD管理
- `/dd new タイトル` - 新規DD作成
- `/dd list` - DD一覧
- `/dd log メモ` - ログ追記
- `/dd archive 番号` - アーカイブ
- `/dd search キーワード` - DD検索
- `/dd rebuild-index` - インデックス再構築
- `/dd health` - DD運用ヘルスチェック（滞留・クローズ漏れ・形骸化の検出）
- DA メソッド: `doc/da-method.md`（DA品質フィルター・再チェック条件）
- `/setup パス` - 外部プロジェクトへDD導入

（Codex ではスラッシュの代わりに `$dd` / `$setup` で呼び出す）

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
