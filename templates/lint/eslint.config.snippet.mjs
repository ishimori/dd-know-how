// =====================================================================
// coding-standards.md 機械的強制ルール（ESLint Flat Config 用スニペット）
//
// 既存の eslint.config.js / .mjs にマージして使う:
//   import { ddCodingStandards } from './doc/templates/lint/eslint.config.snippet.mjs';
//   export default [ ...既存設定, ddCodingStandards ];
//
// 方針: エラーメッセージに P規約ID と修正方針を含め、
//       LLM が Lint 出力だけを見て自己修正できるようにする。
//       メッセージを変更できない既存ルールは lint-fix-hints.json で補完する。
// =====================================================================

export const ddCodingStandards = {
  rules: {
    // P01: any の使用禁止（型不明は unknown + 型ガード）
    '@typescript-eslint/no-explicit-any': 'error',

    // P02: 安全でない型キャストの制限（as const / DOM境界 / widening は許可）
    // 段階修正後に 'error' へ昇格する
    '@typescript-eslint/consistent-type-assertions': [
      'warn',
      { assertionStyle: 'as', objectLiteralTypeAssertions: 'never' },
    ],

    // P03: 非 null アサーション（!）の制限
    // 段階修正後に 'error' へ昇格する
    '@typescript-eslint/no-non-null-assertion': 'warn',

    // P19: @ts-ignore 禁止。@ts-expect-error は理由コメント（10文字以上）付きのみ許可
    '@typescript-eslint/ban-ts-comment': [
      'error',
      {
        'ts-ignore': true,
        'ts-expect-error': 'allow-with-description',
        minimumDescriptionLength: 10,
      },
    ],

    // P20: TODO/FIXME の残置禁止（本番コードに未完成マーカーを残さない）
    'no-warning-comments': [
      'error',
      { terms: ['todo', 'fixme'], location: 'anywhere' },
    ],

    // P21: console.log/debug/info の残置禁止（warn/error は構造化ログとして許可）
    'no-console': ['error', { allow: ['warn', 'error'] }],

    // P19: as unknown as（ダブルキャスト）禁止 — メッセージ自体が修正ヒント
    'no-restricted-syntax': [
      'error',
      {
        selector: 'TSAsExpression > TSAsExpression',
        message:
          'P19違反: as unknown as（ダブルキャスト）は禁止。unknown で受けて型ガード（is 述語 / typeof / instanceof）で絞り込むこと。詳細: coding-standards.md P19',
      },
    ],
  },
};

export default [ddCodingStandards];
