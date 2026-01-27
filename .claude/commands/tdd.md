---
description: テスト駆動開発ワークフローを強制します。インターフェースを定義し、まずテストを生成し、それからテストをパスする最小限のコードを実装します。80%以上のカバレッジを確保します。
---

# TDD コマンド

このコマンドは **tdd-guide** エージェントを呼び出し、テスト駆動開発の方法論を強制します。

## このコマンドの機能

1. **インターフェースの定義** - まず型/インターフェースを定義
2. **テストを先に生成** - 失敗するテストを書く（RED）
3. **最小限のコードを実装** - テストをパスするのに必要な最小限のコードを書く（GREEN）
4. **リファクタリング** - テストをグリーンに保ちながらコードを改善（REFACTOR）
5. **カバレッジの検証** - 80%以上のテストカバレッジを確保

## 使用するタイミング

以下の場合に `/tdd` を使用してください：
- 新機能の実装時
- 新しい関数/コンポーネントの追加時
- バグ修正時（まずバグを再現するテストを書く）
- 既存コードのリファクタリング時
- 重要なビジネスロジックの構築時

## 動作の仕組み

tdd-guide エージェントは以下を行います：

1. 入出力の**インターフェースを定義**
2. **失敗するテストを書く**（コードがまだ存在しないため）
3. **テストを実行**し、正しい理由で失敗することを確認
4. テストをパスするための**最小限の実装を書く**
5. **テストを実行**し、パスすることを確認
6. テストをグリーンに保ちながら**コードをリファクタリング**
7. **カバレッジをチェック**し、80%未満の場合はテストを追加

## TDD サイクル

```
RED → GREEN → REFACTOR → REPEAT

RED:      失敗するテストを書く
GREEN:    テストをパスする最小限のコードを書く
REFACTOR: コードを改善し、テストはパスさせ続ける
REPEAT:   次の機能/シナリオへ
```

## 使用例

```
User: /tdd 市場の流動性スコアを計算する関数が必要です

Agent (tdd-guide):
# TDD セッション: 市場流動性スコア計算機

## Step 1: インターフェースの定義 (SCAFFOLD)

```typescript
// lib/liquidity.ts
export interface MarketData {
  totalVolume: number
  bidAskSpread: number
  activeTraders: number
  lastTradeTime: Date
}

export function calculateLiquidityScore(market: MarketData): number {
  // TODO: Implementation
  throw new Error('Not implemented')
}
```

## Step 2: 失敗するテストを書く (RED)

```typescript
// lib/liquidity.test.ts
import { calculateLiquidityScore } from './liquidity'

describe('calculateLiquidityScore', () => {
  it('should return high score for liquid market', () => {
    const market = {
      totalVolume: 100000,
      bidAskSpread: 0.01,
      activeTraders: 500,
      lastTradeTime: new Date()
    }

    const score = calculateLiquidityScore(market)

    expect(score).toBeGreaterThan(80)
    expect(score).toBeLessThanOrEqual(100)
  })

  it('should return low score for illiquid market', () => {
    const market = {
      totalVolume: 100,
      bidAskSpread: 0.5,
      activeTraders: 2,
      lastTradeTime: new Date(Date.now() - 86400000) // 1 day ago
    }

    const score = calculateLiquidityScore(market)

    expect(score).toBeLessThan(30)
    expect(score).toBeGreaterThanOrEqual(0)
  })

  it('should handle edge case: zero volume', () => {
    const market = {
      totalVolume: 0,
      bidAskSpread: 0,
      activeTraders: 0,
      lastTradeTime: new Date()
    }

    const score = calculateLiquidityScore(market)

    expect(score).toBe(0)
  })
})
```

## Step 3: テストを実行 - 失敗を確認

```bash
npm test lib/liquidity.test.ts

FAIL lib/liquidity.test.ts
  ✕ should return high score for liquid market (2 ms)
    Error: Not implemented

1 test failed, 0 passed
```

テストは期待通り失敗しました。実装の準備ができました。

## Step 4: 最小限のコードを実装 (GREEN)

```typescript
// lib/liquidity.ts
export function calculateLiquidityScore(market: MarketData): number {
  // Handle zero volume edge case
  if (market.totalVolume === 0) {
    return 0
  }

  // Calculate component scores (0-100 scale)
  const volumeScore = Math.min(market.totalVolume / 1000, 100)
  const spreadScore = Math.max(100 - (market.bidAskSpread * 1000), 0)
  const traderScore = Math.min(market.activeTraders / 10, 100)

  // Recent activity bonus
  const hoursSinceLastTrade = (Date.now() - market.lastTradeTime.getTime()) / (1000 * 60 * 60)
  const recencyScore = Math.max(100 - (hoursSinceLastTrade * 10), 0)

  // Weighted average
  const score = (
    volumeScore * 0.4 +
    spreadScore * 0.3 +
    traderScore * 0.2 +
    recencyScore * 0.1
  )

  return Math.min(Math.max(score, 0), 100) // Clamp to 0-100
}
```

## Step 5: テストを実行 - パスを確認

```bash
npm test lib/liquidity.test.ts

PASS lib/liquidity.test.ts
  ✓ should return high score for liquid market (3 ms)
  ✓ should return low score for illiquid market (2 ms)
  ✓ should handle edge case: zero volume (1 ms)

3 tests passed
```

全てのテストがパスしました！

## Step 6: リファクタリング (IMPROVE)

```typescript
// lib/liquidity.ts - Refactored with constants and better readability
const WEIGHTS = {
  VOLUME: 0.4,
  SPREAD: 0.3,
  TRADERS: 0.2,
  RECENCY: 0.1,
} as const

const SCALE_FACTORS = {
  VOLUME: 1000,
  SPREAD: 1000,
  TRADERS: 10,
  RECENCY_PENALTY: 10,
} as const

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max)
}

export function calculateLiquidityScore(market: MarketData): number {
  if (market.totalVolume === 0) return 0

  const volumeScore = Math.min(market.totalVolume / SCALE_FACTORS.VOLUME, 100)
  const spreadScore = clamp(100 - (market.bidAskSpread * SCALE_FACTORS.SPREAD), 0, 100)
  const traderScore = Math.min(market.activeTraders / SCALE_FACTORS.TRADERS, 100)

  const hoursSinceLastTrade = (Date.now() - market.lastTradeTime.getTime()) / (1000 * 60 * 60)
  const recencyScore = clamp(100 - (hoursSinceLastTrade * SCALE_FACTORS.RECENCY_PENALTY), 0, 100)

  const weightedScore =
    volumeScore * WEIGHTS.VOLUME +
    spreadScore * WEIGHTS.SPREAD +
    traderScore * WEIGHTS.TRADERS +
    recencyScore * WEIGHTS.RECENCY

  return clamp(weightedScore, 0, 100)
}
```

## Step 7: テストがまだパスすることを確認

```bash
npm test lib/liquidity.test.ts

PASS lib/liquidity.test.ts
  ✓ should return high score for liquid market (3 ms)
  ✓ should return low score for illiquid market (2 ms)
  ✓ should handle edge case: zero volume (1 ms)

3 tests passed
```

リファクタリング完了、テストはまだパスしています！

## Step 8: カバレッジをチェック

```bash
npm test -- --coverage lib/liquidity.test.ts

File           | % Stmts | % Branch | % Funcs | % Lines
---------------|---------|----------|---------|--------
liquidity.ts   |   100   |   100    |   100   |   100

Coverage: 100% (Target: 80%)
```

TDD セッション完了！
```

## TDD ベストプラクティス

**推奨事項：**
- テストは実装の前に書く
- 実装前にテストを実行し、失敗することを確認する
- テストをパスするための最小限のコードを書く
- テストがグリーンになってからのみリファクタリングする
- エッジケースとエラーシナリオを追加する
- 80%以上のカバレッジを目指す（重要なコードは100%）

**避けるべきこと：**
- テストの前に実装を書く
- 変更後のテスト実行をスキップする
- 一度に多くのコードを書く
- 失敗したテストを無視する
- 実装の詳細をテストする（振る舞いをテストすべき）
- 全てをモックする（統合テストを優先）

## 含めるべきテストの種類

**ユニットテスト**（関数レベル）：
- 正常系のシナリオ
- エッジケース（空、null、最大値）
- エラー条件
- 境界値

**統合テスト**（コンポーネントレベル）：
- API エンドポイント
- データベース操作
- 外部サービス呼び出し
- hooks を使用した React コンポーネント

**E2E テスト**（`/e2e` コマンドを使用）：
- 重要なユーザーフロー
- 複数ステップのプロセス
- フルスタック統合

## カバレッジ要件

- **80%が最小値**（全てのコード）
- **100%が必須**：
  - 金融計算
  - 認証ロジック
  - セキュリティ上重要なコード
  - コアビジネスロジック

## 重要な注意事項

**必須**：テストは実装の前に書く必要があります。TDD サイクルは：

1. **RED** - 失敗するテストを書く
2. **GREEN** - パスするように実装
3. **REFACTOR** - コードを改善

RED フェーズをスキップしないでください。テストの前にコードを書かないでください。

## 他のコマンドとの連携

- まず `/plan` で構築するものを理解
- `/tdd` でテストと共に実装
- ビルドエラーが発生したら `/build-and-fix` を使用
- `/code-review` で実装をレビュー
- `/test-coverage` でカバレッジを検証

## 関連エージェント

このコマンドは以下にある `tdd-guide` エージェントを呼び出します：
`~/.claude/agents/tdd-guide.md`

また、以下にある `tdd-workflow` スキルを参照できます：
`~/.claude/skills/tdd-workflow/`
