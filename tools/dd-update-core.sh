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
#   bash tools/dd-update-core.sh --target /path/to/project [--dry-run] [--adopt-content]
#     --adopt-content: テンプレ/スキル/方法論文書のローカル改変を無視して強制上書き
#
# 原則:
#   - プロジェクト固有ファイルには一切触れない: .dd-config（無い場合の新規生成のみ）/
#     CLAUDE.md / AGENTS.md / DOC-MAP.md / DD-INDEX.md（再生成コマンド経由のみ）/
#     engineering-patterns.md / decisions.md
#   - コミットはしない（diff の確認とコミットは人間または呼び出し元のLLMが行う）
#   - 2層で扱う:
#       * コード（scripts/ ・ hooks/）… 常に上書き（プロジェクト固有の値は持たない）
#       * コンテンツ（テンプレ・スキル・方法論文書）… put_safe で保護。利用先がパス参照等を
#         ローカル改変していれば上書きせず手動確認に回す（改変判定は .dd-manifest を使う）
#   - 導入済みの構成にだけ従う（スキル/フック/任意スクリプトは存在する場所のみ更新）
# =============================================================================
set -euo pipefail

KH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TARGET=""
DRY=0
ADOPT=0   # --adopt-content: ローカル改変を無視してコンテンツ(テンプレ/スキル/方法論文書)も強制上書き
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)         TARGET="${2:?--target にパスが必要}"; shift 2 ;;
        --dry-run)        DRY=1; shift ;;
        --adopt-content)  ADOPT=1; shift ;;
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
content_skipped=()          # ローカル改変を検出して上書きを見送ったコンテンツ（"dst<TAB>src"）
declare -A MF               # マニフェスト: 相対パス -> 前回配布時のハッシュ
DD_MANIFEST=".dd-manifest"  # 対象リポジトリ直下（cd 後に読み書き）

dd_hash() { sha1sum "$1" 2>/dev/null | cut -d' ' -f1; }

# 差分があるときだけコピーして報告する（スクリプト/フック用＝常に上書きしてよいコード）
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

# コンテンツ用の安全なコピー（テンプレ/スキル/方法論文書＝利用先がパス調整等で
# ローカル改変することがある）。改変を検出したら上書きせず手動確認を促す。
#   - dst 無し                         → 新規作成
#   - dst == src                       → 何もしない（既に最新。ハッシュだけ記録）
#   - dst がマニフェスト記録と一致       → 前回配布から未改変 → 新版を採用
#   - --adopt-content 指定              → 強制上書き
#   - それ以外（ローカル改変 or 初回で判定不可） → 上書きせずスキップし手動確認へ
put_safe() {  # put_safe <src> <dst>
    local src="$1" dst="$2" sh dh mh
    if [ ! -f "$src" ]; then
        notes+=("⚠️ ソースに存在しないためスキップ: $src")
        return 0
    fi
    if [ ! -f "$dst" ]; then
        if [ "$DRY" -eq 1 ]; then
            echo "  + $dst（新規作成予定）"
        else
            mkdir -p "$(dirname "$dst")"
            cp "$src" "$dst"
            echo "  + $dst（新規作成）"
            MF["$dst"]="$(dd_hash "$dst")"
        fi
        updated=$((updated + 1))
        return 0
    fi
    if cmp -s "$src" "$dst"; then
        MF["$dst"]="$(dd_hash "$dst")"   # 一致 → 記録だけ最新化して静かに終了
        return 0
    fi
    sh="$(dd_hash "$src")"; dh="$(dd_hash "$dst")"; mh="${MF[$dst]:-}"
    if [ "$ADOPT" -eq 1 ] || { [ -n "$mh" ] && [ "$mh" = "$dh" ]; }; then
        # 強制採用、または「前回配布から未改変」→ 新版を採用
        if [ "$DRY" -eq 1 ]; then
            echo "  + $dst（更新予定）"
        else
            cp "$src" "$dst"
            echo "  + $dst（更新）"
            MF["$dst"]="$sh"
        fi
        updated=$((updated + 1))
        return 0
    fi
    # ローカル改変あり（または初回で判定不可）→ 保護してスキップ。マニフェストは触らない
    content_skipped+=("$dst"$'\t'"$src")
    return 0
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

# コンテンツ改変判定のためのマニフェスト（前回配布時のハッシュ）を読み込む
MANIFEST_EXISTED=0
if [ -f "$DD_MANIFEST" ]; then
    MANIFEST_EXISTED=1
    while IFS=$'\t' read -r _h _p; do
        [ -n "${_p:-}" ] && MF["$_p"]="$_h"
    done < "$DD_MANIFEST"
fi

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
#    ※ put_safe: 利用先がパス参照等をローカル改変している場合は上書きしない
for sd in .claude/skills .agents/skills; do
    if [ -f "$sd/dd/SKILL.md" ]; then
        put_safe "$KH/.claude/skills/dd/SKILL.md" "$sd/dd/SKILL.md"
    fi
done

# 4) テンプレート（put_safe: ローカル改変を保護）
if [ -n "$TPL_DIR" ]; then
    for t in dd_template.md dd_template_bugfix.md dd_template_tdd.md dd_template_mock.md \
             dd_template_e2e.md guides.md screen-spec-template.md coding-standards.md; do
        put_safe "$KH/templates/$t" "$TPL_DIR/$t"
    done
else
    notes+=("⚠️ テンプレートフォルダが見つからず未更新（.dd-config に TEMPLATES_DIR=\"doc/templates\" を設定すると明示できます）")
fi

# 5) 方法論文書（導入済みの場合のみ。put_safe: ローカル改変を保護）
for m in da-method.md spec-sync-check.md; do
    if [ -f "$DOC_DIR/$m" ]; then
        put_safe "$KH/doc/$m" "$DOC_DIR/$m"
    fi
done

echo "（表示されないファイル = 既に最新）"

# --- コンテンツのマニフェストを書き出す（次回の改変判定に使用） ---
if [ "$DRY" -eq 0 ] && [ ${#MF[@]} -gt 0 ]; then
    { for _p in "${!MF[@]}"; do printf '%s\t%s\n' "${MF[$_p]}" "$_p"; done; } | LC_ALL=C sort -k2 > "$DD_MANIFEST"
    [ "$MANIFEST_EXISTED" -eq 0 ] && notes+=(".dd-manifest を新規生成しました（コンテンツの改変判定に使う基準。git にコミットしておくと次回以降の判定が安定します）")
fi

# --- ローカル改変で上書きを見送ったコンテンツを手動確認に回す ---
if [ ${#content_skipped[@]} -gt 0 ]; then
    echo ""
    echo "## ⚠️ 手動確認が必要なコンテンツ（ローカル改変を検出 → 自動上書きせず保護）"
    echo "  以下はパス調整等のローカル編集が入っているため上書きしませんでした。"
    echo "  新版を取り込むなら差分を手動マージするか、全面採用なら --adopt-content を付けて再実行してください:"
    for _e in "${content_skipped[@]}"; do
        _dst="${_e%%$'\t'*}"; _src="${_e#*$'\t'}"
        echo "    - $_dst"
        echo "        差分: diff \"$_src\" \"$_dst\""
    done
fi

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
