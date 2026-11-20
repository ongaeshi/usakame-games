# AGENTS.md (usakame-games)

このリポジトリ（`usakame-games`）で AI エージェントが Usakame ゲームを連続制作する際の絶対ルールとワークフローです。

---

## 1. プロジェクト目標と共通制約

* **目標1**: ユーザーが実際にちゃんと遊べるゲーム（少なくとも5分は触れて、繰り返しても楽しい）
* **目標2**: SNS などでシェアして喜ばれそうな見た目（GIF・スクショ映え）のあるゲーム
* 各タイトルはいずれか（理想は両方）を高い水準で満たし、**全30本すべてネタ被りなし**で `games/` 配下に **1ファイル完結** で実装する。
* **使用API範囲（厳守）**:
  * **基本API + `bg()` + スプライト（`@PALETTE` / `@SPRITE` / `spr` / `spr_ext` / `spr_clip` / `spr_id`）+ キーボード/マウス入力** のみを使用。
  * **タイルマップ（`map`, `mget`, `mset`, `mdel`, `mclear`, `@MAP`）およびサウンド（`sfx`, `music`, `play`, `tone`, `@SFX`, `@MUSIC`）は一切使用しない**。
  * 外部画像ファイルは使わず、内蔵 BG プリセット（`:sky`, `:mountain`, `:forest`, `:cave`, `:city`, `:space`, `:cyber`, `:training`）と `__END__` 内の `@PALETTE` / `@SPRITE` のみで完結させる。
* **流用ルール**:
  * `refs/` および作成済みの `games/*.rb` の汎用クラス（`EffectSystem`、物理ヘルパー、3D射影、UIヘルパー等）や `@PALETTE` / `@SPRITE` は、作品に合わせて積極的に流用・アレンジしてよい。

---

## 2. mrubyedge & Usakame エンジン必須ルール

コード作成前に必ず [docs/api.md](docs/api.md) および [docs/mrubyedge_api.md](docs/mrubyedge_api.md) を参照し、以下を厳守すること。

### ① 未実装メソッドの禁止
* ❌ `array.sample` → ⭕ `array[rand(array.size)]`
* ❌ `array.shuffle` → ⭕ Fisher-Yates 自前実装（`refs/procgen_utils.rb` 参照）
* ❌ `array.reverse` → ⭕ 逆順 `while` ループ
* ❌ `array.delete(item)` → ⭕ `array.reject! { |x| x == item }` または `delete_at(i)`
* ❌ `hash.key?(k)` / `hash.include?(k)` → ⭕ `hash.has_key?(k)`
* ❌ `hash.fetch` / `hash.dig` → ⭕ `hash[a] && hash[a][b]`
* ❌ `string.gsub` / `sub` → ⭕ `split` + `join`
* ❌ `n.upto(m)` / `downto` → ⭕ `(n..m).each` または `while`
* ❌ `n.even?` / `odd?` → ⭕ `n % 2 == 0` / `n % 2 != 0`
* ❌ `sleep` / `Time.now` → ⭕ フレームカウンタ制御

### ② 実地確認済みの mrubyedge / エンジン注意点
* **`attr_accessor` / `attr_reader`**: 1回の呼び出しに **最大6シンボル以下** に分割すること（多すぎると `RuntimeError: Class#attr_reader must be called with symbols` が発生する）。
* **オプションハッシュ渡し**: Ruby 側で定義した `def initialize(opts)` 等のメソッドにハッシュを渡す際は、必ず **明示的ハッシュ `Foo.new({ a: 1, b: 2 })`** または位置引数を使うこと（`{}` なしキーワード風呼び出しは `ArgumentError` になる）。
* **継承・`super` 回避**: クラス継承や `super` は使わず、独立クラス／コンポジション構成にする。
* **`spr_ext` のピボット差**: `rot == 0` 時は左上基準スケーリング、`rot != 0` 時は中心基準回転・スケーリング。`refs/boss_rush.rb` の `draw_spr_grounded` / `draw_spr_centered` を流用すると安全。
* **`bg()` と `camera()`**: `bg()` は `camera()` のオフセットを受けない。シェイク時は `scale: 1.04` + `scroll_x` + `y` で端の黒隙間を防ぎ、HUD 描画前に必ず `camera()` と `clip()` をリセットする。
* **高品質ドット絵**: `.agents/skills/usakame-sprite/SKILL.md`（主役・ボス向け）および `.agents/skills/usakame-sprite-fast/SKILL.md`（小物・大量生成向け）を使い分け、Bank 0 上限（256スロット = 16x16グリッド）内に収めること。

---

## 3. 1本完成ごとの必須フロー（自動コミット）

1. `ROADMAP.md` から次の未着手ゲーム（`[ ]`）を選ぶ。
2. 必要に応じて `refs/` や過去作の `games/*.rb` からユーティリティ・スプライトを流用しつつ、1ファイル完結で実装する。
3. 自動検証スクリプトを実行し、終了コード 0 を確認する：
   ```powershell
   pwsh -NoProfile -File scripts/verify_game.ps1 games/<file>.rb
   ```
4. スクリーンショットを撮影し（`screenshots/` ではなく一時フォルダまたは撮影後削除）、`read_file` で目視確認する：
   ```powershell
   uk run games/<file>.rb -s tmp/preview.png -f 60
   uk run games/<file>.rb -s tmp/preview_play.png -f 180 -g
   ```
   UI被り・文字切れ・スプライト崩れがあれば修正して再検証する（確認後 `tmp/` は削除または `.gitignore` 対象のままコミットしない）。
5. `ROADMAP.md` の該当行を `[x]` に更新し、簡潔な実装メモを追記する。
6. **1本完成するたびに即コミットする**（ユーザー確認不要で自動進行）：
   ```powershell
   git add games/<file>.rb ROADMAP.md
   git commit -m "feat(games): add <file> - <Title>"
   ```
