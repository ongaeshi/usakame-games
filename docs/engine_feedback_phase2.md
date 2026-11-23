# Usakame Engine & mrubyedge 開発フィードバック・改善要望メモ（Phase 2: 31〜40）

Phase 1（`docs/engine_feedback.md`）で対応された新API（`alpha` 半透明、`blend(:add / :mul)`、太線 `line` / `polyline`、塗りつぶし多角形 `trifill` / `quadfill` / `polygonfill`、高解像度 `bg()` 自動フィット、`Float - Integer` 修正、`verify_game.py` 字句解析）を活用し、新作7本＋DX進化版3本の計10本（No.31〜40）を連続制作した振り返りです。

---

## 1. Phase 2 新APIで劇的に良くなった点

### ① `blend(:add / :mul)` ＋ `alpha` の表現力
- **`31_prism_laser.rb` / `40_fireworks_symphony.rb`**: `blend(:add)` により、レーザーのRGB加算混色や花火の重なり白熱発光が「光そのもの」として自然に表現できるようになった。
- **`33_shadow_thief.rb` / `34_drift_circuit_dx.rb` / `36_submarine_sonar_2.rb`**: `blend(:mul)` で画面全体を夜の暗闇や漆黒の深海へ沈め、その上から `blend(:add)` の視界コーン・ヘッドライト・サーチライトを重ねることで、擬似表現では不可能だった明暗コントラストが数行で実現できた。

### ② `polyline` / `trifill` / `quadfill` / `polygonfill`
- **`34_drift_circuit_dx.rb`**: 前作 `05` で `circfill` を大量スタンプして描いていた路面が、`polyline` 太線数本だけで滑らか・高速に描画できるようになった。
- **`32_star_trench.rb`**: `quadfill` / `trifill` により、Zソートされた面塗り3Dポリゴン渓谷・敵・戦艦をピュアRubyで違和感なく構築できた。
- **`33_shadow_thief.rb` / `39_vitrail_craft.rb`**: 任意多角形 `polygonfill(..., alpha)` により、壁遮蔽レイキャスト視界コーンやステンドグラスの多角形ガラス片が美しく描画できた。

### ③ 高解像度 `bg()` 自動フィット（`fit: :auto`）
- **`32`〜`34`, `36` (`320x240`) / `37`, `40` (`480x270`) / `38` (`640x480`)**: 仮想解像度を変更しても `bg(:mountain)` や `bg(:cave)` が自動で画面全体にフィットし、ワイド・高精細ゲームの制作コストが大幅に下がった。

### ④ `Float - Integer` 対応と `verify_game.py`
- `@px - 10` のような記述で VM パニックが一切起きなくなり、物理・座標計算の記述ストレスが解消された。
- `verify_game.py` の字句解析化により、`Array#map` やローカル変数名での誤検知がゼロになった。

---

## 2. Phase 2 で新たに踏んだ制約・ハマりやすい仕様

### ① 描画APIのキーワード引数 vs 位置引数
- **遭遇ゲーム**: `31_prism_laser.rb`
- **現象**: `line(x0, y0, x1, y1, col, width: 6, alpha: 0.42)` のように `width:` / `alpha:` をキーワード引数で渡したところ、太さや透明度が反映されず 1px 不透明線で描画された。
- **回避策**: `line(x0, y0, x1, y1, col, 6, 0.42)` のように**位置引数**として渡すことで正常に太線・半透明が効くことを確認。`rect` / `tri` / `poly` / `print_text` 等でも位置引数を統一使用した。
- **改善要望**: `docs/api.md` 上の引数表と同じ感覚で `width:` / `alpha:` キーワード引数も全図形APIで受け取れるようにするか、位置引数推奨を明記すると親切。

### ② `Array#each` ブロック引数の配列展開（Destructuring）
- **遭遇ゲーム**: `31_prism_laser.rb`（タイトル画面）
- **現象**: `[[y0, col0], [y1, col1]].each do |ty, c|` と書くと、mrubyedge では `ty` に配列 `[y0, col0]` がそのまま入り、`c` が `nil` になった。
- **回避策**: `each do |pair| ty = pair[0]; c = pair[1]` のようにインデックスアクセスする。

### ③ 高解像度時の `print_text` デフォルトサイズ
- **遭遇ゲーム**: `32_star_trench.rb`
- **現象**: `320x240` や `480x270` で `print_text(str, x, y, col)` をサイズ省略で呼ぶと、大きなフォント（16px相当）で描画され HUD が重なりやすかった。
- **回避策**: HUD や小ラベルには第5引数で明示的に `print_text(str, x, y, col, 8)`（8px美咲/6x8フォント）を指定する。

### ④ マウス入力API名（`btnp(:mouse_l)`）
- **遭遇ゲーム**: `31_prism_laser.rb`
- **現象**: `mouse_btn(0)` は未定義で `NoMethodError` となった。
- **回避策**: `btn(:mouse_l)` / `btnp(:mouse_l)` / `btnp(:mouse_r)` と `mouse_x` / `mouse_y` を使用する。

### ⑤ `Array#index` 未実装
- **遭遇ゲーム**: `40_fireworks_symphony.rb`
- **現象**: Phase 1 の `docs/engine_feedback.md` にも記載がある通り `Array#index` は未実装。
- **回避策**: インデックス検索が必要な場合は手動ループまたはランダム選択で代替する。
