# Usakame Games Collection (30 Games)

ゲームエンジン **[Usakame](https://github.com/ongaeshi/usakame) (`uk`)** で構築された、1ファイル完結・タイルマップ＆サウンド不使用（基本API + `bg()` + カスタムパレット＆スプライトのみ）のゲーム＆ビジュアルトイ30本コレクションです。

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

* `games/`: 30本のゲーム本体（各1ファイル完結）
* `ROADMAP.md`: 30本の企画リスト・進捗・流用メモ・コミット記録
* `refs/`: 参考実装（`boss_rush.rb`, `diorama.rb`, `orb_breaker.rb`, `chrono_duel.rb` 等）
* `docs/`: Usakame API 仕様書・mrubyedge リファレンス
* `scripts/verify_game.py`: 自動検証スクリプト本体（`scripts/verify_game.ps1` は互換ラッパー）
