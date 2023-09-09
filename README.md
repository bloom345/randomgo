# randomgo

指定したサイズの碁盤（〜19路）に指定石数だけランダムに石を配置し、SGFファイルとして出力するスクリプトです。

### 実行方法

```
# 19路、黒白20子ずつ、中国ルール
% SZ=19 STONES=20 RU=Chinese ruby init_rand_position.rb

# 13路、座標指定
% SZ=13 COORDS="B[ab];W[ac];" ruby init_rand_position.rb
```

### 環境変数

- SZ: 碁盤のサイズ。1〜19までの整数。デフォルト=13
- STONES: 各色の石の数。デフォルト=10
- MIN: nを指定したときに、n線以上にしか配置しない。
- COORDS ランダム配置ではなく、座標をSGFファイル形式で指定できる。この変数を初期化した場合、STONESは無視される。

