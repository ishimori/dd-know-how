#!/usr/bin/env bash
# =============================================================================
# dd-update.sh — DD一式を dd-know-how から取り込む（Pull型更新の呼び出し口）
#
# 使い方:
#   bash scripts/dd-update.sh --dry-run   # 更新内容の事前確認
#   bash scripts/dd-update.sh             # 取り込み（コミットはしない）
#
# 本体ロジックは dd-know-how 側（tools/dd-update-core.sh）にあり、常に最新が
# 実行される（このスタブ自体もそこから更新される）。
# dd-know-how の場所は .dd-config の SOURCE_REPO で指定できる。
# 省略時はプロジェクトの兄弟ディレクトリ ../dd-know-how を使う。
# =============================================================================
set -euo pipefail

# 自己位置からプロジェクトルートを解決（CWD非依存。他のDDスクリプトと同一方式）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
if [ ! -f "$PROJECT_ROOT/.dd-config" ]; then
    _p="$SCRIPT_DIR"
    while [ -n "$_p" ] && [ "$_p" != "/" ] && [ "$_p" != "." ]; do
        if [ -f "$_p/.dd-config" ]; then PROJECT_ROOT="$_p"; break; fi
        _p="$(dirname "$_p")"
    done
fi
# shellcheck source=/dev/null
[ -f "$PROJECT_ROOT/.dd-config" ] && . "$PROJECT_ROOT/.dd-config"

SOURCE_REPO="${SOURCE_REPO:-$PROJECT_ROOT/../dd-know-how}"
CORE="$SOURCE_REPO/tools/dd-update-core.sh"
if [ ! -f "$CORE" ]; then
    {
        echo "ERROR: dd-know-how が見つかりません: $SOURCE_REPO"
        echo "  対処: .dd-config に次の1行を追記してください（実際の場所に合わせる）:"
        echo '    SOURCE_REPO="C:/repo/dd-know-how"'
    } >&2
    exit 1
fi

exec bash "$CORE" --target "$PROJECT_ROOT" "$@"
