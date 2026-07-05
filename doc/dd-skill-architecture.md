# DD スキル アーキテクチャ

DDスキルの各操作における、LLM・ファイル・フック・スクリプトの連動を可視化した設計書。

---

## 1. 全体俯瞰: DDライフサイクル

```mermaid
flowchart LR
    subgraph 作成
        A["/dd new"] --> B["DD-NNN_xxx.md\n作成"]
        B --> C["dd-index-gen.sh\n実行"]
    end

    subgraph 運用
        D["/dd list"] --> E["DD-INDEX.md\nRead"]
        F["/dd search"] --> E
        F --> G["Grep 全文検索\n（フォールバック）"]
        H["/dd 参照"] --> E
        H2["/dd log"]
    end

    subgraph アーカイブ
        I["/dd archive"] --> J["DD本体+フォルダ\nを移動"]
        J --> K["post-bash hook\nリマインダー"]
        K --> L["dd-index-gen.sh\n実行"]
    end

    subgraph ガードレール
        M["pre-edit-guard.sh"]
        M -. "ブロック" .-> N["settings.json\n.env\nDD-INDEX.md"]
    end

    C --> E
    L --> E
    作成 --> 運用
    運用 --> アーカイブ
```

---

## 2. DD新規作成フロー

```mermaid
sequenceDiagram
    actor User
    participant LLM
    participant FS as ファイルシステム
    participant Script as dd-index-gen.sh

    User->>LLM: /dd new タイトル

    Note over LLM: Step 1-2: テンプレート読み込み
    LLM->>FS: Read templates/guides.md
    FS-->>LLM: アプローチ選択ガイド
    LLM->>FS: Read templates/dd_template.md<br/>(+ 差分テンプレート)
    FS-->>LLM: DD骨格

    Note over LLM: Step 3: 採番
    alt DD-INDEX.md が存在
        LLM->>FS: Read DD-INDEX.md
        FS-->>LLM: INDEXから最大番号
    else INDEX未存在
        LLM->>FS: ls doc/DD/ + doc/archived/DD/
        FS-->>LLM: ファイルスキャンで最大番号
    end

    Note over LLM: Step 4-6: DD作成
    LLM->>FS: Write DD-{連番}_{タイトル}.md
    Note right of FS: HTMLコメント除去済み

    Note over LLM: Step 7: Playwright MCP確認（画面系のみ）

    Note over LLM: Step 8: インデックス更新
    LLM->>Script: bash scripts/dd-index-gen.sh
    Script->>FS: head -6 全DDファイル
    Script->>FS: Write DD-INDEX.md
    Script-->>LLM: 完了レポート

    LLM-->>User: DD作成完了
```

---

## 3. アーカイブフロー

```mermaid
sequenceDiagram
    actor User
    participant LLM
    participant FS as ファイルシステム
    participant Hook as post-bash hook
    participant Guard as pre-edit-guard
    participant Script as dd-index-gen.sh

    User->>LLM: /dd archive 番号

    Note over LLM: 事前確認（必須）
    LLM->>FS: ls doc/DD/ | grep DD-{番号}
    FS-->>LLM: 本体 + フォルダ一覧

    Note over LLM: ファイル移動
    LLM->>FS: mv DD-{番号}_*.md → archived/
    activate Hook
    FS-->>Hook: PostToolUse(Bash) 発火
    Hook-->>LLM: ⚠️ INDEX更新リマインダー
    deactivate Hook

    opt DD番号フォルダが存在
        LLM->>FS: mv DD-{番号}/ → archived/
        Note right of Hook: .mdファイルのみに反応<br/>フォルダ移動では発火しない
    end

    Note over LLM: チェックリスト確認
    LLM->>LLM: ✅ 本体移動済み
    LLM->>LLM: ✅ フォルダ移動済み（該当時）
    LLM->>LLM: ✅ 元の場所に残りなし

    Note over LLM: インデックス再生成
    LLM->>Script: bash scripts/dd-index-gen.sh
    Script->>FS: Write DD-INDEX.md
    Note right of Guard: Edit/Writeはガードが<br/>ブロックするが<br/>Bash経由のスクリプトは通過
    Script-->>LLM: 完了レポート

    LLM->>LLM: ✅ INDEX再生成済み
    LLM-->>User: アーカイブ完了
```

---

## 4. 検索フロー

```mermaid
flowchart TD
    A["ユーザー: DDを検索 / キーワード"] --> B["Phase 1: インデックス検索"]
    B --> C{"DD-INDEX.md\n存在する？"}
    C -- Yes --> D["DD-INDEX.md を Read"]
    C -- No --> G

    D --> E{"キーワードに\nマッチするDD\nあり？"}
    E -- Yes --> F["結果表示"]
    F --> F2{"全文検索も\nしますか？"}
    F2 -- Yes --> G
    F2 -- No --> END["完了"]

    E -- No --> G["Phase 2: 全文検索"]
    G --> H["Grep: doc/DD/*.md"]
    G --> I["Grep: archived/DD/*.md"]
    H --> J{"10件超？"}
    I --> J
    J -- Yes --> K["タイトルマッチ優先表示"]
    J -- No --> L["全件表示"]
    K --> END
    L --> END
```

---

## 5. Hooks 発火タイミング

```mermaid
flowchart TD
    subgraph "PreToolUse（実行前）"
        PE["Edit / Write 呼び出し"]
        PE --> PG["pre-edit-guard.sh"]
        PG --> CHK1{"対象ファイルは？"}
        CHK1 -- "settings.json\nsettings.local.json" --> BLOCK1["❌ ブロック\nHook設定の改竄防止"]
        CHK1 -- ".env / .env.local\n.env.production" --> BLOCK2["❌ ブロック\nシークレット保護"]
        CHK1 -- "DD-INDEX.md" --> BLOCK3["❌ ブロック\n自動生成ファイル保護"]
        CHK1 -- "その他" --> PASS1["✅ 通過"]
    end

    subgraph "PostToolUse（実行後）"
        PB["Bash 呼び出し"]
        PB --> PA["post-bash-dd-archive-reminder.sh"]
        PA --> CHK2{"コマンドに\nmv.*DD-.*archived/\nを含む？"}
        CHK2 -- Yes --> REMIND["⚠️ リマインダー表示\nINDEX更新を促す"]
        CHK2 -- No --> PASS2["何もしない"]
    end

    style BLOCK1 fill:#ffcccc,stroke:#cc0000
    style BLOCK2 fill:#ffcccc,stroke:#cc0000
    style BLOCK3 fill:#ffcccc,stroke:#cc0000
    style REMIND fill:#fff3cd,stroke:#cc9900
    style PASS1 fill:#ccffcc,stroke:#009900
    style PASS2 fill:#ccffcc,stroke:#009900
```

---

## 6. DD-INDEX.md アクセスパターン

```mermaid
flowchart LR
    subgraph "Read（参照）"
        LIST["/dd list"]
        SEARCH["/dd search"]
        REF["/dd 参照"]
    end

    subgraph "Write（更新） — スクリプト経由のみ"
        NEW["/dd new"]
        ARCHIVE["/dd archive"]
        REBUILD["/dd rebuild-index"]
    end

    INDEX["DD-INDEX.md"]

    LIST -- "Read" --> INDEX
    SEARCH -- "Read" --> INDEX
    REF -- "Read\n（番号→ファイル名解決）" --> INDEX

    NEW -- "bash dd-index-gen.sh" --> INDEX
    ARCHIVE -- "bash dd-index-gen.sh" --> INDEX
    REBUILD -- "bash dd-index-gen.sh" --> INDEX

    GUARD["pre-edit-guard.sh"]
    GUARD -. "Edit/Write\nブロック" .-> INDEX

    style GUARD fill:#ffcccc,stroke:#cc0000
    style INDEX fill:#e6f3ff,stroke:#0066cc
```

---

## 設計原則

| 原則 | 説明 |
|------|------|
| **INDEX更新は常にスクリプト経由** | LLMの直接編集をpre-edit-guardでブロックし、`dd-index-gen.sh` のみが書き込む |
| **運用の健全性も機械検証** | 「DD運用が回っているか」をLLMの自己申告ではなく `dd-health.sh` の静的分析で測る（滞留・クローズ漏れ・ログ形骸化・DA雛形残置の検出。テレメトリ不要 — DD本体そのものが分析対象） |
| **スクリプトは冪等** | 何度実行しても同じ結果。壊れたINDEXはいつでも再生成可能 |
| **Hooksは人間が設定** | settings.json のフック設定はLLMではなく人間が手動で行う |
| **フォールバック設計** | INDEX未存在時はファイルスキャンで動作。スクリプト未存在時はユーザーに通知 |
