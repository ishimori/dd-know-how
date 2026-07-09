#!/usr/bin/env bash
# =============================================================================
# dd-update-core.sh — DD一式の Pull 型更新・本体（dd-know-how 側に常駐）
#
# 各プロジェクトの scripts/dd-update.sh（呼び出し口スタブ）から exec され、
# 対象プロジェクトへ配布物（scripts / hooks / スキル / テンプレート / 方法論文書）
# を取り込む。スタブ経由で常に dd-know-how の最新ロジックが実行されるため、
# 本体の配り直しは不要。
#
# 使い方（直接実行する場合）:
#   bash tools/dd-update-core.sh --target /path/to/project [--dry-run]
#
# 原則:
#   - プロジェクト固有ファイルには一切触れない: .dd-config（無い場合の新規生成のみ）/
#     CLAUDE.md / AGENTS.md / DOC-MAP.md / DD-INDEX.md（再生成コマンド経由のみ）/
#     engineering-patterns.md / decisions.md
#   - コミットはしない（diff の確認とコミットは人間または呼び出し元のLLMが行う）
#   - 実体が変わるファイルだけコピーして「更新」として報告する（cmp で判定）
#   - 導入済みの構成にだけ従う（スキル/フック/任意スクリプトは存在する場所のみ更新）
# =============================================================================
set -euo pipefail

KH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TARGET=""
DRY=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)  TARGET="${2:?--target にパスが必要}"; shift 2 ;;
        --dry-run) DRY=1; shift ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done
if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
    echo "ERROR: --target <プロジェクトルート> を指定してください" >&2
    exit 2
fi
TARGET="$(cd "$TARGET" && pwd)"
if [ "$TARGET" = "$KH" ]; then
    echo "ERROR: dd-know-how 自身は更新対象にできません" >&2
    exit 2
fi

updated=0
notes=()

# 差分があるときだけコピーして報告する
put() {  # put <src> <dst>
    local src="$1" dst="$2"
    if [ ! -f "$src" ]; then
        notes+=("⚠️ ソースに存在しないためスキップ: $src")
        return 0
    fi
    if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
        return 0   # 変更なし（静かにスキップ）
    fi
    if [ "$DRY" -eq 1 ]; then
        echo "  + $dst（更新予定）"
    else
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        echo "  + $dst（更新）"
    fi
    updated=$((updated + 1))
}

echo "# DD更新: $TARGET"
echo "- ソース: $KH（$(git -C "$KH" log -1 --format='%h %s' 2>/dev/null || echo 'git情報なし')）"
[ "$DRY" -eq 1 ] && echo "- モード: --dry-run（ファイルは変更しません）"

# --- 対象の git 状態を確認（別ブランチ・未コミット変更への注意喚起） ---
if git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    br="$(git -C "$TARGET" rev-parse --abbrev-ref HEAD)"
    echo "- 対象ブランチ: $br"
    if [ "$br" != "main" ] && [ "$br" != "master" ]; then
        echo "  ⚠️ main 以外のブランチです。取り込み先ブランチが正しいか確認してください"
    fi
    if [ -n "$(git -C "$TARGET" status --porcelain 2>/dev/null)" ]; then
        echo "  ⚠️ 未コミットの変更があります。更新分と混ざるため、先にコミットしておくのを推奨"
    fi
else
    echo "- 対象は git 管理外です（diff での差分確認ができないため注意）"
fi

cd "$TARGET"

# .dd-config を安全に読む（source しない = 設定ファイル内の任意コード実行を防止）。
# KEY="value" / KEY=value 形式の行から、パスとして妥当な文字だけを1件抽出する。
dd_config_get() {  # dd_config_get KEY FILE
    [ -f "$2" ] || return 0
    sed -n "s|^[[:space:]]*${1}[[:space:]]*=[[:space:]]*\"\{0,1\}\([A-Za-z0-9 ._:/~-]*\)\"\{0,1\}[[:space:]]*\$|\1|p" "$2" 2>/dev/null | head -1
}

# --- .dd-config（無ければ実レイアウトから生成。既存ファイルは不可侵） ---
if [ -f .dd-config ]; then
    DD_DIR="$(dd_config_get DD_DIR .dd-config)"
    ARCHIVE_DIR="$(dd_config_get ARCHIVE_DIR .dd-config)"
    DOC_DIR="$(dd_config_get DOC_DIR .dd-config)"
    TEMPLATES_DIR="$(dd_config_get TEMPLATES_DIR .dd-config)"
else
    dd_guess="doc/DD"
    [ ! -d doc/DD ] && [ -d docs/DD ] && dd_guess="docs/DD"
    arc_guess="doc/archived/DD"
    [ -d "$dd_guess/archive" ] && arc_guess="$dd_guess/archive"
    [ "$dd_guess" = "docs/DD" ] && [ -d docs/archived/DD ] && arc_guess="docs/archived/DD"
    doc_guess="doc"
    [ ! -d doc ] && [ -d docs ] && doc_guess="docs"
    if [ "$DRY" -eq 1 ]; then
        echo "- .dd-config が無いため生成予定: DD_DIR=$dd_guess / ARCHIVE_DIR=$arc_guess / DOC_DIR=$doc_guess"
    else
        {
            echo "# DD運用パス設定（dd-update が実レイアウトから自動生成。値を確認して必要なら修正）"
            echo "DD_DIR=\"$dd_guess\""
            echo "ARCHIVE_DIR=\"$arc_guess\""
            echo "DOC_DIR=\"$doc_guess\""
        } > .dd-config
        echo "- .dd-config を生成しました（DD_DIR=$dd_guess / ARCHIVE_DIR=$arc_guess）→ 値を確認してください"
    fi
    DD_DIR="$dd_guess"; ARCHIVE_DIR="$arc_guess"; DOC_DIR="$doc_guess"
fi
DD_DIR="${DD_DIR:-doc/DD}"
DOC_DIR="${DOC_DIR:-doc}"

# --- テンプレートフォルダの検出（.dd-config の TEMPLATES_DIR が最優先） ---
TPL_DIR="${TEMPLATES_DIR:-}"
if [ -z "$TPL_DIR" ]; then
    for d in "$DOC_DIR/templates" doc/templates docs/templates templates; do
        if [ -f "$d/dd_template.md" ]; then TPL_DIR="$d"; break; fi
    done
fi

echo ""
echo "## 取り込み"

# 1) scripts/（常に上書きOK群。codex-review は導入済みの場合のみ）
for s in dd-index-gen.sh dd-health.sh doc-check.sh dd-update.sh; do
    put "$KH/templates/scripts/$s" "scripts/$s"
done
if [ -f scripts/codex-review.sh ]; then
    put "$KH/templates/scripts/codex-review.sh" "scripts/codex-review.sh"
fi

# 2) hooks（.claude / .codex / .agents の導入済みディレクトリにのみ）
for hd in .claude/hooks .codex/hooks .agents/hooks; do
    [ -d "$hd" ] || continue
    put "$KH/templates/hooks/post-bash-dd-archive-reminder.sh" "$hd/post-bash-dd-archive-reminder.sh"
    put "$KH/templates/hooks/pre-edit-guard.sh" "$hd/pre-edit-guard.sh"
    if [ -f "$hd/post-edit-lint.mjs" ]; then
        put "$KH/templates/hooks/post-edit-lint.mjs" "$hd/post-edit-lint.mjs"
    fi
done

# 3) スキル（正本 .claude/skills/ を単一ソースに、導入済みの各置き場へ。
#    .agents/skills/ は Codex 用ミラー — dd-know-how 側の .agents/ からはコピーしない）
for sd in .claude/skills .agents/skills; do
    if [ -f "$sd/dd/SKILL.md" ]; then
        put "$KH/.claude/skills/dd/SKILL.md" "$sd/dd/SKILL.md"
    fi
done

# 4) テンプレート
if [ -n "$TPL_DIR" ]; then
    for t in dd_template.md dd_template_bugfix.md dd_template_tdd.md dd_template_mock.md \
             dd_template_e2e.md guides.md screen-spec-template.md coding-standards.md; do
        put "$KH/templates/$t" "$TPL_DIR/$t"
    done
else
    notes+=("⚠️ テンプレートフォルダが見つからず未更新（.dd-config に TEMPLATES_DIR=\"doc/templates\" を設定すると明示できます）")
fi

# 5) 方法論文書（導入済みの場合のみ）
for m in da-method.md spec-sync-check.md; do
    if [ -f "$DOC_DIR/$m" ]; then
        put "$KH/doc/$m" "$DOC_DIR/$m"
    fi
done

echo "（表示されないファイル = 既に最新）"

# --- DD-INDEX 再生成（フォーマット追随。dry-run では実行しない） ---
if [ "$DRY" -eq 0 ] && [ -f scripts/dd-index-gen.sh ] && [ -d "$DD_DIR" ]; then
    echo ""
    echo "## DD-INDEX 再生成"
    bash scripts/dd-index-gen.sh || notes+=("⚠️ dd-index-gen.sh が失敗。.dd-config のパス設定を確認してください")
fi

# --- まとめ ---
echo ""
echo "## 結果"
echo "- 更新ファイル: $updated 件"
for n in "${notes[@]:-}"; do
    [ -n "$n" ] && echo "- $n"
done
if [ "$DRY" -eq 0 ]; then
    if git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "- 変更一覧（git status --short）:"
        git -C "$TARGET" status --short | sed 's/^/    /'
    fi
    echo ""
    echo "次にやること:"
    echo "  1. 差分を確認する（git diff）"
    echo "  2. 問題なければコミットする（このスクリプトはコミットしません）"
    echo "  3. スキル・フックの変更はエージェント（Claude Code / Codex）の再起動後に有効"
else
    echo ""
    echo "実際に取り込むには --dry-run なしで再実行してください"
fi
