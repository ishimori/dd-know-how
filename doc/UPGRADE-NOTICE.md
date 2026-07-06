# DD-Know-How アップグレード通知

> 💡 **使い方**: 導入先プロジェクトで作業中の Claude/Codex に、**このファイルの絶対パスと対象バージョンを添えて**依頼するとそのまま実行できる。別リポジトリからは相対参照だと場所を特定できないため、絶対パスが確実:
>
> ```
> c:\repo\dd-know-how の doc/UPGRADE-NOTICE.md の v4 手順で更新して
> ```
>
> 呼び出し口（`scripts/dd-update.sh`）が入る2回目以降は、各プロジェクトで `bash scripts/dd-update.sh`（または「DDスキルを更新して」）だけで済む。本手順書が要るのは初回のみ。

## v4: ステータス固定語彙+補足列 / .dd-config パス基盤（2026-07-06）

### 概要

2つの構造問題への対応:

1. **ステータス自由記述の限界**: ヘッダ表のステータス列に補足説明が混入し（例:「実装完了（Phase 0-2 完了・…未コミット）」）、KANBANビューア・DD-INDEX・ヘルスチェックの機械判定が不安定だった。→ **ステータスを固定6種に、説明は新設の補足列（4列目）へ**
2. **導入先でのパスずれ再発**: パス設定がスクリプト本体への直書きだったため、(a) カレントディレクトリ依存で「DD directory not found」が頻発、(b) スクリプトを上書き更新するたび設定が消えていた。→ **設定をルート直下 `.dd-config` に分離し、スクリプトは自己位置からルートを解決（CWD非依存）**

### 主な変更点

- **ヘッダ表が4列に**: `| 作成日 | 更新日 | ステータス | 補足 |`（新規DDから適用。既存DDの3列も全ツールがそのまま読める）
- **ステータス固定語彙6種**: `検討中` `進行中` `確認待ち` `保留` `見送り` `完了`（詳細: `templates/guides.md` §3）。終端（完了・見送り）になったらアーカイブする
- **`.dd-config` 新設**（ルート直下）: `DD_DIR` / `ARCHIVE_DIR` / `DOC_DIR` の単一ソース。スクリプト・フックはこれを読む
- **全スクリプトがCWD非依存に**: どのディレクトリから実行してもよい
- `dd-index-gen.sh`: 「保留・見送り」セクションを自動生成（従来は常に空）。「主な成果」は補足列を優先。**アーカイブ判定が `archived/` 固定だったバグを修正**（`doc/DD/archive/` 等の配置でアーカイブ済みDDが「進行中」に混入していた）
- `dd-health.sh`: ステータス語彙lint追加（固定6種以外を⚠️検出）。`見送り` のままアクティブに残るDDもクローズ漏れ扱いに
- アーカイブリマインダーフック: `archive/` 配置でも発火するよう修正（従来は `archived/` のみ）
- **Pull型更新（`dd-update.sh`）新設**: 次回以降の更新は各プロジェクト側から `bash scripts/dd-update.sh` 一発で取り込める（本手順のステップ3で呼び出し口が入る。本v4だけは手動取り込みが必要）

### 配布物マップ（上書き可否 — 以後のアップグレード共通）

| dd-know-how ソース | 導入先の配置 | 更新方針 |
|---|---|---|
| `templates/scripts/*.sh` | `scripts/` | **常に上書きOK**（プロジェクト固有設定を含まない） |
| `templates/hooks/*.sh` `*.mjs` | `.claude/hooks/`（`.agents/hooks/`） | **上書きOK**（末尾にプロジェクト固有ルールを追記していた場合のみ再適用） |
| `templates/dd-config.example` | ルート `.dd-config` | **初回のみ生成・以後上書き禁止**（プロジェクト固有の生存領域） |
| `.claude/skills/dd/SKILL.md` | `.claude/skills/dd/` | 上書き後、旧版とdiffしてプロジェクト固有調整（パス等）を再適用 |
| `templates/dd_template*.md` `guides.md` | `{テンプレートフォルダ}/` | 上書きOK（独自カスタムがあればマージ） |
| `templates/CLAUDE.md.snippet` | `CLAUDE.md` | 追記マージのみ（上書き禁止） |
| `doc/da-method.md` 等の方法論文書 | `doc/` | 上書きOK |

> 更新ロジック本体（`tools/dd-update-core.sh`）は dd-know-how 側に常駐し配布されない。各プロジェクトの `scripts/dd-update.sh`（呼び出し口）が exec するため、常に最新のロジックが使われる。

### アップグレード手順（導入先プロジェクトのルートで実行）

以下 `{KH}` = dd-know-how リポジトリのパス。事前に `{KH}` で `git pull` して最新化しておく。

**1. 実レイアウトの確認**

DDフォルダとアーカイブの実パスを確認する（プロジェクトにより `doc/DD` + `doc/archived/DD` / `doc/DD/archive` / `docs/DD` 等の揺れがある）:

```bash
ls -d doc/DD docs/DD doc/archived/DD doc/DD/archive 2>/dev/null
```

**2. `.dd-config` を作成**（既にあればスキップ）

```bash
cp {KH}/templates/dd-config.example .dd-config
# エディタで DD_DIR / ARCHIVE_DIR / DOC_DIR をステップ1の実パスに合わせる
```

**3. スクリプトを上書きコピー**

```bash
cp {KH}/templates/scripts/dd-index-gen.sh {KH}/templates/scripts/dd-health.sh \
   {KH}/templates/scripts/doc-check.sh {KH}/templates/scripts/dd-update.sh scripts/
# codex-review.sh を使っているプロジェクトのみ:
cp {KH}/templates/scripts/codex-review.sh scripts/
```

**4. フックを上書きコピー**

```bash
cp {KH}/templates/hooks/post-bash-dd-archive-reminder.sh .claude/hooks/
cp {KH}/templates/hooks/pre-edit-guard.sh .claude/hooks/   # 固有ルールを追記していた場合は末尾を再適用
```

**5. スキルを更新**

```bash
cp {KH}/.claude/skills/dd/SKILL.md .claude/skills/dd/SKILL.md
```

上書き後、旧版とのdiffを見てプロジェクト固有のパス調整があれば再適用する。

**6. テンプレートを更新**

```bash
cp {KH}/templates/dd_template.md {KH}/templates/dd_template_tdd.md {KH}/templates/dd_template_e2e.md {KH}/templates/guides.md {テンプレートフォルダ}/
```

（`dd_template_bugfix.md` / `dd_template_mock.md` は今回変更なし。guides.md の節番号が変わったため tdd / e2e も同時更新が必要）

**7. CLAUDE.md の「DD設定」に2行追記**

```markdown
- **パス設定**: ルート直下の `.dd-config`（スクリプト・フックはここを読む。上の実パスと常に一致させる）
- **ステータス**: 固定6種（検討中/進行中/確認待ち/保留/見送り/完了）+ 補足列。語彙ルール: {テンプレートフォルダ}/guides.md §3
```

**8. 🔬 検証（必須）**

```bash
cd {適当なサブフォルダ} && bash ../scripts/dd-health.sh   # ← サブフォルダからでもエラーなく動くこと
bash scripts/dd-index-gen.sh                               # DD-INDEX.md 再生成
git diff --stat                                            # INDEX の変化を確認
```

INDEX の想定される変化: 進行中セクションが4列化 / 「保留・見送り」に該当DDが自動掲載 / `doc/DD/archive` 等の配置ではアーカイブ済みDDが「進行中」から「完了済み」へ移動（従来のバグ修正）。

**9. TS移植版（dd-index-gen.ts）を使っているプロジェクトのみ**

`{KH}/templates/scripts/README.md` の参考実装で `scripts/dd-index-gen.ts` を全面差し替えする（旧版には4列表で補足をステータスと誤読するバグがある）。

**10. 以後の更新について**

本手順のステップ3で `scripts/dd-update.sh`（Pull型更新の呼び出し口）が入った。**次回からは対象プロジェクトでこれを実行するだけ**でよい（本手順書のような手動コピーは不要になる）:

```bash
bash scripts/dd-update.sh --dry-run   # 更新内容の事前確認
bash scripts/dd-update.sh             # 取り込み（コミットはされない → diff を見て自分でコミット）
```

dd-know-how の場所は既定で兄弟ディレクトリ `../dd-know-how`。別の場所にある場合は `.dd-config` に `SOURCE_REPO="C:/repo/dd-know-how"` を追記する。

### Codex（.agents 構成）の場合の差分

- スキル: `{KH}/.agents/skills/dd/SKILL.md` → `.agents/skills/dd/SKILL.md`
- フック: `.agents/hooks/` へコピー
- 追記先: CLAUDE.md ではなく AGENTS.md（内容は同じ2行）
- スクリプトは `dd-index-gen.sh` のみが標準構成

### 既存DDへの影響

- **新規DD**: 更新後のテンプレートで自動的に4列+固定語彙になる（`/dd new` のセルフチェックが語彙外を検出して矯正）
- **進行中のDD**: そのまま動く（全ツールが3列/4列両対応）。**次にそのDDを触るタイミング**でヘッダ表を4列+固定語彙に書き換えると、KANBAN・INDEXがすぐ安定する
- **アーカイブ済みDD**: 変更不要（遡及しない）。「主な成果」は従来どおりステータス欄の文言が使われ続ける
- `dd-health.sh` に既存アクティブDDの「🏷️ 語彙外ステータス」警告が並ぶのは**想定内**。漸進的に解消すればよい（`--strict` をCIに入れている場合は移行完了までの間は注意）

### トラブルシュート

| 症状 | 原因と対処 |
|------|-----------|
| `ERROR: DDフォルダが見つかりません` | `.dd-config` 未作成またはパス誤り。エラーメッセージ内の例に従いルート直下に作成する |
| アーカイブ済みDDが「進行中」に出る | `.dd-config` の `ARCHIVE_DIR` が実配置と不一致（例: `doc/DD/archive` なのに既定値のまま） |
| KANBANで「ステータス不明」に入る | ステータスが固定6種の語彙外。`bash scripts/dd-health.sh` の語彙テーブルで一覧確認 |
| 更新後もスクリプトが旧挙動 | コピー漏れ。`grep -l "dd-config" scripts/*.sh` で新版か確認できる |

---

## v3: 実装前詳細化（2段階方式）導入（2026-05-03）

### 概要

「DDで計画を立てて合意を取る」の後、いざ実装に入ると詳細設計不足でいきあたりばったりになる問題への対応。
計画段階で詳細設計までやるのはやりすぎなので、**計画フェーズと実装直前の詳細化フェーズを分離**する2段階方式を導入しました。

### 主な変更点

#### 標準テンプレート（`dd_template.md`）に2段階方式を組み込み

**Phase 0 に「📐 実装前詳細化トリガー判定」を追加**

各Phaseに対して、以下のシグナルで詳細化要/不要を判定:

- **規模シグナル**（いずれか該当で詳細化必須）
  - 3ファイル以上の変更
  - 新規モジュール・新規エンドポイント追加
  - 外部I/F（API/スキーマ/公開関数シグネチャ）変更あり
- **複雑度シグナル**（いずれか該当で詳細化必須）
  - 既存の条件分岐・状態遷移を変更
  - 並行処理・トランザクション境界・ロックに触れる
  - データ移行・スキーマ変更を伴う
  - パフォーマンス特性が変わりうる
  - セキュリティ境界に触れる
  - 同じ関数を3箇所以上から呼んでいるものの内部仕様を変える

判定結果（`Phase N → 詳細化要/不要`）をDD本文に明記する。

**各実装Phase の冒頭に「📐 実装前詳細化」タスクを追加（該当Phaseのみ）**

詳細化要と判定されたPhaseでは、コーディング前に以下を箇条書きで詳細化し、ユーザーレビューを通す:

- 触るファイル/関数の特定
- 関数シグネチャと責務
- データフロー
- エッジケース・エラーハンドリング方針
- テスト観点

### アップグレード手順

**1ファイルだけ差し替えれば反映されます:**

```
dd-know-how/templates/dd_template.md
  → {プロジェクト}/{テンプレートフォルダ}/dd_template.md（上書き）
```

**差分テンプレート4種（`dd_template_bugfix.md` / `dd_template_e2e.md` / `dd_template_mock.md` / `dd_template_tdd.md`）は更新不要です。** 理由:

- e2e/mock/tdd は標準のPhase 0に「追加」する形で定義されており、標準テンプレを差し替えれば判定タスクは自動的に継承される
- bugfix は独自の「フルパス/ライトパス分岐」で同等の規模/複雑度判定をすでに持っているため、二重化を避ける

### 既存DDへの影響

- **進行中のDD**: そのまま使えます。次のDDから判定タスクが入ります
- **新規DD**: 更新後のテンプレートで自動的に2段階方式になります
- **アーカイブ済みDD**: 変更不要

---

## v2: DDスキル分割 + DA批判レビュー導入（2026-02-07）

### 概要

DDスキルの構造とレビュー手法を大幅に改善しました。
既にDD-Know-Howを導入済みのプロジェクトは、以下の手順でアップグレードできます。

### 主な変更点

#### 1. DDスキルの分割（コンテキスト効率改善）

**変更前:** `/dd` スキル1つに全機能（428行）
**変更後:** 2つのスキルに分離

| スキル | 行数 | 内容 |
|--------|------|------|
| `/dd` | ~180行 | DD操作（参照・作成・一覧・検索・アーカイブ） |
| `doc/da-method.md` | — | DA品質フィルター・再チェック条件・Phase種別チェックリスト |

**メリット:** DD参照だけの時にワークフロー全体がロードされなくなり、コンテキスト消費を削減。

#### 2. DA批判レビュー（Devil's Advocate）の導入

**変更前:** 「見落としチェック」— 「何を見落としているか？」を問う
**変更後:** 「DA批判レビュー」— **「どこが壊れるか？」を問う**

具体的な改善:
- **4段階の批判手順**: 壊れる前提で探す → 暗黙の前提を疑う → 将来の破壊を予測 → 記録
- **DA観点チェックリスト**: 矛盾・不整合、エッジケース、依存関係等の6項目
- **条件A（新規）**: 重要度「中」以上が1件でもあれば別角度で再チェック必須
- **記録テンプレート改善**: DA観点カラム、発動理由、切り替え視点の記録

#### 3. DDスキルの改善

- **添付ファイル配置ルール**: `DD-{番号}/` フォルダへの統一ルール
- **アーカイブ時チェックリスト**: 移動漏れ防止の必須チェック
- **DD分割の提案**: 100行超見込みで自動提案

---

### アップグレード手順

#### Level 2（/dd + DA メソッド）をお使いの場合

**1. スキルファイルを更新**

以下のファイルをdd-know-howリポジトリからコピー:

```
dd-know-how/.claude/skills/dd/SKILL.md
  → {プロジェクト}/.claude/skills/dd/SKILL.md（上書き）

dd-know-how/doc/da-method.md
  → {プロジェクト}/doc/da-method.md（新規）
```

**2. テンプレートを更新**

```
dd-know-how/templates/dd_template.md
  → {プロジェクト}/{テンプレートフォルダ}/dd_template.md（上書き）
```

**3. CLAUDE.mdにDA メソッド参照を追記**

```markdown
- DA メソッド: `doc/da-method.md`（DA品質フィルター・再チェック条件）
```

---

### 既存DDへの影響

- **進行中のDD**: そのまま使えます。見落としチェック形式でも問題なく動作します
- **新規DD**: 更新後のテンプレートでDA批判レビュー形式になります
- **アーカイブ済みDD**: 変更不要です

### 用語の対応表

| 旧用語 | 新用語 |
|--------|--------|
| 見落としチェック | DA批判レビュー |
| 🔍 見落としチェック（最低1件発見） | 😈 DA批判レビュー（「このPhaseで何が壊れるか」を最低1件発見） |
| 見落としチェック記録 | DA批判レビュー記録 |
| 見落とし発見モード | DA批判レビュー（Devil's Advocate視点） |
