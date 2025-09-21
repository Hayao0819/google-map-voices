# Google Map Voices スクリプト

音声の自動生成を行うためのスクリプトです。

## gen.sh

[voices.json](../data/voices.json)に記載されているキャラクターとテキストを用いて音声ファイルの生成を行います。

実際の生成には[`core`](../core)ディレクトリのスクリプトを使用します。

使い方は`gen.sh -h`を参照してください。

## convert_mp3.sh

指定したディレクトリ内にある`.wav`ファイル全てを`ffmpeg`コマンドを用いて`.mp3`形式に変換します。

使い方は`convert_mp3.sh -h`を参照してください。

## main.sh

`gen.sh`と`convert.sh`を用いて音声ファイルを生成した後、必要なファイルを追加・圧縮して`voice_instructions_unitless.zip`を作成します。

単に`voice_instructions_unitless.zip`をビルドしたい場合はこのスクリプトを実行してください。

指定可能な引数はありません。

`jq`と`zip`が必要です。

## misc/gen_voices_template.sh

`messages.xml`から`voices.json`のテンプレートを生成します。

`xmllint`が必要です。

## misc/setup.sh

`voicevox_core`のダウンロードを行います。

`curl`が必要です。
