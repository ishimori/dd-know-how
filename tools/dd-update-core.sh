#!/usr/bin/env bash
# =============================================================================
# dd-update-core.sh — 導入先と dd-know-how の配布物の差分レポート（読み取り専用）
#
# dd-know-how 側に常駐し、各プロジェクトの scripts/dd-update.sh（呼び出し口スタブ）から
# exec される。導入先のファイルは一切変更しない。取り込みはこのレポートを見て、
# ファイルごとに人が判断して行う（エージェントが行う場合もファイルごとにユーザーの確認を取る）。
# v8 で一括取り込みを廃止した — 安定稼働中のリポジトリへ、確認なしで配布物を流し込まないため。
#
# 使い方（直接実行する場合）:
#   bash tools/dd-update-core.sh --target /path/to/project
#
# 分類（改行コードの違いは無視して比べる）:
#   上流だけ変更     … 導入先は過去の配布版のまま。上流に新しい版がある → 取り込み候補
#   両方変更         … 導入先に改変があり、上流も更新されている → 上流の変更だけを手で反映する
#   ローカルだけ変更 … 導入先に改変があり、上流は変わっていない → 対応不要
#   未導入           … 上流にだけある
#   同一             … 差分なし
# 導入先の改変の「元になった上流版」は、上流の歴代の版のうち行の差が最も小さいものを推定値とする。
# 比較の基準は dd-know-how のコミット済みの内容（HEAD）。作業ツリーの未コミット変更は使わない。
#
# 推定の限界: 上流が導入先の改変を取り込み、同じコミットでさらに手を加えると、導入先のファイルは
#   最新版に最も近くなり「ローカルだけ変更」と出る（差分の - 行が、導入先に無い上流の追加分）。
#   上流へ還元するときは、まず導入先の改変をそのまま1コミットで入れ、追加の変更は別コミットにする。
#   こうすると導入先は「上流だけ変更（導入先 = 還元コミットの版）」と正しく判定される。
#
# 改修時の注意: ループの中で外部コマンドを呼ばない（Windows + Git Bash は fork 1回が最大 約0.3秒）。
#   上流の履歴（git log）・歴代の版の中身（git cat-file --batch）・比較（awk）は全ファイル分を各1回で行う。
#   ファイル数に比例する fork は、差分表示の diff だけにとどめる。
#   変数の直後に全角文字が続くときは ${VAR} と書く（macOS の bash は全角の先頭バイトを変数名に含めうる）。
# =============================================================================
set -euo pipefail

KH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TARGET=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)  TARGET="${2:?--target にパスが必要}"; shift 2 ;;
        --dry-run) shift ;;   # v7 までのオプション。常に読み取り専用なので受け付けて無視する
        --adopt-content)
            {
                echo "ERROR: --adopt-content は廃止しました（v8）。dd-update はファイルを変更せず、差分を表示するだけです"
                echo "  オプションなしで実行し、レポートを見てファイルごとに取り込んでください"
            } >&2
            exit 2 ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done
if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
    echo "ERROR: --target <プロジェクトルート> を指定してください" >&2
    exit 2
fi
TARGET="$(cd "$TARGET" && pwd)"
if [ "$TARGET" = "$KH" ]; then
    echo "ERROR: dd-know-how 自身は比較対象にできません" >&2
    exit 2
fi
if ! git -C "$KH" rev-parse --verify -q HEAD >/dev/null; then
    echo "ERROR: dd-know-how が git 管理されていないため比較できません: $KH" >&2
    exit 2
fi

# cp の案内に使う dd-know-how のパス。Git Bash では C:/... 形式にして PowerShell でもそのまま通るようにする
KH_CP="$(cd "$KH" && pwd -W 2>/dev/null || echo "$KH")"
KH_HEAD="$(git -C "$KH" log -1 --format='%h %cs %s')"
H="${KH_HEAD%% *}"
KH_BRANCH="$(git -C "$KH" rev-parse --abbrev-ref HEAD)"

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

cd "$TARGET"

# .dd-config を安全に読む（source しない = 設定ファイル内の任意コード実行を防止）。
# KEY="value" / KEY=value 形式の行から、パスとして妥当な文字だけを1件抽出する。
dd_config_get() {  # dd_config_get KEY FILE
    [ -f "$2" ] || return 0
    sed -n "s|^[[:space:]]*${1}[[:space:]]*=[[:space:]]*\"\{0,1\}\([A-Za-z0-9 ._:/~-]*\)\"\{0,1\}[[:space:]]*\$|\1|p" "$2" 2>/dev/null | head -1
}

notes=()
if [ -f .dd-config ]; then
    DOC_DIR="$(dd_config_get DOC_DIR .dd-config)"
    TEMPLATES_DIR="$(dd_config_get TEMPLATES_DIR .dd-config)"
else
    DOC_DIR="doc"
    [ ! -d doc ] && [ -d docs ] && DOC_DIR="docs"
    TEMPLATES_DIR=""
    notes+=(".dd-config がありません（DOC_DIR=$DOC_DIR と推測して比較した。作るなら $KH_CP/templates/dd-config.example を参照）")
fi
DOC_DIR="${DOC_DIR:-doc}"

# --- テンプレートフォルダの検出（.dd-config の TEMPLATES_DIR が最優先） ---
TPL_DIR="${TEMPLATES_DIR:-}"
if [ -z "$TPL_DIR" ]; then
    for d in "$DOC_DIR/templates" doc/templates docs/templates templates; do
        if [ -f "$d/dd_template.md" ]; then TPL_DIR="$d"; break; fi
    done
fi

# --- 比べるファイルの組（導入先<TAB>上流）。導入済みの構成にだけ従う ---
pairs=()
for s in dd-index-gen.sh dd-health.sh doc-check.sh dd-update.sh; do
    pairs+=("scripts/$s"$'\t'"templates/scripts/$s")
done
if [ -f scripts/codex-review.sh ]; then
    pairs+=("scripts/codex-review.sh"$'\t'"templates/scripts/codex-review.sh")
fi
for hd in .claude/hooks .codex/hooks .agents/hooks; do
    [ -d "$hd" ] || continue
    pairs+=("$hd/post-bash-dd-archive-reminder.sh"$'\t'"templates/hooks/post-bash-dd-archive-reminder.sh")
    pairs+=("$hd/pre-edit-guard.sh"$'\t'"templates/hooks/pre-edit-guard.sh")
    if [ -f "$hd/post-edit-lint.mjs" ]; then
        pairs+=("$hd/post-edit-lint.mjs"$'\t'"templates/hooks/post-edit-lint.mjs")
    fi
done
# スキルは正本 .claude/skills/ が単一ソース（.agents/skills/ は Codex 用ミラー）
for sd in .claude/skills .agents/skills; do
    if [ -f "$sd/dd/SKILL.md" ]; then
        pairs+=("$sd/dd/SKILL.md"$'\t'".claude/skills/dd/SKILL.md")
    fi
done
if [ -n "$TPL_DIR" ]; then
    for t in dd_template.md dd_template_bugfix.md dd_template_tdd.md dd_template_mock.md \
             dd_template_e2e.md guides.md screen-spec-template.md coding-standards.md; do
        pairs+=("$TPL_DIR/$t"$'\t'"templates/$t")
    done
else
    notes+=("テンプレートフォルダが見つからず比較していません（.dd-config に TEMPLATES_DIR=\"doc/templates\" を書くと明示できる）")
fi
for m in da-method.md spec-sync-check.md; do
    if [ -f "$DOC_DIR/$m" ]; then
        pairs+=("$DOC_DIR/$m"$'\t'"doc/$m")
    fi
done

declare -A seen_src=()
srcs=()
{
    for p in "${pairs[@]}"; do
        dst="${p%%$'\t'*}"; src="${p#*$'\t'}"
        if [ -f "$dst" ]; then e=1; else e=0; fi
        printf '%s\t%s\t%s\n' "$dst" "$src" "$e"
        if [ -z "${seen_src[$src]:-}" ]; then seen_src[$src]=1; srcs+=("$src"); fi
    done
} > "$T/pairs"
printf '%s\n' "${srcs[@]}" > "$T/srcs"

# --- 上流のデータを集める（全ファイル分を各1回の git 呼び出しで） ---
git -C "$KH" -c core.quotepath=false ls-tree HEAD -- "${srcs[@]}" > "$T/heads"
git -C "$KH" -c core.quotepath=false log -M --raw --no-abbrev --format='C%x09%H%x09%cs%x09%s' HEAD > "$T/log"
declare -A kh_dirty=()
while IFS= read -r l; do
    if [ -n "$l" ]; then kh_dirty["${l:3}"]=1; fi
done < <(git -C "$KH" -c core.quotepath=false status --porcelain -- "${srcs[@]}")

# 歴代の版（新しい順）: 論理ファイル<TAB>blob<TAB>コミット<TAB>日付<TAB>件名。リネームは旧パスへさかのぼって追う
: > "$T/blobs"
LC_ALL=C awk -F'\t' -v blobs="$T/blobs" '
    FILENAME == ARGV[1] { alias[$0] = $0; next }
    /^C\t/ { h = substr($2, 1, 7); d = $3; s = $4; next }
    /^:/ {
        split($1, f, " "); st = substr(f[5], 1, 1); nb = f[4]
        np = (st == "R" || st == "C") ? $3 : $2
        if (!(np in alias)) next
        L = alias[np]
        if (st != "D" && !((L, nb) in seen)) {
            seen[L, nb] = 1
            print L "\t" nb "\t" h "\t" d "\t" s
            if (!(nb in listed)) { listed[nb] = 1; print nb > blobs }
        }
        if (st == "R") alias[$2] = L
    }
' "$T/srcs" "$T/log" > "$T/versions"
git -C "$KH" cat-file --batch < "$T/blobs" > "$T/contents"

# --- 分類（改行コードを無視。結果は1行1件、diff 表示用の中身は $T/<番号>.* に書き出す） ---
LC_ALL=C awk -F'\t' -v T="$T" '
function same(b, n,    i) {
    if (!(b in cnt) || cnt[b] != n) return 0
    for (i = 1; i <= n; i++) if (ln[b, i] != loc[i]) return 0
    return 1
}
function dist(b, n,    i, c, x, d) {   # 行の多重集合の差（並べ替えは数えない、diff 行数の近似）
    split("", c)
    for (i = 1; i <= n; i++) c[loc[i]]++
    for (i = 1; i <= cnt[b]; i++) c[ln[b, i]]--
    d = 0
    for (x in c) d += (c[x] < 0) ? -c[x] : c[x]
    return d
}
function newer(L, upto,    i, s) {     # 版 upto より新しい上流コミット（新しい順、\037 区切り）
    s = ""
    for (i = 1; i < upto; i++) s = s (i > 1 ? "\037" : "") vh[L, i] " " vd[L, i] " " vs[L, i]
    return s
}
function dump(b, file,    i) {
    printf "" > file
    for (i = 1; i <= cnt[b]; i++) print ln[b, i] > file
    close(file)
}
function dumploc(n, file,    i) {
    printf "" > file
    for (i = 1; i <= n; i++) print loc[i] > file
    close(file)
}
function classify(dst, src, ex,    hb, n, line, i, key, bi, bd, d) {
    hb = head[src]
    if (hb == "") { print "NOHEAD\t" dst "\t" src; return }
    if (ex == 0) { print "MISSING\t" dst "\t" src; return }
    n = 0; key = src
    while ((getline line < dst) > 0) { sub(/\r$/, "", line); loc[++n] = line; key = key "\n" line }
    close(dst)
    if (key in firstdst) { print "DUP\t" dst "\t" firstdst[key]; return }   # .claude と .agents の複製など
    firstdst[key] = dst
    if (same(hb, n)) { print "SAME\t" dst; return }
    if (nv[src] == 0) { nv[src] = 1; vb[src, 1] = hb; vh[src, 1] = "HEAD"; vd[src, 1] = "-"; vs[src, 1] = "" }
    for (i = 1; i <= nv[src]; i++) {
        if (vb[src, i] == hb || !same(vb[src, i], n)) continue
        k++; dumploc(n, T "/" k ".local"); dump(hb, T "/" k ".head")
        print "UP\t" dst "\t" src "\t" k "\t" vh[src, i] "\t" vd[src, i] "\t" newer(src, i)
        return
    }
    bi = 0; bd = -1
    for (i = 1; i <= nv[src]; i++) { d = dist(vb[src, i], n); if (bd < 0 || d < bd) { bd = d; bi = i } }
    k++; dumploc(n, T "/" k ".local"); dump(hb, T "/" k ".head")
    if (vb[src, bi] == hb) { print "LOCAL\t" dst "\t" src "\t" k "\t" bd; return }
    dump(vb[src, bi], T "/" k ".base")
    print "BOTH\t" dst "\t" src "\t" k "\t" vh[src, bi] "\t" vd[src, bi] "\t" bd "\t" n "\t" newer(src, bi)
}
BEGIN { mode = "hdr"; k = 0 }
FILENAME == ARGV[1] { split($1, a, " "); head[$2] = a[3]; next }
FILENAME == ARGV[2] { n = ++nv[$1]; vb[$1, n] = $2; vh[$1, n] = $3; vd[$1, n] = $4; vs[$1, n] = $5; next }
FILENAME == ARGV[3] {
    # git cat-file --batch の出力: "<sha> <type> <size>" の行 → 中身 size バイト → 区切りの改行
    if (mode == "hdr") {
        split($0, hd, " "); cur = hd[1]; rem = hd[3] + 0; cnt[cur] = 0
        mode = (hd[2] == "missing") ? "hdr" : (rem == 0 ? "sep" : "body"); next
    }
    if (mode == "sep") { mode = "hdr"; next }
    cnt[cur]++; ln[cur, cnt[cur]] = $0
    if (length($0) + 1 <= rem) { rem -= length($0) + 1; if (rem == 0) mode = "sep" }
    else { rem = 0; mode = "hdr" }   # 末尾に改行の無い最終行（区切りの改行で終わっている）
    next
}
{ classify($1, $2, $3) }
' "$T/heads" "$T/versions" "$T/contents" "$T/pairs" > "$T/plan"

# --- 結果を分類ごとにまとめる ---
declare -A cat_of=() dups_of=()
n_up=(); n_both=(); n_local=(); n_missing=(); n_same=(); n_nohead=()
r_up=(); r_both=(); r_local=(); r_missing=()
add_name() {  # add_name 分類 表示名
    case "$1" in
        UP) n_up+=("$2") ;;           BOTH) n_both+=("$2") ;;   LOCAL) n_local+=("$2") ;;
        MISSING) n_missing+=("$2") ;; SAME) n_same+=("$2") ;;   NOHEAD) n_nohead+=("$2") ;;
    esac
}
while IFS= read -r rec; do
    tag="${rec%%$'\t'*}"; rest="${rec#*$'\t'}"; dst="${rest%%$'\t'*}"
    if [ "$tag" = DUP ]; then
        first="${rest#*$'\t'}"
        dups_of[$first]="${dups_of[$first]:-}$dst"$'\n'
        add_name "${cat_of[$first]:-SAME}" "${dst}（$first と同じ内容）"
        continue
    fi
    cat_of[$dst]="$tag"
    add_name "$tag" "$dst"
    case "$tag" in
        UP) r_up+=("$rec") ;;   BOTH) r_both+=("$rec") ;;   LOCAL) r_local+=("$rec") ;;   MISSING) r_missing+=("$rec") ;;
    esac
done < "$T/plan"

show_diff() {  # show_diff 比較元 比較先 比較元ラベル 比較先ラベル
    # 囲みは4連: テンプレート内の ``` が diff の文脈行（先頭1スペース）に出ても囲みを閉じない
    echo '````diff'
    diff -u --label "$3" --label "$4" "$1" "$2" || true
    echo '````'
}
print_commits() {  # print_commits "<コミット 日付 件名>\037..."
    local -a cs=()
    local c
    IFS=$'\037' read -ra cs <<< "$1"
    for c in ${cs[@]+"${cs[@]}"}; do echo "    - $c"; done
    return 0
}
dup_note() {  # dup_note 導入先パス — 同じ内容の複製があれば知らせる
    local d
    while IFS= read -r d; do
        if [ -n "$d" ]; then echo "- 同じ内容のファイル: ${d}（取り込むなら同じように反映する）"; fi
    done <<< "${dups_of[$1]:-}"
    return 0
}
cp_lines() {  # cp_lines 上流パス 導入先パス — 同じ内容の複製にも同じ案内を出す
    local d
    if [ -n "${kh_dirty[$1]:-}" ]; then
        echo "- ⚠️ dd-know-how 側でこのファイルに未コミットの変更があるため、取り込みコマンドは出しません（cp は作業中の内容を写すため）。コミットしてから再実行してください"
        return 0
    fi
    while IFS= read -r d; do
        if [ -n "$d" ]; then echo "- 取り込む: cp \"$KH_CP/$1\" \"$d\""; fi
    done <<< "$2"$'\n'"${dups_of[$2]:-}"
    return 0
}
list_names() {  # list_names 見出し 表示名...
    local title="$1" x
    shift
    echo "- $title: $#件"
    for x in "$@"; do echo "    - $x"; done
    return 0
}

# --- レポート ---
echo "# DD配布物の差分レポート: $TARGET"
echo "- 上流: ${KH}（${KH_HEAD}）"
echo "- このスクリプトはファイルを一切変更しません。改行コードの違いは無視し、上流はコミット済みの内容（HEAD）と比べます"
if [ "$KH_BRANCH" != "main" ] && [ "$KH_BRANCH" != "master" ]; then
    echo "  ⚠️ dd-know-how が main 以外のブランチ（${KH_BRANCH}）です。配布の基準として正しいか確認してください"
fi
if [ ${#kh_dirty[@]} -gt 0 ]; then
    echo "  ⚠️ dd-know-how の作業ツリーに未コミットの変更があります（比較には使っていません）: ${!kh_dirty[*]}"
fi
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "- 導入先ブランチ: $(git rev-parse --abbrev-ref HEAD)"
    if [ -n "$(git status --porcelain --untracked-files=no 2>/dev/null)" ]; then
        echo "  ℹ️ 導入先に未コミットの変更があります。取り込む前にコミットしておくと、取り込んだ分だけを git diff で確認できます"
    fi
else
    echo "- 導入先は git 管理外です（取り込み後に git diff で確認できないため注意）"
fi

echo ""
echo "## 一覧（比べたファイル: $(( ${#n_up[@]} + ${#n_both[@]} + ${#n_local[@]} + ${#n_missing[@]} + ${#n_same[@]} + ${#n_nohead[@]} ))件）"
list_names "上流だけ変更（取り込み候補）" ${n_up[@]+"${n_up[@]}"}
list_names "両方変更（上流の変更だけを手で反映）" ${n_both[@]+"${n_both[@]}"}
list_names "ローカルだけ変更（対応不要）" ${n_local[@]+"${n_local[@]}"}
list_names "未導入（上流にだけある）" ${n_missing[@]+"${n_missing[@]}"}
list_names "同一" ${n_same[@]+"${n_same[@]}"}
if [ ${#n_nohead[@]} -gt 0 ]; then
    list_names "⚠️ 上流でまだコミットされていないため比べられない" "${n_nohead[@]}"
fi

if [ ${#r_up[@]} -gt 0 ]; then
    echo ""
    echo "## 上流だけ変更 — 導入先は過去の配布版のまま（取り込み候補。コマンドは導入先のルートで実行）"
    for rec in "${r_up[@]}"; do
        IFS=$'\t' read -r _ dst src k vh vd newer <<< "$rec"
        echo ""
        echo "### $dst"
        echo "- 導入先 = 上流 ${vh}（${vd}）の版。その後の上流の変更:"
        print_commits "$newer"
        cp_lines "$src" "$dst"
        show_diff "$T/$k.local" "$T/$k.head" "local/$dst" "upstream@$H/$src"
    done
fi

if [ ${#r_both[@]} -gt 0 ]; then
    echo ""
    echo "## 両方変更 — 導入先に改変あり＋上流も更新（導入先の改変を残したまま、上流の変更だけを手で反映する）"
    for rec in "${r_both[@]}"; do
        IFS=$'\t' read -r _ dst src k bh bdate bd n newer <<< "$rec"
        echo ""
        echo "### $dst"
        dup_note "$dst"
        echo "- 元になった上流版（推定）: ${bh}（${bdate}）。そこからの導入先の改変は約 ${bd} 行"
        if [ $((bd * 2)) -gt "$n" ]; then
            echo "  ⚠️ 改変が全体の半分を超えるため、元になった版の推定は当てになりません"
        fi
        echo "- その後の上流の変更:"
        print_commits "$newer"
        echo ""
        echo "反映すべき上流の変更（$bh → ${H}）:"
        show_diff "$T/$k.base" "$T/$k.head" "upstream@$bh/$src" "upstream@$H/$src"
        echo ""
        echo "残すべき導入先の改変（$bh → 現在のファイル）:"
        show_diff "$T/$k.base" "$T/$k.local" "upstream@$bh/$src" "local/$dst"
    done
fi

if [ ${#r_local[@]} -gt 0 ]; then
    echo ""
    echo "## ローカルだけ変更 — 上流は変わっていない（取り込むものはない。導入先の改変の確認用）"
    for rec in "${r_local[@]}"; do
        IFS=$'\t' read -r _ dst src k bd <<< "$rec"
        echo ""
        echo "### $dst"
        dup_note "$dst"
        echo "- 上流 $H の版からの改変 約 ${bd} 行（上流でも役立つ修正なら、dd-know-how への還元を検討する）"
        show_diff "$T/$k.head" "$T/$k.local" "upstream@$H/$src" "local/$dst"
    done
fi

if [ ${#r_missing[@]} -gt 0 ]; then
    echo ""
    echo "## 未導入 — 上流にだけある（必要なものだけ取り込む。フックは settings への登録も必要。コマンドは導入先のルートで実行）"
    for rec in "${r_missing[@]}"; do
        IFS=$'\t' read -r _ dst src <<< "$rec"
        echo ""
        echo "### $dst"
        cp_lines "$src" "$dst"
    done
fi

if [ -f .dd-manifest ]; then
    notes+=(".dd-manifest は v8 から使っていません（残っていれば削除してかまいません）")
fi
if [ ${#notes[@]} -gt 0 ]; then
    echo ""
    echo "## 補足"
    for x in "${notes[@]}"; do echo "- $x"; done
fi

echo ""
if [ $(( ${#r_up[@]} + ${#r_both[@]} + ${#r_missing[@]} )) -eq 0 ]; then
    echo "取り込むものはありません（このスクリプトはファイルを変更していません）"
else
    echo "## 次にやること（このスクリプトはファイルを変更していません）"
    echo "取り込みはファイルごとに判断する。安定して動いているなら、理由（セキュリティ修正・このリポジトリで起きているバグ・欲しい機能）がない限り取り込まなくてよい:"
    echo "  1. 「上流だけ変更」「未導入」から必要なものを選び、表示の cp で取り込む"
    echo "  2. 「両方変更」は、導入先の改変を残したまま、上流の変更だけを手で反映する"
    echo "  3. git diff で確認してからコミットする（stage は対象ファイルを明示）。dd-index-gen.sh を取り込んだら bash scripts/dd-index-gen.sh で DD-INDEX を再生成する"
    echo "  4. スキル・フックの変更は、エージェント（Claude Code / Codex）の再起動後に有効になる"
fi
