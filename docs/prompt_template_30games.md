# Usakame 30本連続制作・再現用マスタープロンプト & 運用ガイド

今回の30本連続制作で培った「途中で止まらず、品質と検証を両立して全30本を完走するためのノウハウ」を反映した、次回以降そのまま流用できるテンプレートです。

---

## 1. 事前準備チェックリスト（制作開始前）

1. **`ROADMAP.md` を用意する**:
   - No.01〜30 の表（`Status` 列 `[ ]`、`File`、`タイトル & コンセプト`、`解像度`、`流用・設計メモ`）を作成する。
2. **`.gitignore` に `tmp/` を入れておく**:
   - 確認用の一時ファイル（`tmp/preview.png` 等）を毎回削除しなくて済むようにする。
3. **検証スクリプト `scripts/verify_game.ps1` を配置する**:
   - 禁止APIチェック + スプライト寸法チェック + `uk check`（通常60F + `-g` 480Fガチャ連打テスト）を1コマンドで回せる状態にしておく。
4. **権限（Auto-Approve）のコツ**:
   - サンドボックス外で実行する必要があるコマンド（環境によっては `git add` / `git commit` 等）は、`a; b` のように `;` で繋げず **単独コマンド** で実行させることで、一度「常に許可」すれば以降の全ゲームで停止せず自動進行できる。

---

## 2. 次回そのまま使える `/goal` プロンプトテンプレート

以下をコピーし、必要に応じてカテゴリや制約を調整してチャットに投入してください。

```markdown
/goal このリポジトリの `ROADMAP.md` に記載された未着手ゲーム（`[ ]`）を順番に、全30本すべて完成するまで連続で制作・検証・コミットしてください。

## 事前確認
作業開始前に `AGENTS.md`、`ROADMAP.md`、`docs/api.md`、`docs/mrubyedge_api.md`、`.agents/skills/usakame-sprite/SKILL.md` を確認し、参考・流用元として `refs/` のファイルを活用してください。

## 各ゲームの制作ルール
1. **品質目標（どちらか必須、理想は両方）**:
   - 目標1: ユーザーが実際に少なくとも5分は夢中で遊べ、繰り返しても楽しいゲーム性（手触り・成長/スコア・リプレイ性）
   - 目標2: SNS などでシェアして喜ばれそうな見た目（カスタムパレット高品質ドット絵・BG演出・パーティクル・無音でも気持ちいいヒットストップ/シェイク/フラッシュ）
2. **絶対制約**:
   - **1ファイル完結**（`games/XX_<name>.rb`、外部画像不使用）
   - **基本API + `bg()` + スプライト + キーボード/マウス入力のみ**を使用
   - **タイルマップ（`map`, `mget`, `mset`, `mdel`, `@MAP`）とサウンド（`sfx`, `music`, `play`, `tone`, `@SFX`）は一切使用しない**
   - **mrubyedge 鉄則**:
     - 未実装メソッド（`sample`, `shuffle`, `reverse`, `delete`, `key?`, `include?` on Hash, `fetch`, `dig`, `gsub`, `sub`, `even?`, `odd?`, `upto`, `downto`, `index`, `fill`, `map`）を使わない
     - `Float` から `Integer` リテラルを引かない（必ず `y - 10.0` のように `.0` を付ける）
     - `.each` ループ中に同じ配列へ `<<` しない（一時配列に溜めてループ後に追加する）
     - `attr_accessor` は1行6シンボル以下、ハッシュ引数は明示的 `({ ... })`、クラス継承/`super` 不使用
3. **1本完成ごとの必須検証＆自動コミット（許可待ちせず自動進行）**:
   - `pwsh -NoProfile -File scripts/verify_game.ps1 games/<file>.rb` を実行し、終了コード 0 を確認する
   - `uk run games/<file>.rb -s tmp/preview.png -f 60`（タイトル確認用、削除不要で毎回上書き）と `uk run games/<file>.rb -s images/<file>.png -f 180 -g`（ギャラリー保存用）でスクリーンショットを撮影し、`read_file` で目視確認する
   - `ROADMAP.md` の該当行を `[x]` に更新し、簡潔な実装メモを追記する
   - `git add` と `git commit` は連結せず**別々の単独コマンド**で実行し、1本ごとに即コミットして休まず次の未着手ゲームへ進む

## 完了条件
- `ROADMAP.md` の 01〜30 がすべて `[x]` になり、全30本と `images/` スクリーンショットが検証済みかつ1本ごとにコミットされていること
- `git status` がクリーンであること
```

---

## 3. 連続制作を高速化するパイプラインのコツ
- **並列オーバーラップ**: 「ゲームNの `verify_game.ps1` ＋スクショ撮影（バックグラウンド実行）」を走らせている間に、「ゲームN+1の設計と `write_file`」を進めることで、待ち時間ゼロで30本を駆け抜けられます。
- **タイトル＆プレイ中チェックの徹底**: タイトル画面（`-f 60`）と実プレイ画面（`-f 180 -g`）の2枚を見ることで、「タイトルでの文字はみ出し」と「プレイ中のHUD被り・背景サイズ不整合」を確実に潰せます。

---

## 4. Phase 2 (31–40) 実行用 `/goal` プロンプトテンプレート

Phase 2（および今後の Phase N）を新規セッションで実行する際は、以下をコピーして投入してください（Phase 3 以降は Phase 番号・連番範囲・フィードバックファイル名のみ書き換えて流用できます）。

```markdown
/goal このリポジトリの `ROADMAP.md` にある `Phase2 (31-40) 2026-11-24` の未着手ゲーム（`[ ]`）を順番に、全10本（No.31〜40）すべて完成するまで連続で制作・検証・コミットし、最後にショーケース追記と Phase 2 フィードバック整理まで完了させてください。

## 事前確認
作業開始前に `AGENTS.md`、`ROADMAP.md`、`docs/api.md`、`docs/mrubyedge_api.md`、`docs/engine_feedback.md`、`.agents/skills/usakame-sprite/SKILL.md` を確認してください。
また、続編DXタイトル（34, 36, 40）を制作する際は対応する前作（05, 10, 26）を参照し、新APIによって見た目と遊び心地が劇的に進化したことがユーザーから一目で分かる仕上がりにしてください。

## Phase 2 の重視ポイント（新APIの積極活用）
`docs/engine_feedback.md` の対応で追加・改善された以下の機能を、各ゲームの核となる演出・ゲーム性に積極的に組み込んでください：
- **`alpha` 半透明描画**: 図形・テキスト・スプライト（`spr` / `spr_ext` / `spr_clip` / `blt`）の残像、ゴースト、フェード、ガラス混色、視界表現
- **`blend(:normal / :add / :mul)`**: `:add` によるレーザー・花火・ネオン・魔法の加算発光、`:mul` による深海・暗闇・影の表現（描画後は必ず `blend(:normal)` に戻す）
- **太線・連続線・塗りつぶし多角形**: `line(..., width:)`、`polyline`、`trifill`、`quadfill`、`polygonfill` による3Dポリゴン描画、滑らかな路面、視界コーン、軌跡スラッシュ、ステンドグラス表現
- **高解像度 `bg()` 自動スケーリング**: `320x240` / `480x270` / `640x480` 解像度での `bg()` 自動フィット（`fit: :auto` / `:screen` 等）とワイド・高精細UIの活用

## 各ゲームの制作ルール
1. **品質目標（どちらか必須、理想は両方）**:
   - 目標1: ユーザーが実際に少なくとも5分は夢中で遊べ、繰り返しても楽しいゲーム性（手触り・成長/スコア・リプレイ性）
   - 目標2: SNS などでシェアして喜ばれそうな見た目（新APIの光/半透明/多角形演出・カスタムパレット高品質ドット絵・無音でも気持ちいいヒットストップ/シェイク/フラッシュ）
2. **絶対制約**:
   - **1ファイル完結**（`games/XX_<name>.rb`、外部画像不使用）
   - **基本API + `bg()` + スプライト + キーボード/マウス入力のみ**を使用
   - **タイルマップ（`map`, `mget`, `mset`, `mdel`, `mclear`, `@MAP`）とサウンド（`sfx`, `music`, `play`, `tone`, `@SFX`, `@MUSIC`）は一切使用しない**
   - **mrubyedge 鉄則**:
     - 未実装メソッド（`sample`, `shuffle`, `reverse`, `delete`, `key?`, `include?` on Hash, `fetch`, `dig`, `gsub`, `sub`, `even?`, `odd?`, `upto`, `downto`, `index`, `fill`）を使わない（`Array#map` と `Float - Integer` は対応済みだが、引き続き安全側に書く）
     - `.each` ループ中に同じ配列へ `<<` しない（一時配列に溜めてループ後に追加する）
     - `attr_accessor` / `attr_reader` は1行6シンボル以下、Ruby側メソッドへのハッシュ引数は明示的 `({ ... })`、クラス継承/`super` 不使用
     - `camera()`・`clip()`・`blend(:normal)` は HUD 描画前に必ずリセットする
3. **1本完成ごとの必須検証＆自動コミット（許可待ちせず自動進行）**:
   - `pwsh -NoProfile -File scripts/verify_game.ps1 games/<file>.rb` を実行し、終了コード 0 を確認する
   - `uk run games/<file>.rb -s tmp/preview.png -f 60`（タイトル確認用）と `uk run games/<file>.rb -s images/<file>.png -f 180 -g`（ギャラリー保存用）でスクリーンショットを撮影し、`read_file` で目視確認する（UI被り・文字切れ・スプライト崩れ・ブレンド戻し忘れがあれば修正して再検証）
   - `ROADMAP.md` の該当行を `[x]` に更新し、簡潔な実装メモを追記する
   - `git add` と `git commit` は連結せず**別々の単独コマンド**で実行し、1本ごとに即コミット（`feat(games): add <file> - <Title>`）して休まず次の未着手ゲームへ進む

## 全10本完了後の仕上げタスク
1. **`docs/games_showcase.md` の更新**:
   - 末尾に `## Phase2 (31-40) 2026-11-24` 見出しを追加し、No.31〜40 の全10本について画像リンク（`../images/<file>.png`）、おすすめポイント、新API活用の工夫点を追記する。
2. **`docs/engine_feedback_phase2.md` の新規作成**:
   - Phase 2（31〜40）の制作を通して判明した、新API（`alpha` / `blend` / `polygonfill` / 太線 / 高解像度 `bg()` 等）の使用感・良かった点・新たに踏んだ制約や改善要望を `docs/engine_feedback.md` と同等の構成でまとめる。
3. **仕上げのコミット**:
   - `docs/games_showcase.md` と `docs/engine_feedback_phase2.md` をコミットする（`git add` と `git commit` は単独コマンドで実行）。

## 完了条件
- `ROADMAP.md` の `Phase2 (31-40)`（No.31〜40）がすべて `[x]` になり、全10本と `images/31_*.png`〜`images/40_*.png` が検証済みかつ1本ごとにコミットされていること
- `docs/games_showcase.md` に `Phase2 (31-40)` が追記され、`docs/engine_feedback_phase2.md` が作成・コミットされていること
- `git status` がクリーンであること
```

---

## 5. Phase 3 (41–50) 実行用 `/goal` プロンプトテンプレート

新規セッションを開き、以下のブロックをそのままコピー＆ペーストして送信してください。

```markdown
/goal このリポジトリの `ROADMAP.md` にある `Phase3 (41-50) 2026-11-26` の未着手ゲーム（`[ ]`）を順番に、全10本（No.41〜50）すべて完成するまで連続で制作・検証・コミットし、最後にショーケース追記と Phase 3 フィードバック作成まで完了させてください。

## 事前確認
作業開始前に `AGENTS.md`、`ROADMAP.md`、`docs/api.md`、`docs/mrubyedge_api.md`、`docs/engine_feedback_phase2.md`、`.agents/skills/usakame-sprite/SKILL.md` を確認してください。
また、続編DXタイトル（46, 48）を制作する際は対応する前作（`games/22_falling_sand_lab.rb`, `games/18_fishing_twilight.rb`）を参照し、新APIによって見た目・遊び心地・やり込み性が劇的に進化したことがユーザーから一目で分かる仕上がりにしてください。

## Phase 3 の重視ポイント（新APIの積極活用）
`docs/engine_feedback_phase2.md` の対応で追加・改善された以下の機能を、`ROADMAP.md` の設計メモに沿って各ゲームの核となる遊び・演出に組み込んでください：
- **永続セーブデータ API**: `config(save_id: "...", save_salt: "...")` を必ず設定（`uk save-init` 相当の固有ID＋ソルト）し、`save_set` / `save_get` / `save_has?` / `save_clear` でハイスコア・クリア状況・図鑑・恒久強化・工場/作品データ（`Array` / `Hash`）を永続保存する
- **オフスクリーン `:gpu` サーフェス ＆ `blend(:erase)`**: `create_surface(w, h, :gpu)`、`render_to`、`cls(nil)` / `cls(col, alpha)`、`blend(:erase)`、`draw_surface` による白飛びしない複数光源2Dライトマップや、配列肥大なしで戦場・コートに残る永続デカール表現
- **`:pixel` サーフェス ＆ 破壊可能地形クエリ API**: `create_surface(w, h, :pixel)` と `pget` / `surface_pget` / `surface_pset` / `surface_swap` / `surface_solid?` / `surface_circle_solid?` / `surface_raycast` / `surface_count` によるクレーター破壊地形、高速落ち砂反応、インク塗り面積のリアルタイム集計
- **テキスト計測・整列・装飾**: `text_width` / `text_height` および位置引数 `print_text(text, x, y, col, size, alpha, align, outline, shadow)`（`:center` / `:right` 整列、4近傍 `outline` フチ取り、`shadow` 影文字、解像度非依存デフォルト `8`px）による視認性の高いUI
- **入力の拡充**: `btn(id, player)` / `btnp(id, player)`（1P＋CPUモードを基本としつつ `player = 1` の2Pキーボード `IJKL+U/O`・ゲームパッド対戦/協力にも対応）、`gamepad_count`、`mouse_wheel`、`show_cursor(false)`

## 各ゲームの制作ルール
1. **品質目標（どちらか必須、理想は両方）**:
   - 目標1: ユーザーが実際に少なくとも5分は夢中で遊べ、セーブ機能も含めて繰り返し遊んで楽しいゲーム性
   - 目標2: SNS などでシェアして喜ばれそうな見た目（ライトマップ・破壊地形・永続デカール・カスタムパレット高品質ドット絵・気持ちいいヒットストップ/シェイク/フラッシュ）
2. **パラメータのハッシュテーブル管理（Phase 3 必須設計ルール）**:
   - ゲームバランス調整値（速度・重力・クールタイム・制限時間・UI寸法等）やエンティティ仕様（武器・敵・設備・元素・魚・ボス等）は、定数（`FOO = 1`）や `initialize` 内のマジックナンバーに散らさず、**スクリプト冒頭の浅いハッシュテーブル（`$cfg = { ... }`、`$weapons = { ... }` 等、1〜2階層）に集約**すること（`uk run` のライブ・ホットリロードで保存即反映できるようにするため）。
   - mrubyedge では `Hash#dig` / `fetch` / `key?` が未実装のため使わないこと（`has_key?` と浅い階層を使う）。
   - 毎フレーム数千回回る最内側 `while` ループ（落ち砂や大量パーティクル等）では、ループ直前で `grav = $cfg[:gravity]` のようにローカル変数へ1回キャッシュして検索コストを避けること。
3. **絶対制約**:
   - **1ファイル完結**（`games/XX_<name>.rb`、外部画像不使用）
   - **基本API（描画・Surface・Save・Text・入力）+ `bg()` + スプライトのみ**を使用
   - **タイルマップ（`map`, `mget`, `mset`, `mdel`, `mclear`, `@MAP`）とサウンド（`sfx`, `music`, `play`, `tone`, `@SFX`, `@MUSIC`）は一切使用しない**
   - **mrubyedge ＆ 描画API鉄則**:
     - 描画API（`line`, `rect`, `print_text` 等）はキーワード引数非対応のため、すべて**位置引数**で渡す（`bg()`・`run()`・`config()`・`draw_surface()` のみキーワード引数可）
     - 未実装メソッド（`sample`, `shuffle`, `reverse`, `delete`, `key?`, `include?`, `fetch`, `dig`, `gsub`, `sub`, `even?`, `odd?`, `upto`, `downto`, `fill`）およびブロック引数の配列展開（`each do |a, b|`）を使わない（`Array#index` は使用可）
     - `.each` ループ中に同じ配列へ `<<` しない、`attr_accessor` / `attr_reader` は1行6シンボル以下、Ruby側メソッドへのハッシュ引数は明示的 `({ ... })`、クラス継承/`super` 不使用
     - `set_target(nil)`（または `render_to` ブロック）・`camera()`・`clip()`・`blend(:normal)` は HUD 描画前に必ずリセットする
4. **1本完成ごとの必須検証＆自動コミット（許可待ちせず自動進行）**:
   - `pwsh -NoProfile -File scripts/verify_game.ps1 games/<file>.rb` を実行し、終了コード 0 を確認する
   - `uk run games/<file>.rb -s tmp/preview.png -f 60`（タイトル確認用）と `uk run games/<file>.rb -s images/<file>.png -f 180 -g`（ギャラリー保存用）でスクリーンショットを撮影し、`read_file` で目視確認する（UI被り・文字切れ・スプライト崩れ・ブレンド/ターゲット戻し忘れがあれば修正して再検証）
   - `ROADMAP.md` の該当行を `[x]` に更新し、簡潔な実装メモを追記する
   - `git add` と `git commit` は連結せず**別々の単独コマンド**で実行し、1本ごとに即コミット（`feat(games): add <file> - <Title>`）して休まず次の未着手ゲームへ進む

## 全10本完了後の仕上げタスク
1. **`docs/games_showcase.md` の更新**:
   - 末尾に `## Phase3 (41-50) 2026-11-26` 見出しを追加し、No.41〜50 の全10本について画像リンク（`../images/<file>.png`）、おすすめポイント、新API＆ハッシュ設計の工夫点を追記する。
2. **`docs/engine_feedback_phase3.md` の新規作成**:
   - Phase 3（41〜50）の制作を通して判明した、新API（`save_set`、`:gpu`/`:pixel` サーフェス、`blend(:erase)`、`text_width`/`outline`、2P/ホイール/`show_cursor`、ハッシュテーブルによるホットリロード調整等）の使用感・良かった点・新たに踏んだ制約や今後の改善要望を `docs/engine_feedback_phase2.md` と同等の構成でまとめる。
3. **仕上げのコミット**:
   - `docs/games_showcase.md` と `docs/engine_feedback_phase3.md` をコミットする（`git add` と `git commit` は単独コマンドで実行）。

## 完了条件
- `ROADMAP.md` の `Phase3 (41-50) 2026-11-26`（No.41〜50）がすべて `[x]` になり、全10本と `images/41_*.png`〜`images/50_*.png` が検証済みかつ1本ごとにコミットされていること
- `docs/games_showcase.md` に `Phase3 (41-50) 2026-11-26` が追記され、`docs/engine_feedback_phase3.md` が作成・コミットされていること
- `git status` がクリーンであること
```
