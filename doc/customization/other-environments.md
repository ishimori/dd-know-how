# Claude Code以外の環境での使用方法

DDノウハウはClaude Codeのスラッシュコマンドを活用していますが、他の環境でも運用できます。

## 環境別の対応方法

### 1. 他のAIアシスタント（ChatGPT, Copilot等）

スラッシュコマンドは使えませんが、DDの運用自体は可能です。

#### DDテンプレートの使用

1. テンプレートをプロジェクトに配置
2. 新規DDはテンプレートをコピーして作成
3. AIに「DD-001を参照して」と指示すればファイルを読んでもらえる

#### コマンドの代替

| Claude Code | 他のAIアシスタント |
|-------------|-------------------|
| `/dd new タイトル` | 「DDテンプレートを使って新しいDDを作成して」 |
| `/dd 001` | 「DD-001の内容を読んで要約して」 |
| `/dd list` | 「doc/DD/にあるDDの一覧を表示して」 |
| `/dd archive 001` | 「DD-001をdoc/archived/DD/に移動して」 |

#### CLAUDE.mdの代替

他のAIアシスタントでは、以下のいずれかで対応：

- **システムプロンプト**: DD運用ルールをシステムプロンプトに設定
- **プロジェクトルール**: Copilot Workspaceの`.github/copilot-instructions.md`等に記載
- **都度指示**: 必要に応じてDD運用ルールを伝える

### 2. 手動運用（AIなし）

AIを使わずに手動でDDを運用する場合。

#### 基本フロー

1. **DD作成**: テンプレートをコピー、ファイル名を `DD-{番号}_{タイトル}.md` に変更
2. **DD更新**: エディタで直接編集、タスク完了時は `[x]` に変更、ログを追記
3. **DDアーカイブ**: ファイルを `doc/archived/DD/` に手動で移動

#### 番号管理

手動運用では番号の重複に注意が必要です。

```bash
# 最大番号を確認（Bash）
ls doc/DD/DD-*.md doc/archived/DD/DD-*.md 2>/dev/null | \
  grep -oE 'DD-[0-9]+' | sort -u | tail -1

# PowerShell
Get-ChildItem -Path doc/DD/DD-*.md, doc/archived/DD/DD-*.md -ErrorAction SilentlyContinue |
  Select-String -Pattern 'DD-(\d+)' |
  ForEach-Object { $_.Matches.Groups[1].Value } |
  Sort-Object | Select-Object -Last 1
```

### 3. Cursor / Windsurf

CursorやWindsurfでは、`.cursorrules` や同等のファイルにDD運用ルールを記載できます。

```markdown
# .cursorrules

## DD設計書運用ルール

（CLAUDE.md.snippetの内容をここに貼り付け）
```

### 4. VS Code + GitHub Copilot

`.github/copilot-instructions.md` にDD運用ルールを記載。

```markdown
# Copilot Instructions

## DD設計書運用ルール

（CLAUDE.md.snippetの内容をここに貼り付け）
```

## Level別の対応

### Level 1（手動でも運用可能）

| 項目 | Claude Code | 手動運用 |
|------|-------------|---------|
| DDテンプレート | ✓ | ✓ |
| 基本ルール | ✓ | ✓ |
| ファイル命名 | ✓ | ✓ |
| タスク管理 | ✓ | ✓ |

### Level 2（AIアシスタント推奨）

| 項目 | Claude Code | 手動運用 |
|------|-------------|---------|
| `/dd` コマンド | ✓ | △（手動操作で代替） |
| 開発フロー | ✓ | ✓（意識して実行） |
| 進捗表示 | ✓ | ✗ |

## 推奨環境

| 運用スタイル | 推奨環境 |
|-------------|---------|
| フル機能で運用 | Claude Code |
| 他のAIで運用 | ChatGPT, Copilot + 手動コマンド代替 |
| AIなしで運用 | Level 1のみ + 手動操作 |
| チーム開発 | Claude Code または 共通ルールを文書化 |

## 移行パス

### 手動運用 → Claude Code

1. 既存のDDファイルはそのまま使用可能
2. `.claude/commands/dd.md` を配置するだけでコマンドが使える
3. CLAUDE.mdにスニペットを追加

### Claude Code → 他のAI

1. DDファイルはそのまま使用可能（Markdown形式は汎用的）
2. CLAUDE.mdの内容を他のAIのルールファイルに移植
3. コマンドは手動操作または自然言語で代替
