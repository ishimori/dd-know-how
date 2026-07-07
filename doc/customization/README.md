# カスタマイズガイド

DDノウハウをプロジェクトに合わせて調整するためのガイドです。

## カスタマイズ可能な項目

| 項目 | 説明 | 参照 |
|------|------|------|
| テンプレートのセクション | DDに含めるセクションの追加・削除 | [template-sections.md](template-sections.md) |
| 開発フローのステップ数 | 3, 5, 7, 9ステップから選択 | [development-flow-variants.md](development-flow-variants.md) |
| フォルダパス | `doc/DD/` 以外のパスを使用 | 本ファイル参照 |
| コマンド名 | `/dd` 以外のコマンド名を使用 | 本ファイル参照 |
| 他の環境での使用 | Claude Code / Codex 以外のAI/手動運用 | [other-environments.md](other-environments.md) |

## フォルダパスのカスタマイズ

デフォルトのフォルダ構成：

```
doc/
├── DD/
├── archived/
│   └── DD/
└── templates/
    └── dd_template.md
```

### 例1: docsフォルダを使用

```
doc/
├── design-documents/
├── archived/
│   └── design-documents/
└── templates/
    └── dd_template.md
```

**変更箇所:**
- `.dd-config` の `DD_DIR` / `ARCHIVE_DIR`
- `AGENTS.md.snippet` のパス参照
- `.claude/skills/dd/SKILL.md` のパス参照（変更後は `.agents/skills/dd/` ミラーにも同内容を反映）

### 例2: プロジェクトルート直下

```
design/
├── current/
├── done/
└── template.md
```

## コマンド名のカスタマイズ

`/dd` 以外のコマンド名を使用する場合：

### 例: `/doc` を使用

1. `.claude/skills/dd/` を `.claude/skills/doc/` にリネーム（SKILL.md の `name:` も変更）
2. ファイル内の説明を適宜修正
3. AGENTS.md のコマンド名参照を修正
4. `.agents/skills/` ミラーにも同じ変更を反映

### 例: `/design` を使用

DDを「Design Document」として明示的に呼ぶ場合。

1. `.claude/skills/dd/` を `.claude/skills/design/` にリネーム（`.agents/skills/` も同様）
2. AGENTS.md の説明を「Design Documentの操作」に変更

## 仕様書パスのカスタマイズ

Level 3の仕様書同期チェックで使用するパスを調整します。

### デフォルト

```
doc/spec/
├── 01_システム概要.md
├── 02_機能一覧.md
├── 03_画面仕様/
└── 04_テーブル定義.md
```

### 例: 英語フォルダ名

```
doc/spec/
├── overview.md
├── features.md
├── screens/
└── database.md
```

**変更箇所:**
- `.claude/skills/dd/SKILL.md` の仕様書同期チェック参照部分（`.agents/skills/dd/` ミラーにも反映）
- `spec-sync-check.md` のパス参照

## 日本語/英語の切り替え

このノウハウ集は日本語で書かれていますが、英語化する場合：

### テンプレートの英語化

```markdown
# DD-{number}: {title}

**Status**: In Progress

## Purpose

(What this DD decides or achieves)

## Background

(Why this DD is needed)

## Investigation

(Options comparison, research results)

## Decision

(What was finally decided)

## Tasks

- [ ] Task 1
- [ ] Task 2

## Log

### {date}
- DD created
```

### ステータスの英語化

| 日本語 | 英語 |
|--------|------|
| 進行中 | In Progress |
| 完了 | Completed |
| 未着手 | Pending |
| スキップ | Skipped |

## チーム固有のルール追加

### 例: レビュアー必須

DDに「レビュアー」セクションを追加：

```markdown
## レビュアー

| 名前 | 承認日 |
|------|--------|
| @yamada | 2024-01-15 |
```

### 例: 見積もり必須

DDに「工数見積もり」セクションを追加：

```markdown
## 工数見積もり

| タスク | 見積もり | 実績 |
|--------|----------|------|
| 実装 | 2日 | 1.5日 |
| テスト | 1日 | 1日 |
```

### 例: リスク管理

DDに「リスク」セクションを追加：

```markdown
## リスク

| リスク | 影響度 | 対策 |
|--------|--------|------|
| 既存機能への影響 | 高 | 既存テストで確認 |
| パフォーマンス劣化 | 中 | ベンチマーク実施 |
```

## 次のステップ

具体的なカスタマイズ方法：

- [template-sections.md](template-sections.md) - テンプレートのセクション追加例
- [development-flow-variants.md](development-flow-variants.md) - 開発フローのステップ数調整
- [other-environments.md](other-environments.md) - Claude Code / Codex 以外の環境での使用方法
