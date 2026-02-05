# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- 実例集に「バグ修正DD（見落としチェック記録付き）」を追加
  - 見落としチェックの実践例を含む
  - 各Phaseで問題を発見・対応した記録

### Changed
- 自己レビュー → 見落としチェック（Devil's Advocate アプローチ）
  - 「確認したか？」ではなく「何を見落としているか？」を問う形式に変更
  - 最低発見数ルール追加（変更規模に応じて1-3件）
  - 多数発見時の再チェックルール追加（小3件/中5件/大7件以上で別角度チェック）
  - Phase種別ごとのチェックリスト追加（実装/テスト/ドキュメント）
  - よくある見落としパターンを例示
  - 「発見ゼロは疑わしい」原則の導入

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
