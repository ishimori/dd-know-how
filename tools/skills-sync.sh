#!/usr/bin/env bash
# =============================================================================
# skills-sync.sh — スキル正本（.claude/skills/）を .agents/skills/ へミラー
#
# 正本は .claude/skills/ のみ。.agents/skills/ は Codex がスキルを読むための
# 生成物であり、直接編集しない（編集しても本スクリプトで上書きされる）。
# 配布（dd-update-core.sh / setup）も常に正本からコピーするため、
# このミラーは dd-know-how リポジトリを直接 Codex で開く人のためにある。
#
# 使い方:
#   bash tools/skills-sync.sh           # 同期実行
#   bash tools/skills-sync.sh --check   # 差分検出のみ（差分があれば exit 1。コミット前チェック用）
# =============================================================================
set -euo pipefail

KH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$KH/.claude/skills"
DST="$KH/.agents/skills"

CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

[ -d "$SRC" ] || { echo "ERROR: スキル正本が見つかりません: $SRC" >&2; exit 2; }

drift=0

# 正本 → ミラー（内容が異なるファイルのみ）
while IFS= read -r -d '' f; do
    rel="${f#"$SRC"/}"
    dst="$DST/$rel"
    if [ ! -f "$dst" ] || ! cmp -s "$f" "$dst"; then
        drift=$((drift + 1))
        if [ "$CHECK" -eq 1 ]; then
            echo "DRIFT: $rel"
        else
            mkdir -p "$(dirname "$dst")"
            cp "$f" "$dst"
            echo "  + .agents/skills/$rel（更新）"
        fi
    fi
done < <(find "$SRC" -type f -print0)

# ミラーにだけ存在するファイル（正本から消えたもの）
if [ -d "$DST" ]; then
    while IFS= read -r -d '' f; do
        rel="${f#"$DST"/}"
        if [ ! -f "$SRC/$rel" ]; then
            drift=$((drift + 1))
            if [ "$CHECK" -eq 1 ]; then
                echo "ORPHAN: $rel（正本に存在しない）"
            else
                rm "$f"
                echo "  - .agents/skills/$rel（正本に無いため削除）"
            fi
        fi
    done < <(find "$DST" -type f -print0)
fi

if [ "$CHECK" -eq 1 ]; then
    if [ "$drift" -gt 0 ]; then
        echo "✗ .agents/skills/ が正本と $drift 件ずれています → bash tools/skills-sync.sh で同期してください"
        exit 1
    fi
    echo "✓ .agents/skills/ は正本（.claude/skills/）と一致"
else
    if [ "$drift" -eq 0 ]; then
        echo "✓ 変更なし（既に同期済み）"
    else
        echo "✓ 同期完了（$drift 件）"
    fi
fi
