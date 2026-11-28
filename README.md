# Usakame Games Collection

ゲームエンジン **[Usakame](https://github.com/ongaeshi/usakame) (`uk`)** で構築された、1ファイル完結のゲーム＆ビジュアルトイコレクションです（Phase 1〜4 の全60タイトル＋Ver.2 リメイク2本、計62本）。

## ドキュメント・ショーケース

* **[ゲームショーケース (docs/games_showcase.md)](docs/games_showcase.md)**: 全60タイトル＋Ver.2 2本の遊びどころ・技術的工夫点・スクリーンショットまとめ
* **エンジンフィードバック（全バージョン）**:
  * [Phase 1 (No.01–30)](docs/engine_feedback.md)
  * [Phase 2 (No.31–40)](docs/engine_feedback_phase2.md)
  * [Phase 3 (No.41–50)](docs/engine_feedback_phase3.md)
  * [Phase 4 (No.51–60)](docs/engine_feedback_phase4.md)

## 実行方法

```powershell
# Usakame エンジンで任意のゲームを起動（PATH に通っている uk を使用）
uk run games/01_grapple_ascent.rb
```

## 自動検証コマンド

```powershell
# 禁則API・@SPRITE寸法・uk check (60F)・ガチャキー検証 (480F) を一括実行
pwsh -NoProfile -File scripts/verify_game.ps1 games/01_grapple_ascent.rb
```

## ディレクトリ構成

* `games/`: 62本のゲーム本体（No.01〜60＋Ver.2 2本、各1ファイル完結）
* `ROADMAP.md`: 全60本の企画リスト・進捗・設計メモ・コミット記録
* `refs/`: 参考実装（`boss_rush.rb`, `diorama.rb`, `orb_breaker.rb`, `chrono_duel.rb` 等）
* `docs/`: Usakame API 仕様書・mrubyedge リファレンス・ショーケース・エンジンフィードバック集
* `scripts/verify_game.py`: 自動検証スクリプト本体（`scripts/verify_game.ps1` は互換ラッパー）
