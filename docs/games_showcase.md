# Usakame 30 Games — 工夫点・おすすめポイントまとめ

`ROADMAP.md` に沿って制作した全30タイトルの遊びどころ、技術的な工夫点、スクリーンショット映えポイントをカテゴリ別にまとめています。

---

## カテゴリ A: ハイテンポ・アーケードアクション (01–05)

### 01. GRAPPLE ASCENT (`games/01_grapple_ascent.rb`)
![01_grapple_ascent](../images/01_grapple_ascent.png)
- **おすすめポイント**: 1ボタン（`Z` / クリック）で最も有利な上方アンカーを自動ターゲットし、振り子物理の遠心力を活かして溶岩から逃げ切る爽快な縦登りアクション。
- **工夫点**: 黄色い「ブーストアンカー」に触れた瞬間の自動大ジャンプ＋ヒットストップ、速度に応じた残像トレイル、溶岩から立ち昇る火花パーティクル、シェイク時の `:cave` 背景スケーリング（`scale: 1.04`）による黒隙間防止。

### 02. PARRY DOJO (`games/02_parry_dojo.rb`)
![02_parry_dojo](../images/02_parry_dojo.png)
- **おすすめポイント**: 4方向から飛来する矢・手裏剣・忍びをタイミング良く斬り払う1ボタン居合道場。ジャスト見切りで弾を跳ね返し、背後の敵を連鎖撃破できる。
- **工夫点**: 満月＋`:forest` 紺ティント＋舞い散る桜吹雪の雰囲気作り、ジャスト判定時の4フレームヒットストップ＆シアンフラッシュ、ゲージ100%で発動する全体必殺技「月光居合」。

### 03. GRAVITY FLIP RUN (`games/03_gravity_flip_run.rb`)
![03_gravity_flip_run](../images/03_gravity_flip_run.png)
- **おすすめポイント**: 床と天井を瞬時に反転させながらネオン回廊を疾走するスピードラン。フェーズダッシュで空中ドローンを体当たり破壊できる攻めの爽快感。
- **工夫点**: `@PALETTE 11` を使ったシアン残像トレイル、コヨーテタイム＆先行入力バッファによるキレの良い反転操作、距離に応じて変化する `:cyber` 背景ティント。

### 04. SKY JUGGLER (`games/04_sky_juggler.rb`)
![04_sky_juggler](../images/04_sky_juggler.png)
- **おすすめポイント**: 降ってくる敵を落とさずアッパー＆ポゴ踏みで空中お手玉し続けるコンボアクション。
- **工夫点**: 10コンボ達成で背景が `:sky` からサイケデリックな `:cyber` へ変貌する「FEVER MODE」、アッパーヒット時の2段ジャンプ回数回復による滞空ループ。

### 05. DRIFT CIRCUIT (`games/05_drift_circuit.rb`)
![05_drift_circuit](../images/05_drift_circuit.png)
- **おすすめポイント**: タイヤ痕とドリフト火花を散らしながら3周タイムアタックに挑む見下ろしレース。ベストラップを「シアン色のゴーストカー」として再生できる。
- **工夫点**: 進行方向と車体向きの横滑りグリップ物理、ドリフト溜め時間に応じた青→橙→ピンクの火花と解放時ターボ加速、赤白縁石とチェッカーフラッグの視認性。

---

## カテゴリ B: シューティング & 物理アクション (06–10)

### 06. STAR DIVER (`games/06_star_diver.rb`)
![06_star_diver](../images/06_star_diver.png)
- **おすすめポイント**: 都市夜景→山脈→青空→深宇宙→電脳空間へと連続的に背景が移り変わる、3択ビルド型の縦スクロールSTG。
- **工夫点**: ゾーンボス撃破ごとに提示される3択アップグレード（拡散弾・連射・ウィングマン・攻撃力・回復・ノヴァボム）と、`Array` ベースの重複なし抽選（Fisher-Yates）。

### 07. TANK RICOCHET (`games/07_tank_ricochet.rb`)
![07_tank_ricochet](../images/07_tank_ricochet.png)
- **おすすめポイント**: 壁で最大2回跳弾する砲弾とリアルタイムの反射予測線で、障害物の陰にいる敵戦車を狙撃するタクティカル戦車バトル。
- **工夫点**: `compute_ricochet_pts` による1バウンド目までのレーザー予測線、マウスエイムとキーボード自動追尾のハイブリッド操作、青スナイパー戦車との駆け引き。

### 08. COMET LASSO (`games/08_comet_lasso.rb`)
![08_comet_lasso](../images/08_comet_lasso.png)
- **おすすめポイント**: 近くの小惑星をエネルギー投げ縄で捕獲し、自分の周囲で高速回転させてからUFO群へ投げ飛ばす物理アクション。
- **工夫点**: 投げ飛ばした小惑星が複数のUFOを貫通・連鎖爆破した際の `CHAIN x2, x3...` スコア倍率とヒットストップ＆衝撃波リング。

### 09. PINBALL CYBER (`games/09_pinball_cyber.rb`)
![09_pinball_cyber](../images/09_pinball_cyber.png)
- **おすすめポイント**: ネオンバンパーが弾け、上部3つのドロップターゲットを全点灯させると最大3球の「マルチボール」が炸裂するサイバーピンボール。
- **工夫点**: 4サブステップ物理と線分距離計算によるフリッパーの正確な弾き返し（フリッパー上昇中のキック加速対応）とテーブルナッジ機能。

### 10. SUBMARINE SONAR (`games/10_submarine_sonar.rb`)
![10_submarine_sonar](../images/10_submarine_sonar.png)
- **おすすめポイント**: 暗黒の深海でソナー波紋を放ち、闇に潜むアンコウや巨大イカ、機雷を暴き出して魚雷を撃ち込む緊張感ある探索バトル。
- **工夫点**: ソナー波紋が触れた瞬間だけ敵スプライトとロックオンリングが浮かび上がる視界演出と、発見状態の敵に魚雷を当てた際の「2倍クリティカル」仕様。

---

## カテゴリ C: パズル・思考 & ローグライト戦略 (11–15)

### 11. AUTO CHESS MINI (`games/11_auto_chess_mini.rb`)
![11_auto_chess_mini](../images/11_auto_chess_mini.png)
- **おすすめポイント**: 4×4マスのお手軽盤面で、同種ユニットを3体集めて自動★進化させながらウェーブを勝ち抜くミニ・オートバトラー。
- **工夫点**: 購入時に空きマスへ自動配置＆3体揃った瞬間の連鎖合体進化、同クラス2種によるシナジーバフ、マウスとキーボード双方での直感的な配置入替。

### 12. ORBIT TD (`games/12_tower_defense_orbit.rb`)
![12_tower_defense_orbit](../images/12_tower_defense_orbit.png)
- **おすすめポイント**: 中央の母星を取り囲む2重リング（計12スロット）に、レーザー・範囲冷凍・範囲砲台の3種タレットを配置・強化する全方位TD。
- **工夫点**: 全360度から迫る敵に対する軌道リング配置の戦略性と、FROSTの拡大冷凍リング・CANNONの着弾爆風など視認性の高い攻撃エフェクト。

### 13. SLIDING KNIGHT (`games/13_sliding_knight.rb`)
![13_sliding_knight](../images/13_sliding_knight.png)
- **おすすめポイント**: 氷の床を壁にぶつかるまで一直線に滑り抜き、進路上の敵を一撃で斬り伏せるローグライト詰めタクティクス。
- **工夫点**: 1回のスライドで複数体を斬るほど倍率が伸びる連続コンボと、詰み防止＆緊急回避用の周囲4マス攻撃「旋風斬り（NOVA）」。

### 14. ALCHEMY MERGE (`games/14_alchemy_merge.rb`)
![14_alchemy_merge](../images/14_alchemy_merge.png)
- **おすすめポイント**: フラスコの中で転がり跳ねる9段階の魔法玉を合体進化させるスイカ風マージパズル。
- **工夫点**: 4サブステップの円同士反発物理による自然な転がり挙動、合体時の衝撃波＆ポップアップ演出、次の玉（NEXT）表示と危険ライン警告。

### 15. DICE DUNGEON (`games/15_dice_dungeon.rb`)
![15_dice_dungeon](../images/15_dice_dungeon.png)
- **おすすめポイント**: 毎ターン振られる3つのダイスを「剣（攻撃）」「盾（防御）」「杖（奇数限定2倍魔法）」のスロットに割り振って戦うダイス構築RPG。
- **工夫点**: 敵の「次の行動予兆（INTENT: ATK X）」を見ながら防御と攻撃を配分する思考性と、6の目でのクリティカル＆階層突破時のHP回復・攻撃力成長。

---

## カテゴリ D: スポーツ・ミニゲーム & タイムアタック (16–20)

### 16. NEON AIR HOCKEY (`games/16_neon_air_hockey.rb`)
![16_neon_air_hockey](../images/16_neon_air_hockey.png)
- **おすすめポイント**: マウス操作で直感的にパックを弾き、タイミング良くクリック/Zで超高速「パワースマッシュ」を叩き込める4段階CPUトーナメント。
- **工夫点**: 4サブステップ物理による高速パックの壁抜け防止、残像トレイル、ゴール時の大量火花とスクリーンシェイク。

### 17. GOLF GALAXY (`games/17_golf_galaxy.rb`)
![17_golf_galaxy](../images/17_golf_galaxy.png)
- **おすすめポイント**: 惑星の万有引力で曲がる弾道を予測線で見極めながら、全9ホールのワープカップを狙う宇宙物理パターゴルフ。
- **工夫点**: 各惑星の重力圏リング表示と、リアルタイム重力計算をそのまま42ステップ先読みして描画する「曲がる軌道予測線」。

### 18. FISHING TWILIGHT (`games/18_fishing_twilight.rb`)
![18_fishing_twilight](../images/18_fishing_twilight.png)
- **おすすめポイント**: 夕暮れの湖畔で8種類の魚（伝説の LAKE KING まで）を釣り上げ、図鑑コンプリートを目指す癒やし＆駆け引き釣りゲーム。
- **工夫点**: 夕日の水面反射アニメーション、魚影の回遊、引きの強さが種族ごとに異なるゲージ制リールバトルと `[X]` でいつでも開ける魚図鑑。

### 19. SUSHI CONVEYOR (`games/19_sushi_conveyor.rb`)
![19_sushi_conveyor](../images/19_sushi_conveyor.png)
- **おすすめポイント**: 4人の客の吹き出し注文を見て、マグロ・サーモン・玉子・エビを爆速で握って皿を飛ばす回転寿司アクション。
- **工夫点**: 16×16ドット絵で描いた4種の寿司ネタと回転ベルト演出、同じネタを待つ客の中で「最も怒りゲージが迫っている客」へ自動優先配達する快適な操作感。

### 20. RHYTHM SMITH (`games/20_rhythm_smith.rb`)
![20_rhythm_smith](../images/20_rhythm_smith.png)
- **おすすめポイント**: 収束するタイミングリングが金床に重なる瞬間にハンマーを振り下ろし、5段階の名剣を鍛え上げる鍛冶リズムクラフト。
- **工夫点**: PERFECT時の火花シャワー＋画面フラッシュ＋打撃シェイクによる無音でも伝わる気持ちいい打撃感と、品質スコアに応じた `S/A/B/C` ランク判定。

---

## カテゴリ E: シミュレーション・クリッカー & 育成 (21–25)

### 21. PIXEL AQUARIUM (`games/21_pixel_aquarium.rb`)
![21_pixel_aquarium](../images/21_pixel_aquarium.png)
- **おすすめポイント**: カクレクマノミ・ネオンテトラ・クラゲ・レア魚が泳ぐ水槽にエサをまき、コインを回収して繁殖させる癒やし系アクアリウム。
- **工夫点**: 揺らぐ水草と立ち昇る気泡の環境演出、エサを3回食べると新世代が誕生する繁殖システム、放置でもコインが貯まるまったりサイクル。

### 22. FALLING SAND LAB (`games/22_falling_sand_lab.rb`)
![22_falling_sand_lab](../images/22_falling_sand_lab.png)
- **おすすめポイント**: 砂・水・木・火・TNT爆薬・酸・石の7素材＋消しゴムを自由に描き、連鎖反応を観察できる60FPS物理サンドボックス。
- **工夫点**: 64×54セル配列＋更新済みフラグによる高速セルオートマトン、水で火が消え・火で木とTNTが爆散し・酸が砂や木を溶かす化学反応ルール。

### 23. DUNGEON SHOPKEEPER (`games/23_dungeon_shopkeeper.rb`)
![23_dungeon_shopkeeper](../images/23_dungeon_shopkeeper.png)
- **おすすめポイント**: `640×480` VGA解像度・東雲16px日本語フォント採用の道具屋経営シム。10日間の営業で仕入れと強気/サービス値付けを駆使して最高資産を狙う。
- **工夫点**: PC-98風の二重枠ウィンドウUI、卸売市場の「特売！」相場変動、ショップ評判に応じて成功率が変化する3段階の値付け交渉。

### 24. COLONY ORBIT (`games/24_colony_orbit.rb`)
![24_colony_orbit](../images/24_colony_orbit.png)
- **おすすめポイント**: 巨大な結晶小惑星をクリックでレーザー採掘し、自動採掘ドローンやレーザー衛星、精製倍率を強化していく宇宙インクリメンタル。
- **工夫点**: 購入数に応じて小惑星周囲を実際に周回して自動レーザーを撃つドローン群と、着弾時の小惑星パルス拡大アニメーション。

### 25. MONSTER BREEDER (`games/25_monster_breeder.rb`)
![25_monster_breeder](../images/25_monster_breeder.png)
- **おすすめポイント**: ATK/DEF/SPDの特訓バランスによって全8種類のドット絵モンスターへ分岐進化し、4つの大会制覇を目指す育成ゲーム。
- **工夫点**: 幼体→第2段階3種→最終段階4種（均等育成での隠し形態 `COSMIC KING` 含む）の分岐設計と、特訓画面からそのまま突入するオートバトル大会。

---

## カテゴリ F: SNS映え特化・アート & 実験的トイ (26–30)

### 26. FIREWORKS DIRECTOR (`games/26_fireworks_director.rb`)
![26_fireworks_director](../images/26_fireworks_director.png)
- **おすすめポイント**: クリックした夜空の高さへ「菊」「柳」「ハート」「冠菊」「5連発（SALVO）」を打ち上げられる花火師トイ。
- **工夫点**: 都市夜景の下部に設けた港の水面に花火の火花が揺らぎながらリアルタイム反射する演出と、観賞用のオート花火大会モード。

### 27. KALEIDOSCOPE BLOOM (`games/27_kaleidoscope_bloom.rb`)
![27_kaleidoscope_bloom](../images/27_kaleidoscope_bloom.png)
- **おすすめポイント**: 8 / 12 / 16軸の放射対称ミラーリングで光の曼荼羅アートが咲くジェネラティブ万華鏡トイ。
- **工夫点**: リサージュ軌道による自動ブルームとマウス描画のシームレス切替、4種類のカラーテーマ（NEON / SAKURA / GOLD / ABYSS）切替。

### 28. WORLD GLIDER (`games/28_world_glider.rb`)
![28_world_glider](../images/28_world_glider.png)
- **おすすめポイント**: Usakame内蔵の全8種BG（`:sky`〜`:training`）を風に乗って順番に巡りながら、空中の輪をくぐってコンボを重ねるチル系グライダー。
- **工夫点**: 無操作3秒（または `X` キー）で輪を自動で追尾する「チル・オートパイロット」機能と、上下速度に応じた機体ピッチ回転。

### 29. RETRO SYNTH VISUALIZER (`games/29_retro_synth_visualizer.rb`)
![29_retro_synth_visualizer](../images/29_retro_synth_visualizer.png)
- **おすすめポイント**: 3Dワープトンネル、3Dワイヤーフレーム立方体、シンセウェーブ＋スペアナ、螺旋スター・ボルテックスの4モードを操るデモシーンVJトイ。
- **工夫点**: 3軸回転＋透視投影を1から組んだ3Dワイヤーキューブと、スピード調整・ビートドロップ衝撃波（`X`）によるライブVJ感。

### 30. USAKAME MUSEUM (`games/30_usakame_museum.rb`)
![30_usakame_museum](../images/30_usakame_museum.png)
- **おすすめポイント**: 30本完結記念の歩ける展示室。各カテゴリの代表ドット絵がレッドカーペットの台座に並び、近づくと解説パネルと祝砲コンフェッティが舞う。
- **工夫点**: 全6つの展示ブースを巡り終えると博物館全体で祝福メッセージが表示されるコレクション達成演出。

---

## Phase2 (31-40) 2026-11-24

### 31. PRISM LASER (`games/31_prism_laser.rb`)
![31_prism_laser](../images/31_prism_laser.png)
- **おすすめポイント**: 鏡とハーフプリズムを回転させてR・G・Bのレーザーを合流・混色（黄/シアン/マゼンタ/白）させる全12面の光学パズル。
- **工夫点（新API活用）**: `@PALETTE 1` ＋ `blend(:add)` ＋ 太線 `line` による光の加算混色レーザーと、`trifill` / `polygonfill` による半透明ガラスプリズム表現。

### 32. STAR TRENCH 3D (`games/32_star_trench.rb`)
![32_star_trench](../images/32_star_trench.png)
- **おすすめポイント**: Zソートされた面塗り3Dポリゴンの渓谷を疾走し、敵機・砲台・巨大戦艦ドレッドノートを撃ち抜く320x240レールシューター。
- **工夫点（新API活用）**: `quadfill` / `trifill` による透視投影3Dポリゴン描画と、`blend(:add)` ツインレーザー・`polyline` 軌道付きホーミングミサイル。

### 33. SHADOW THIEF (`games/33_shadow_thief.rb`)
![33_shadow_thief](../images/33_shadow_thief.png)
- **おすすめポイント**: 警備員の視界コーンを避け、デコイ小石やシャドウダッシュを駆使して宝石を盗み出す全5面のステルス潜入アクション。
- **工夫点（新API活用）**: `blend(:mul)` による夜の暗闇表現と、壁で正確に遮蔽されるレイキャスト `polygonfill` ＋ `alpha` 半透明視界コーン。

### 34. DRIFT CIRCUIT DX (`games/34_drift_circuit_dx.rb`)
![34_drift_circuit_dx](../images/34_drift_circuit_dx.png)
- **おすすめポイント**: 05作目の正統DX進化版。3コース選択・ライバル車2台・ナイトレース対応の320x240見下ろしドリフトレース。
- **工夫点（新API活用）**: `polyline` 太線による滑らかなコース路面、`spr_ext(..., alpha)` による本物の半透明ゴースト、ナイトモードでの `blend(:mul)` 暗闇＆`trifill` ヘッドライト。

### 35. NEON SLASH (`games/35_neon_slash.rb`)
![35_neon_slash](../images/35_neon_slash.png)
- **おすすめポイント**: 居合ダッシュ斬りで敵も弾も真っ二つに両断し、ゲージを溜めて奥義・閃光乱舞を放つハイスピード剣戟アクション。
- **工夫点（新API活用）**: `polyline` ＋ `blend(:add)` の残光斬撃トレイル、`trifill` による切断面ポリゴン飛散、`spr(..., alpha)` による居合残像。

### 36. ABYSS SONAR II (`games/36_submarine_sonar_2.rb`)
![36_submarine_sonar_2](../images/36_submarine_sonar_2.png)
- **おすすめポイント**: 10作目の正統DX進化版。漆黒の深海をサーチライトとソナー波紋で照らし、巨大クラーケンに挑む320x240深海バトル。
- **工夫点（新API活用）**: `blend(:mul)` 漆黒深海、`trifill` ＋ `blend(:add)` 2層サーチライトコーン、`alpha` フェードする多重ソナー波紋＆32x32クラーケン戦。

### 37. SLINGSHOT FORTRESS (`games/37_slingshot_fortress.rb`)
![37_slingshot_fortress](../images/37_slingshot_fortress.png)
- **おすすめポイント**: 鉄球・3分裂弾・爆弾の3種砲弾を使い分け、木・石・ガラス・TNTで構成された物理城砦を崩落させる480x270ワイド破壊パズル（全8面）。
- **工夫点（新API活用）**: 480x270 `bg(:mountain)` 自動フィット、`quadfill` 回転ブロック＆半透明ガラス、`polyline` 弾道ガイド、`blend(:add)` 爆風ショックウェーブ。

### 38. ARCANA DECK (`games/38_arcana_deck.rb`)
![38_arcana_deck](../images/38_arcana_deck.png)
- **おすすめポイント**: 16px東雲日本語UIで遊べる全8階層のデッキ構築ローグライトRPG。勝利後のカード選択でデッキを強化し深淵の龍を討伐。
- **工夫点（新API活用）**: `640x480` `bg(:cave)` 自動フィット、選択カードへの `blend(:add)` 発光オーラ＆魔法ビーム、`alpha` 半透明UIパネル。

### 39. VITRAIL CRAFT (`games/39_vitrail_craft.rb`)
![39_vitrail_craft](../images/39_vitrail_craft.png)
- **おすすめポイント**: 多角形の色ガラスをはめて美しいステンドグラスを完成させる幾何学パズル（全10図柄＋フリーアートモード）。
- **工夫点（新API活用）**: `polygonfill` ＋ `alpha` による半透明色ガラス＆鉛枠、完成時に差し込む `quadfill` ＋ `blend(:add)` 大聖堂の光条シャワー。

### 40. FIREWORKS SYMPHONY DX (`games/40_fireworks_symphony.rb`)
![40_fireworks_symphony](../images/40_fireworks_symphony.png)
- **おすすめポイント**: 26作目の正統DX進化版。480x270ワイド夜空に菊・柳・ハート・土星・星・5連発シンフォニーを打ち上げる花火師トイ。
- **工夫点（新API活用）**: `480x270` `bg(:city)` 自動フィット、`blend(:add)` による光の重なり白熱発光と港水面リアルタイム反射、`polyline` による柳のしだれ軌跡。

---

## Phase3 (41-50) 2026-11-26

### 41. CRATER ARTILLERY (`games/41_crater_artillery.rb`)
![41_crater_artillery](../images/41_crater_artillery.png)
- **おすすめポイント**: 爆風でピクセル地形をリアルタイムに抉り、地形の崩落や角度変化を読みながら戦うWorms風砲撃バトル（1P全8面キャンペーン＋2P対戦）。
- **工夫点（新API＆ハッシュ設計）**: `:pixel` サーフェス＋`blend(:erase)` によるクレーター破壊、`surface_raycast` / `surface_solid?` による着弾・斜面移動判定、`mouse_wheel` 4種兵器切替、`btn(..., 1)` 2P対戦、`save_set` 進捗保存、`$cfg`/`$weapons`/`$stages` ハッシュ集約。

### 42. LANTERN SURVIVORS (`games/42_lantern_survivors.rb`)
![42_lantern_survivors](../images/42_lantern_survivors.png)
- **おすすめポイント**: ランタンの揺らめく光だけを頼りに闇森の魔物をなぎ倒し、ソウルを集めて恒久強化する暗黒サバイバーズ。
- **工夫点（新API＆ハッシュ設計）**: `:gpu` サーフェス＋`blend(:erase)` による白飛びしない複数光源2Dライトマップ（ランタン・松明・魔法弾）、別 `:gpu` サーフェスへの永続スライム痕・足跡デカール、`save_set` 恒久強化、`$cfg`/`$enemies`/`$meta_upgrades` ハッシュ管理。

### 43. INK TURF ARENA (`games/43_ink_turf_arena.rb`)
![43_ink_turf_arena](../images/43_ink_turf_arena.png)
- **おすすめポイント**: 3種のインク兵器で床を塗り合い、自チームインクに潜伏して高速移動＆回復しながら塗り率％を競うスプラッシュ陣取り（1P 2v2 / 2P対戦）。
- **工夫点（新API＆ハッシュ設計）**: `:pixel` 床サーフェス塗り、`surface_pget` による足元インク潜伏・敵インク減速判定、`surface_count` によるリアルタイム面積％集計、`save_set` ブキ解放、`$cfg`/`$weapons` ハッシュ管理。

### 44. MICRO FACTORY (`games/44_micro_factory.rb`)
![44_micro_factory](../images/44_micro_factory.png)
- **おすすめポイント**: 採掘機・ベルトコンベア・精錬炉・出荷口を配線して自動生産ラインを築き、設備を高速化する工場建設シミュレーション。
- **工夫点（新API＆ハッシュ設計）**: `save_set` による工場グリッド配列・GOLD・出荷数・速度Lvの自動JSON永続化、`mouse_wheel` 設備回転、`show_cursor(false)` 設計図カーソル、日本語 `outline` UI、`$cfg`/`$machines`/`$items` ハッシュ管理。

### 45. CYBER DISC DUEL (`games/45_cyber_disc_duel.rb`)
![45_cyber_disc_duel](../images/45_cyber_disc_duel.png)
- **おすすめポイント**: カーブ投法・壁反射・ダッシュキャッチからの必殺「HYPER SMASH」でゴールを狙う高速フライングディスク対戦（1P全4ライバル杯 / 2P対戦）。
- **工夫点（新API＆ハッシュ設計）**: `btn(..., 0/1)`＋`gamepad_count` 対応、`:gpu` サーフェスへのダッシュ痕・壁跳ね・ゴール爆風デカール、`print_text(..., :center, 0)` 演出、`save_set` 記録、`$cfg`/`$rivals` ハッシュ管理。

### 46. FALLING SAND LAB DX (`games/46_falling_sand_dx.rb`)
![46_falling_sand_dx](../images/46_falling_sand_dx.png)
- **おすすめポイント**: 22作目の正統DX進化版。10種の元素（砂・水・木・火・油・酸・溶岩・蒸気・TNT・石）が反応する全10面パズル＋3枠作品セーブ対応ラボ。
- **工夫点（新API＆ハッシュ設計）**: `:pixel` サーフェス＋`surface_swap`/`surface_pget`/`surface_count`（ビーカー充填判定）、`mouse_wheel` ブラシサイズ調整、`save_set` によるクリア記録＆RLE作品保存、`$cfg`/`$elements`/`$puzzles` ハッシュ管理。

### 47. PICROSS ATELIER (`games/47_picross_atelier.rb`)
![47_picross_atelier](../images/47_picross_atelier.png)
- **おすすめポイント**: ロジックを解くとドット絵が完成し、アトリエの壁に飾られて動き出すお絵かきパズル（5x5〜10x10の全16作）。
- **工夫点（新API＆ハッシュ設計）**: `text_width`＋`:right`/`:center` によるヒント数字の精密整列、`save_set` 途中経過オートセーブ＆全16作の永続ギャラリー展示、`mouse_wheel` ツール切替、`$cfg`/`$puzzles` ハッシュ管理。

### 48. FISHING ODYSSEY DX (`games/48_fishing_odyssey_dx.rb`)
![48_fishing_odyssey_dx](../images/48_fishing_odyssey_dx.png)
- **おすすめポイント**: 18作目の正統DX進化版。夕暮れの湖・サンゴ礁・夜港・深海トレンチの4海域を巡り、全20種の永続魚図鑑（最大寸・王冠）を埋める釣りRPG。
- **工夫点（新API＆ハッシュ設計）**: `save_set` による20種図鑑・竿Lv・海域解放の永続保存、夜港・深海での `:gpu` `blend(:erase)` 集魚灯ライトマップ、`mouse_wheel` リール巻き対応、`$cfg`/`$seas`/`$fish_db` ハッシュ管理。

### 49. ABYSSAL DRILLER (`games/49_abyssal_driller.rb`)
![49_abyssal_driller](../images/49_abyssal_driller.png)
- **おすすめポイント**: 縦1160pxのピクセル地層を掘り進み、鉱石を換金してドリル・タンク・ライト・ジェットを強化しながら1000mの最深部コアを目指す地底採掘アクション。
- **工夫点（新API＆ハッシュ設計）**: 大型 `:pixel` サーフェス掘削＆落石判定（`surface_circle_solid?`）、深度に応じた `:gpu` ヘッドライト＆発煙筒ライトマップ、`save_set` 恒久強化、`$cfg`/`$ores`/`$upgrades` ハッシュ管理。

### 50. TITAN COLOSSEUM (`games/50_titan_colosseum.rb`)
![50_titan_colosseum](../images/50_titan_colosseum.png)
- **おすすめポイント**: 50本記念・戦場の傷跡が最後まで残る全5体の32x32巨大タイタン討伐ボスラッシュ（1Pソロ / 2P協力レイド）。
- **工夫点（新API＆ハッシュ設計）**: `:gpu` アリーナ永続傷跡サーフェス＋暗転フェーズ `:gpu` ライトマップ、`show_cursor(false)` カスタム照準、`btn(..., 1)` 2P協力、`save_set` Sランク＆最速タイム保存、`$cfg`/`$titans` ハッシュ管理。
