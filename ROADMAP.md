# Usakame 30 Games Roadmap

全30本（6カテゴリ × 5本）・ネタ被りなし・1ファイル完結・基本API + `bg()` + スプライトのみの制作台帳です。
1本完成するごとに `[x]` へ更新し、直ちにコミットします。

---

## カテゴリ A: ハイテンポ・アーケードアクション (01–05)

| No. | Status | File | タイトル & コンセプト | 解像度 | 流用・設計メモ |
| :---: | :---: | :--- | :--- | :---: | :--- |
| 01 | [x] | `games/01_grapple_ascent.rb` | **GRAPPLE ASCENT** — 振り子フックショットで溶岩から逃げ切る縦登りアクション | 256x256 | `:cave` 溶岩tint, 振り子物理・ブーストアンカー・`EffectSystem` 実装 |
| 02 | [x] | `games/02_parry_dojo.rb` | **PARRY DOJO** — 月夜の竹林で四方の刃・矢を見切り居合斬りする1ボタン道場 | 256x256 | `:forest` 紺tint+満月, ジャスト見切り・弾き返し・奥義月光居合実装 |
| 03 | [x] | `games/03_gravity_flip_run.rb` | **GRAVITY FLIP RUN** — 床⇔天井の重力反転でネオン回廊を疾走するスピードラン | 256x256 | `:cyber`, 残像 `@PALETTE 11`・フェーズダッシュ・ドローン破壊実装 |
| 04 | [x] | `games/04_sky_juggler.rb` | **SKY JUGGLER** — 敵を落とさず空中お手玉コンボ＆フィーバーBG変貌アリーナ | 256x256 | `:sky`→`:cyber`, アッパー打ち上げ・ポゴ踏み・フィーバー変貌実装 |
| 05 | [x] | `games/05_drift_circuit.rb` | **DRIFT CIRCUIT** — タイヤ痕・火花・ゴースト再生付き見下ろしドリフトレース | 256x256 | `:training` 芝生tint, 回転 `spr_ext`・ドリフトブースト・ゴースト再生実装 |

## カテゴリ B: シューティング & 物理アクション (06–10)

| No. | Status | File | タイトル & コンセプト | 解像度 | 流用・設計メモ |
| :---: | :---: | :--- | :--- | :---: | :--- |
| 06 | [x] | `games/06_star_diver.rb` | **STAR DIVER** — 都市→山→空→宇宙→電脳へBG連続変化する3択ビルド縦STG | 256x256 | 5ゾーンBG変化・ボス撃破後3択アップグレード・ノヴァボム実装 |
| 07 | [x] | `games/07_tank_ricochet.rb` | **TANK RICOCHET** — 壁跳弾×予測線で敵戦車を撃ち抜くタクティカル戦車アリーナ | 256x256 | `:training`, 跳弾予測線・2回壁反射・4種アリーナ循環実装 |
| 08 | [x] | `games/08_comet_lasso.rb` | **COMET LASSO** — 回転投げ縄で小惑星や敵を振り回し連鎖爆破する物理アクション | 256x256 | `:space`, 投げ縄公転・投擲連鎖・UFO迎撃実装 |
| 09 | [x] | `games/09_pinball_cyber.rb` | **PINBALL CYBER** — マルチボール＆ネオンバンパー乱舞の1画面サイバーピンボール | 256x256 | `:cyber`, 4サブステップ物理・ドロップターゲット・マルチボール実装 |
| 10 | [x] | `games/10_submarine_sonar.rb` | **SUBMARINE SONAR** — 暗黒の深海でソナー波紋を放ち海獣を暴く魚雷バトル | 256x256 | `:cave` 深海青tint, ソナー照射発見・2倍クリティカル魚雷実装 |

## カテゴリ C: パズル・思考 & ローグライト戦略 (11–15)

| No. | Status | File | タイトル & コンセプト | 解像度 | 流用・設計メモ |
| :---: | :---: | :--- | :--- | :---: | :--- |
| 11 | [x] | `games/11_auto_chess_mini.rb` | **AUTO CHESS MINI** — 4×4盤面で3体合体進化＆シナジーを組むミニ・オートバトラー | 256x256 | マウス＋キー両対応, 3体自動★進化・ショップリロール・オートバトル実装 |
| 12 | [x] | `games/12_tower_defense_orbit.rb` | **ORBIT TD** — 中央惑星を守る全方位リング軌道タワーディフェンス | 256x256 | `:space`, 2重軌道12スロット・レーザー/冷凍/砲台3種＆強化実装 |
| 13 | [x] | `games/13_sliding_knight.rb` | **SLIDING KNIGHT** — 止まらない氷床で敵を一掃するローグライト詰めタクティクス | 256x256 | `:mountain` 氷tint, 8x8氷盤面・連続スライディングコンボ・旋風斬り実装 |
| 14 | [x] | `games/14_alchemy_merge.rb` | **ALCHEMY MERGE** — フラスコ内で魔法玉が転がり合体進化するスイカ風マージパズル | 256x256 | `:cave`, 4サブステップ円衝突・9段階合体進化実装 |
| 15 | [x] | `games/15_dice_dungeon.rb` | **DICE DUNGEON** — 出目を装備スロットにはめて戦うダイス構築ローグライト | 256x256 | `:cave`, ダイス3個×剣盾杖スロット・行動予兆・マウス/キー対応 |

## カテゴリ D: スポーツ・ミニゲーム & タイムアタック (16–20)

| No. | Status | File | タイトル & コンセプト | 解像度 | 流用・設計メモ |
| :---: | :---: | :--- | :--- | :---: | :--- |
| 16 | [x] | `games/16_neon_air_hockey.rb` | **NEON AIR HOCKEY** — マウス操作×超高速パック＆チャージ弾のネオン・エアホッケー | 256x256 | `:cyber`, CPU4段階・4サブステップ物理・パワースマッシュ実装 |
| 17 | [x] | `games/17_golf_galaxy.rb` | **GOLF GALAXY** — 惑星の万有引力で弾道が曲がる宇宙物理パターゴルフ | 256x256 | `:space`, 万有引力軌道予測線＋全9ホール実装 |
| 18 | [x] | `games/18_fishing_twilight.rb` | **FISHING TWILIGHT** — 夕焼け湖畔で伝説魚を釣り上げる図鑑コンプ釣りゲーム | 256x256 | `:mountain` 夕焼けtint+水面反射, 8種魚図鑑＆リールゲージ実装 |
| 19 | [x] | `games/19_sushi_conveyor.rb` | **SUSHI CONVEYOR** — 注文通りにネタを握って皿を飛ばす爆速回転寿司アクション | 256x256 | `:training` 暖色tint, 4種寿司ドット絵・飛行皿・コンボ実装 |
| 20 | [x] | `games/20_rhythm_smith.rb` | **RHYTHM SMITH** — 視覚リング目押しで赤熱の剣を叩き名剣を鍛える鍛冶クラフト | 256x256 | `:cave` 鍛冶炉tint, 5種名剣鍛造・収束リング目押し・ランク判定実装 |

## カテゴリ E: シミュレーション・クリッカー & 育成 (21–25)

| No. | Status | File | タイトル & コンセプト | 解像度 | 流用・設計メモ |
| :---: | :---: | :--- | :--- | :---: | :--- |
| 21 | [x] | `games/21_pixel_aquarium.rb` | **PIXEL AQUARIUM** — 熱帯魚・クラゲが泳ぎ繁殖する癒やしのインタラクティブ水槽 | 256x256 | `:cave` 水中tint, 水草揺らぎ・エサやり繁殖・レア種購入実装 |
| 22 | [x] | `games/22_falling_sand_lab.rb` | **FALLING SAND LAB** — 砂・水・火・木・爆薬・酸が連鎖反応する落ち砂物理ラボ | 256x256 | 64x54セルオートマトン・8素材(砂/水/木/火/TNT/酸/石/消去)実装 |
| 23 | [x] | `games/23_dungeon_shopkeeper.rb` | **DUNGEON SHOPKEEPER** — 勇者相手の値付け＆仕入れで商会を育てるアイテム屋経営 | 640x480 | 640x480日本語UI・3段階値付け交渉・卸売市場仕入れ実装 |
| 24 | [x] | `games/24_colony_orbit.rb` | **COLONY ORBIT** — 小惑星採掘＆ドローン自動化の宇宙コロニー・クリッカー | 256x256 | `:space`, ドローン周回・自動レーザー衛星・精製倍率強化実装 |
| 25 | [x] | `games/25_monster_breeder.rb` | **MONSTER BREEDER** — 特訓・進化分岐(8種)でドット絵相棒を育て大会制覇を目指す育成ゲー | 256x256 | `:forest`/`:city`, 8種進化分岐・4大会制覇オートバトル実装 |

## カテゴリ F: SNS映え特化・アート & 実験的トイ (26–30)

| No. | Status | File | タイトル & コンセプト | 解像度 | 流用・設計メモ |
| :---: | :---: | :--- | :--- | :---: | :--- |
| 26 | [x] | `games/26_fireworks_director.rb` | **FIREWORKS DIRECTOR** — 柳・菊・冠菊・ハート型花火を連発できる夜空の花火師トイ | 256x256 | `:city` 夜景+水面反射, 5種花火(菊/柳/ハート/冠菊/連発)・オート大会実装 |
| 27 | [x] | `games/27_kaleidoscope_bloom.rb` | **KALEIDOSCOPE BLOOM** — 8〜16軸対称で光の花が咲くジェネラティブ万華鏡アート | 256x256 | `:space`, 8/12/16軸対称・4パレット・マウス/自動ブルーム実装 |
| 28 | [x] | `games/28_world_glider.rb` | **WORLD GLIDER** — 内蔵全BG世界を風に乗って輪くぐり滑空するチル＆スコアデモ | 256x256 | 全8種BG連続変化・輪くぐりコンボ・放置オートパイロット実装 |
| 29 | [x] | `games/29_retro_synth_visualizer.rb` | **RETRO SYNTH VISUALIZER** — 3Dワープトンネル＆プラズマ波を操るデモシーンVJトイ | 256x256 | 3Dトンネル/3Dワイヤー立方体/シンセ波/星渦の4モードVJ実装 |
| 30 | [x] | `games/30_usakame_museum.rb` | **USAKAME MUSEUM** — 30本完結記念・過去作スプライトが並ぶ歩けるインタラクティブ展示室 | 256x256 | 6カテゴリ代表スプライト展示・祝砲クラッカー・全訪問演出実装 |

---

## Phase2 (31-40) 2026-11-24

`docs/engine_feedback.md` のエンジン改善（`alpha` 半透明、`blend(:add / :mul)`、太線 `line(..., width:)` / `polyline`、塗りつぶし多角形 `trifill` / `quadfill` / `polygonfill`、高解像度 `bg()` 自動スケーリング、`Float - Integer` 修正）を最大限に活かす10本（完全新作7本＋新機能による劇的進化DX続編3本）。
全10本完了後、`docs/games_showcase.md` への追記および `docs/engine_feedback_phase2.md` への振り返り整理を行う。

| No. | Status | File | タイトル & コンセプト | 解像度 | 活用する新機能・設計メモ |
| :---: | :---: | :--- | :--- | :---: | :--- |
| 31 | [x] | `games/31_prism_laser.rb` | **PRISM LASER** — 鏡とプリズムでRGBレーザーを混色・誘導する光学パズル（全12面） | 256x256 | `@PALETTE 1` + `blend(:add)` + 太線 `line` でRGB加算混色、`trifill`/`polygonfill` 半透明プリズム、全12面実装 |
| 32 | [x] | `games/32_star_trench.rb` | **STAR TRENCH 3D** — 面塗り3Dポリゴンの渓谷と戦艦を撃ち抜くレールシューター | 320x240 | `quadfill`/`trifill` Zソート3Dポリゴン渓谷・敵・ドレッドノート戦艦、`blend(:add)` レーザー＆ホーミングミサイル実装 |
| 33 | [x] | `games/33_shadow_thief.rb` | **SHADOW THIEF** — 警備員の視界コーンとサーチライトを影に潜んで抜けるステルス潜入 | 320x240 | `blend(:mul)` 夜の暗闇、`polygonfill` レイキャスト壁遮蔽視界コーン、`@SPRITE` 怪盗・警備員・宝石、全5面実装 |
| 34 | [x] | `games/34_drift_circuit_dx.rb` | **DRIFT CIRCUIT DX** — 【05進化版】太線路面・半透明ゴースト・ナイトレース対応の本格ドリフト | 320x240 | `polyline` 滑らか太線路面、`spr_ext(..., alpha: 0.45)` 半透明ゴースト、`blend(:mul)`+`trifill` ナイトヘッドライト、3コース＆ライバル車実装 |
| 35 | [x] | `games/35_neon_slash.rb` | **NEON SLASH** — 光の斬撃軌跡で敵と弾を真っ二つに両断するハイスピード剣戟アクション | 256x256 | `polyline` + `blend(:add)` 残光スラッシュ、`trifill` 両断ポリゴン破片、`spr(..., alpha:)` 居合残像、奥義閃光乱舞実装 |
| 36 | [x] | `games/36_submarine_sonar_2.rb` | **ABYSS SONAR II** — 【10進化版】乗算の漆黒深海をライトとソナー波紋で照らす深海探索＆ボス戦 | 320x240 | `blend(:mul)` 漆黒深海、`trifill`+`blend(:add)` サーチライト、`alpha` フェードソナー＆32x32クラーケン戦実装 |
| 37 | [x] | `games/37_slingshot_fortress.rb` | **SLINGSHOT FORTRESS** — 3種砲弾で物理城砦を崩落させるワイド画面カタパルト破壊パズル（全8面） | 480x270 | 480x270 `bg(:mountain)` 自動フィット、`quadfill` 回転ブロック物理＆半透明ガラス、`polyline` 弾道、`blend(:add)` 爆風、全8面実装 |
| 38 | [x] | `games/38_arcana_deck.rb` | **ARCANA DECK** — 日本語UI×カード発光演出で戦うデッキ構築ローグライトRPG | 640x480 | `640x480` `bg(:cave)` 自動フィット、東雲16px日本語UI、`blend(:add)` カード発光＆魔法演出、全8階層実装 |
| 39 | [x] | `games/39_vitrail_craft.rb` | **VITRAIL CRAFT** — 多角形の色ガラスを重ねて光の模様を創るステンドグラス幾何学パズル（全10図柄＋フリー） | 256x256 | `polygonfill`+`alpha` 色ガラス混色＆鉛枠、`quadfill`+`blend(:add)` 大聖堂光条シャワー、全10図柄＋フリーアート実装 |
| 40 | [ ] | `games/40_fireworks_symphony.rb` | **FIREWORKS SYMPHONY DX** — 【26進化版】加算発光・滑らか減衰・大会演出を備えたワイド夜空の花火師 | 480x270 | `blend(:add)` 光の重なり発光、`alpha` フェードアウト、`polyline` 柳トレイル、ワイド夜景＆水面反射、大会プログラムモード |
