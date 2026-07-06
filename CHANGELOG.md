# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- **Pull型更新（`dd-update.sh`）**: 各プロジェクト側から `bash scripts/dd-update.sh` 一発で dd-know-how の最新配布物（scripts / hooks / スキル / テンプレート / 方法論文書）を取り込む
  - 呼び出し口スタブだけを各プロジェクトに配布し、本体（`tools/dd-update-core.sh`）は dd-know-how 側に常駐 — スタブが exec するため更新ロジック自体の配り直しが不要
  - dd-know-how の場所は既定で兄弟ディレクトリ `../dd-know-how`（`.dd-config` の `SOURCE_REPO` で変更可）。テンプレートフォルダは実在検出（`TEMPLATES_DIR` で明示も可）
  - `.dd-config`・CLAUDE.md・DOC-MAP.md・DD-INDEX.md・engineering-patterns.md・decisions.md 等のプロジェクト固有ファイルは不可侵（`.dd-config` は無い場合の自動生成のみ）
  - 対象が main 以外のブランチ/未コミット変更ありの場合は警告。差分のあるファイルだけコピーし件数報告。**コミットは行わない**（diff確認と判断は人間/LLM側）
  - `/dd update`（「DDスキルを更新して」）としてスキルにも配線
- **ステータス固定語彙 + 補足列**（ヘッダ表4列化: 作成日/更新日/ステータス/補足）
  - ステータスは固定6種のみ: 検討中/進行中/確認待ち/保留/見送り/完了（語彙ルール: `templates/guides.md` §3 新設）
  - 補足列に説明・成果を分離（完了時の成果要約は DD-INDEX「主な成果」へ転載）。外部ビューアのKANBAN分類・INDEX自動分類・ヘルスチェックの機械判定を安定させる
  - `dd_template.md` を4列化（初期値「検討中」）。dd/setup SKILL に語彙運用を組み込み（アーカイブ時チェックリストに「ステータス=完了/見送り・補足に成果1行」を追加）
  - `dd-health.sh` にステータス語彙lint（固定6種以外を⚠️検出。`/dd new` のセルフチェックで作成時に自動矯正）
- **`.dd-config` パス設定基盤**（導入先での「パスが違う」再発防止）
  - パス設定（DD_DIR / ARCHIVE_DIR / DOC_DIR）をルート直下 `.dd-config` に一元化（`templates/dd-config.example` 新設）
  - 全スクリプト（dd-index-gen / dd-health / doc-check / codex-review）とアーカイブリマインダーフックが、自己位置からプロジェクトルートを解決して `.dd-config` を読む方式に（**CWD非依存** + スクリプト上書き更新で設定が消えない）
  - エラーメッセージを自己修復型に（`.dd-config` の作成例を提示）。`.dd-config` なしでは `docs/DD` 配置も自動検出
- `templates/AGENTS.md.snippet` を新設（.agents 版 setup が参照していたが実体が無かった）
- `doc/UPGRADE-NOTICE.md` に v4 エントリ（導入済みプロジェクト向け取り込み手順書 + 配布物マップ〔上書き可否〕）
- 標準テンプレート（`dd_template.md`）に「実装前詳細化」2段階方式を導入
  - Phase 0 に「📐 実装前詳細化トリガー判定」を追加（規模3シグナル + 複雑度6シグナル）
  - 各実装Phase の冒頭に「📐 実装前詳細化」タスク（該当Phaseのみ）を追加し、人間レビューゲートを設置
  - 計画段階での過剰設計を避けつつ、実装直前に必要な詳細化を強制する仕組み
  - 差分テンプレート4種（bugfix/e2e/mock/tdd）は変更不要（標準のPhase 0を継承するため。bugfixは独自にフルパス/ライトパス分岐で同等の判定を持つ）
- バグ修正差分テンプレート（`dd_template_bugfix.md`）を新規追加
  - フルパス/ライトパスの2パス分岐（規模に応じた適用）
  - エビデンス手段の選択ガイド（画面キャプチャ/数値比較テーブル/テスト出力）
  - 添付ドキュメントテンプレート（cause-analysis.md / bug-report.md / verification.md）
- アプローチ選択を5つに拡張（バグ修正を優先順1位として追加）
- DA批判レビュー（Devil's Advocate視点）を導入
  - 「確認したか？」→ **「どこが壊れるか？」** への概念転換
  - 4段階の批判手順（壊れる前提で探す→暗黙の前提を疑う→将来の破壊を予測→記録）
  - DA観点チェックリスト（6項目: 矛盾、前提条件、エッジケース、正常系偏重、依存関係、将来の変更）
  - **条件A（新規）**: 重要度「中」以上が1件でも → 別角度で再チェック必須
  - 条件B（従来）: 多数発見時の再チェック
  - 記録テンプレート改善（DA観点カラム、発動理由、切り替え視点）
- DDスキルに添付ファイル配置ルール・アーカイブ時チェックリスト・DD分割提案を追加
- アップグレード通知テキスト（`doc/UPGRADE-NOTICE.md`）を追加
- 実例集に「バグ修正DD（DA批判レビュー記録付き）」を追加
  - DA批判レビューの実践例を含む
  - 各Phaseで問題を発見・対応した記録
- Phase 0に「Devil's Advocate調査」タスクを追加
  - 批判的視点での事前調査を促す
  - 代替案・リスク・失敗シナリオ・保守性を検討

### Changed
- `templates/scripts/dd-index-gen.sh`: 「保留・見送り」セクションを自動生成（ステータス 保留/見送り を検出。従来は「自動検出不可」として常に空）。進行中セクションに補足列を追加。「主な成果」は補足列を優先し、無ければステータス欄（旧運用互換）。TS参考実装（`templates/scripts/README.md`）も同仕様に全面更新
- `templates/scripts/dd-health.sh`: 「見送り」のままアクティブなDDもクローズ漏れ扱いに。ステータス語彙テーブルをアクティブDD限定 + 固定6種判定列付きに変更
- `/setup` スキル: パス調整ステップを `.dd-config` 生成方式に変更（**scripts/・hooks/ 内のパス直書きを禁止**）。パス整合性チェックに `.dd-config` 検証と `dd-index-gen.sh` 実行テストを追加
- `templates/guides.md`: §3「ステータスと補足列（固定語彙）」を挿入し旧§3以降を+1リナンバー（tdd/e2e テンプレの「§7」参照を「§8」へ追随）。フォルダ構成例をスクリプト既定値（`doc/archived/DD`）と一致させ、実配置は `.dd-config` が正であることを明記
- `templates/scripts/dd-index-gen.sh`: 完了済みセクションの「主な成果」列にステータス欄を表示するよう変更（従来は `read` で status を捨て `printf` で空をハードコードしていたため常に空欄だった。完了時ステータスに成果要約を書く運用と組み合わせる）
- 見落としチェック → DA批判レビューに名称・概念を変更
  - テンプレート、実例、開発フロードキュメントを一括更新

### Fixed
- `templates/scripts/dd-index-gen.sh`: アーカイブ判定が固定正規表現 `archived/` だったため、`doc/DD/archive/` 等の配置でアーカイブ済みDDが「進行中」に混入する問題（ARCHIVE_DIR 前方一致 + `archived?/` で判定）
- アーカイブリマインダーフック（`post-bash-dd-archive-reminder.sh`）が `archive/`（d なし）配置では発火しない問題（`.dd-config` の ARCHIVE_DIR + `archived?/` を検出）
- `templates/scripts/README.md` のTS参考実装2件: 4列ヘッダ表で補足セルをステータスと誤読する問題（`fields[4]` 優先分岐を除去し awk `$4`/`$5` と同一の解釈に）、完了済み「主な成果」列が常に空で出力される問題
- `templates/scripts/dd-health.sh` の Windows gawk 正規表現バグ2件を修正（適用先プロジェクトの実DDで全Phase✅を実機確認）
  - 🔬絵文字（非BMP文字）は Windows の gawk の正規表現で照合できず、「🔬機械検証タスクがないPhase」が全DD・全Phaseで偽陽性になる問題（タスク文言「機械検証/机上突合/机上検証」での判定に変更）
  - 多バイト文字を含む正規表現では `.*` が絵文字を跨げず、Phaseタイトル切り出し `sub(/[:：].*/)` が「Phase 1: 設計（📐 x）」→「Phase 1� x）」のような切り残しになる問題（正規表現でなく index/substr で切る方式に変更）
- `templates/scripts/dd-index-gen.sh` の3件のバグを修正
  - グロブ `DD-*.md` が `DD-INDEX.md` 自身をマッチし「DD-INDEX」エントリが出力に混入する問題（ファイル収集時に basename で除外）
  - アーカイブ0件時に grep パイプラインが `pipefail` + `set -e` で非ゼロ終了する問題（`|| true` ガード）
  - レポート行 `archived=0` の表示に改行混入で `0\n0` になる問題（`|| echo 0` → `|| true`）

## [1.0.0] - 2025-01-24

### Added
- 初版リリース
- Level 1〜3の3段階構成
  - Level 1: 最小構成（テンプレート + 基本ルール）
  - Level 2: 標準構成（+ スラッシュコマンド + 開発フロー）
  - Level 3: フル構成（+ 仕様書連携 + 全コマンド）
- クイックスタートガイド
- カスタマイズガイド
  - テンプレートセクションの追加例
  - 開発フローのバリエーション
  - 他のAI環境での使用方法
- 実例集（機能実装DD、設計判断DD）
