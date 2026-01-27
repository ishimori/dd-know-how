# Streamlit 開発パターン

Streamlit アプリケーション開発のベストプラクティスとパターン集です。

## 基本構造

### アプリケーション構成

```
streamlit-app/
├── app.py                  # メインエントリーポイント
├── pages/                  # マルチページ構成
│   ├── 1_dashboard.py
│   ├── 2_settings.py
│   └── 3_about.py
├── components/             # 再利用可能なコンポーネント
│   ├── __init__.py
│   ├── charts.py
│   └── forms.py
├── services/               # ビジネスロジック
│   ├── __init__.py
│   ├── data_service.py
│   └── api_client.py
├── utils/                  # ユーティリティ
│   ├── __init__.py
│   └── helpers.py
├── .streamlit/
│   └── config.toml         # Streamlit設定
├── requirements.txt
└── README.md
```

## 状態管理パターン

### Session State の基本

```python
import streamlit as st

# 初期化パターン
if 'counter' not in st.session_state:
    st.session_state.counter = 0

# 更新
st.session_state.counter += 1

# コールバックでの更新
def increment():
    st.session_state.counter += 1

st.button('Increment', on_click=increment)
```

### 状態管理クラス

```python
from dataclasses import dataclass
from typing import Optional
import streamlit as st

@dataclass
class AppState:
    user_id: Optional[str] = None
    selected_page: str = "home"
    filters: dict = None

    def __post_init__(self):
        if self.filters is None:
            self.filters = {}

def get_state() -> AppState:
    """Session Stateからアプリ状態を取得"""
    if 'app_state' not in st.session_state:
        st.session_state.app_state = AppState()
    return st.session_state.app_state

# 使用例
state = get_state()
state.selected_page = "dashboard"
```

## キャッシュパターン

### データ取得のキャッシュ

```python
import streamlit as st
import pandas as pd

@st.cache_data(ttl=3600)  # 1時間キャッシュ
def load_data(file_path: str) -> pd.DataFrame:
    """データをキャッシュ付きで読み込み"""
    return pd.read_csv(file_path)

@st.cache_data
def fetch_api_data(endpoint: str, params: dict) -> dict:
    """API呼び出しをキャッシュ"""
    import requests
    response = requests.get(endpoint, params=params)
    return response.json()
```

### リソースのキャッシュ

```python
@st.cache_resource
def get_database_connection():
    """データベース接続をキャッシュ（セッション間で共有）"""
    import psycopg2
    return psycopg2.connect(st.secrets["database"]["url"])

@st.cache_resource
def load_ml_model():
    """MLモデルをキャッシュ"""
    import joblib
    return joblib.load("model.pkl")
```

## コンポーネントパターン

### 再利用可能なフォーム

```python
# components/forms.py
import streamlit as st
from typing import Callable, Optional

def login_form(on_submit: Callable[[str, str], bool]) -> Optional[bool]:
    """ログインフォームコンポーネント"""
    with st.form("login_form"):
        username = st.text_input("ユーザー名")
        password = st.text_input("パスワード", type="password")
        submitted = st.form_submit_button("ログイン")

        if submitted:
            if username and password:
                return on_submit(username, password)
            else:
                st.error("ユーザー名とパスワードを入力してください")
    return None

# 使用例
def handle_login(username: str, password: str) -> bool:
    # 認証ロジック
    return username == "admin" and password == "password"

result = login_form(handle_login)
if result:
    st.success("ログイン成功")
```

### チャートコンポーネント

```python
# components/charts.py
import streamlit as st
import plotly.express as px
import pandas as pd

def metric_card(title: str, value: str, delta: str = None):
    """メトリクスカードコンポーネント"""
    st.metric(label=title, value=value, delta=delta)

def time_series_chart(
    df: pd.DataFrame,
    x_col: str,
    y_col: str,
    title: str = ""
):
    """時系列チャートコンポーネント"""
    fig = px.line(df, x=x_col, y=y_col, title=title)
    fig.update_layout(
        xaxis_title=x_col,
        yaxis_title=y_col,
        hovermode='x unified'
    )
    st.plotly_chart(fig, use_container_width=True)
```

## レイアウトパターン

### サイドバー + メインコンテンツ

```python
import streamlit as st

# サイドバー
with st.sidebar:
    st.title("設定")
    option = st.selectbox("表示モード", ["概要", "詳細", "グラフ"])
    date_range = st.date_input("期間", [])

# メインコンテンツ
st.title("ダッシュボード")

col1, col2, col3 = st.columns(3)
with col1:
    st.metric("売上", "¥1,234,567", "+12%")
with col2:
    st.metric("ユーザー数", "1,234", "+5%")
with col3:
    st.metric("コンバージョン", "3.2%", "-0.1%")

# タブ
tab1, tab2 = st.tabs(["データ", "グラフ"])
with tab1:
    st.dataframe(df)
with tab2:
    st.line_chart(df)
```

### エキスパンダーでの情報整理

```python
with st.expander("詳細設定", expanded=False):
    st.slider("閾値", 0, 100, 50)
    st.checkbox("詳細モード")
    st.multiselect("カテゴリ", ["A", "B", "C"])
```

## エラーハンドリング

### 統一的なエラー表示

```python
import streamlit as st
from contextlib import contextmanager

@contextmanager
def error_boundary(error_message: str = "エラーが発生しました"):
    """エラーバウンダリコンテキストマネージャー"""
    try:
        yield
    except Exception as e:
        st.error(f"{error_message}: {str(e)}")
        if st.secrets.get("debug", False):
            st.exception(e)

# 使用例
with error_boundary("データの読み込みに失敗しました"):
    df = load_data("data.csv")
    st.dataframe(df)
```

### バリデーション

```python
def validate_input(value: str, min_length: int = 1) -> tuple[bool, str]:
    """入力値のバリデーション"""
    if not value:
        return False, "値を入力してください"
    if len(value) < min_length:
        return False, f"{min_length}文字以上入力してください"
    return True, ""

# 使用例
user_input = st.text_input("名前")
is_valid, error_msg = validate_input(user_input, min_length=2)

if st.button("送信"):
    if is_valid:
        st.success("送信しました")
    else:
        st.error(error_msg)
```

## 認証パターン

### シンプルな認証

```python
import streamlit as st
import hmac

def check_password() -> bool:
    """パスワード認証"""
    def password_entered():
        if hmac.compare_digest(
            st.session_state["password"],
            st.secrets["password"]
        ):
            st.session_state["authenticated"] = True
            del st.session_state["password"]
        else:
            st.session_state["authenticated"] = False

    if st.session_state.get("authenticated"):
        return True

    st.text_input(
        "パスワード",
        type="password",
        on_change=password_entered,
        key="password"
    )

    if "authenticated" in st.session_state and not st.session_state["authenticated"]:
        st.error("パスワードが正しくありません")

    return False

# 使用例
if not check_password():
    st.stop()

# 認証後のコンテンツ
st.title("認証済みページ")
```

## 設定ファイル

### .streamlit/config.toml

```toml
[theme]
primaryColor = "#FF6B6B"
backgroundColor = "#FFFFFF"
secondaryBackgroundColor = "#F0F2F6"
textColor = "#262730"
font = "sans serif"

[server]
maxUploadSize = 200
enableXsrfProtection = true

[browser]
gatherUsageStats = false
```

### secrets.toml（ローカル開発用）

```toml
# .streamlit/secrets.toml（.gitignoreに追加）
password = "your-secret-password"
debug = true

[database]
url = "postgresql://user:pass@localhost:5432/db"

[api]
key = "your-api-key"
```

## パフォーマンス最適化

### 遅延読み込み

```python
import streamlit as st

# 必要な時だけ重いライブラリをインポート
if st.button("分析を実行"):
    with st.spinner("分析中..."):
        import pandas as pd
        import numpy as np
        # 重い処理
        result = heavy_computation()
        st.success("完了")
```

### プログレス表示

```python
import streamlit as st
import time

def process_with_progress(items: list):
    """プログレスバー付き処理"""
    progress_bar = st.progress(0)
    status_text = st.empty()

    for i, item in enumerate(items):
        # 処理
        process_item(item)

        # 進捗更新
        progress = (i + 1) / len(items)
        progress_bar.progress(progress)
        status_text.text(f"処理中: {i + 1}/{len(items)}")

    status_text.text("完了")
```

## テストパターン

### ユニットテスト

```python
# tests/test_services.py
import pytest
from services.data_service import process_data

def test_process_data():
    input_data = {"value": 10}
    result = process_data(input_data)
    assert result["processed_value"] == 20

def test_process_data_invalid():
    with pytest.raises(ValueError):
        process_data(None)
```

### Streamlit コンポーネントのテスト

```python
# tests/test_app.py
from streamlit.testing.v1 import AppTest

def test_app_loads():
    at = AppTest.from_file("app.py")
    at.run()
    assert not at.exception

def test_button_interaction():
    at = AppTest.from_file("app.py")
    at.run()
    at.button[0].click()
    at.run()
    assert at.success[0].value == "処理完了"
```

---

**Remember**: Streamlit はプロトタイピングに最適ですが、状態管理とキャッシュを適切に使うことで本番品質のアプリケーションも構築できます。
