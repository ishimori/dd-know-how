# 業務アプリ試作プロファイル（任意）

業務アプリを試作するリポジトリで毎回伝えている初期方針（画面の既定値・MVP の品質・文書の置き場所・ER図）を、DDの導入と一緒に入れるためのオプションです。DD（Level 2）を導入した後に適用します。業務アプリの試作でなければ入れません。

## 入れるもの

| 内容 | 導入先 | 元 |
|------|--------|-----|
| 開発方針（品質・文書・DB・画面） | `AGENTS.md` へ追記 | [agents-block.md](agents-block.md) |
| 画面の既定値 | `doc/ui-guidelines.md` | [ui-guidelines.md](ui-guidelines.md) |
| 文書の置き場所（L1/L2） | `doc/L1/`・`doc/L2/` と DOC-MAP | 下の手順3 |
| A5ER の形式仕様（DB を使う場合だけ） | `doc/reference/`（git 管理外） | 公式サイトから取得 |

コピーした後は、どれもプロジェクトのファイルです。プロジェクトに合わせて書き換えてかまいません（dd-know-how との差分レポート `dd-update.sh` の比較対象にも入りません）。

## 手順

パスは、導入時に決めた配置に読み替える。以下と [agents-block.md](agents-block.md) の `doc/` は既定（文書ルートが `doc`）の場合の書き方で、`docs/` などで導入したプロジェクトでは `.dd-config` の `DOC_DIR`（DOC-MAP.md のある場所）に置き換える。`doc/templates/` は、AGENTS.md の「DD設定」にあるテンプレートの場所に置き換える。

### 1. 既存の規約を読む

`AGENTS.md`・`doc/DOC-MAP.md`・既存の画面の規約や設計文書を読む。この方針と食い違うものがあれば、差分を示してユーザーに確認する（黙って上書きしない）。

### 2. 開発方針を AGENTS.md へ追記

[agents-block.md](agents-block.md) の節を `AGENTS.md` の末尾に追記する（同じ節が既にあれば重ねない）。DB を使わないプロジェクトでは「DB」の項目を除く。

### 3. 文書の置き場所（L1/L2）

`doc/L1/README.md` と `doc/L2/README.md` を作り、DOC-MAP の「仕様書（現在形の正典）」節を下の内容に置き換える。L1/L2 の中身は、必要になった時点で書く（空の文書を先に並べない）。

既に `doc/spec/` などの仕様書があるプロジェクトでは、移さずにそれを正典として使い、この手順は飛ばす。このとき、手順2で AGENTS.md に追記した「文書」と「DB」の項目（L1/L2 のパスと ER図の置き場所）も、実際の配置に合わせて書き換える。

`doc/L1/README.md`:

```markdown
# L1: 要件

何のために作るか・範囲・作らないもの・成功の判断基準を書く。めったに変わらない。理由と経緯はDDに書き、ここには結果だけを書く。
```

`doc/L2/README.md`:

```markdown
# L2: 基本設計

今どうなっているか（画面・データ・構成）を書く。実装とずれたら L2 を直す。詳細設計はDDが担うので、ここには書かない。ER図（`.a5er`）とDB定義書はスキーマから生成する。
```

DOC-MAP の「仕様書（現在形の正典）」節:

```markdown
## 仕様書（現在形の正典）

> DD = 変更の記録（フロー）、L1/L2 = 今の姿（ストック）。理由と経緯はDDに、結果だけを L1/L2 に書く。
> 変わる文書はDDの起票時に完了前チェックへ書き、完了前に反映する（手順: `doc/spec-sync-check.md`）。

| パス | 説明 |
|------|------|
| `doc/L1/` | 要件（何のためか・範囲・作らないもの・成功の判断基準） |
| `doc/L2/` | 基本設計（今の画面・データ・構成。ER図とDB定義書はスキーマから生成） |
```

### 4. 画面の既定値

[ui-guidelines.md](ui-guidelines.md) を `doc/ui-guidelines.md` へコピーし、DOC-MAP の「プロセス・開発規約」節に1行足す:

```markdown
| `doc/ui-guidelines.md` | 画面の既定値（業務アプリ。画面・モックを作る前に読む） |
```

既に画面の規約があるプロジェクトでは、コピーせず、その規約に無い項目だけを追記案としてユーザーに示す。このとき、手順2で AGENTS.md に追記した「画面」の項目の参照先を、既存の規約のパスに書き換える（`doc/ui-guidelines.md` のままにしない）。

### 5. A5ER の形式仕様（DB を使う場合）

公式サイトから取得し、git の管理から外す。A5:SQL Mk-2 のライセンス規定は著作権者の許可のない再配布を禁じており、形式仕様の扱いは明示されていないため、リポジトリには入れない（公式サイトは、ER図ファイルを読み書きするプログラムの作成や、AI に読み込ませるために使うよう案内している）。

```bash
mkdir -p doc/reference
curl -fsSL -o doc/reference/a5er_specification.jpn.md \
  https://a5m2.mmatsubara.com/document/v2.21/a5er_specification.jpn.md
echo "doc/reference/a5er_specification.jpn.md" >> .gitignore
```

新しい版が出ていれば、公式サイト（https://a5m2.mmatsubara.com/ ）の「ER図ファイル仕様書」にある最新の URL を使う。DOC-MAP の「プロセス・開発規約」節には、別の環境で取り直せるように取得元を書く（行に「未作成」の語を含めておくと、取得前の環境でも `doc-check.sh` がリンク切れにしない）:

```markdown
| `doc/reference/a5er_specification.jpn.md` | A5ER 形式仕様（git 管理外。未作成なら公式サイトから取得: https://a5m2.mmatsubara.com/document/v2.21/a5er_specification.jpn.md ） |
```

### 6. 確認

- `bash scripts/doc-check.sh` がエラーなく終わる
- AGENTS.md に追記した方針の中のパスが、すべて実在する（`doc-check.sh` は AGENTS.md を見ないので、`ls` で確かめる）
- `AGENTS.md` が50行程度に収まっている（超えるなら詳細を `doc/` へ移し、AGENTS.md からはパスで指す）
- `git status` に形式仕様が出ていない（.gitignore が効いている）
