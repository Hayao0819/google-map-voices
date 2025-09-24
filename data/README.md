# データ

雑多なデータを置いています。

ここらへんの定義ファイルを書き換えればGoogle Mapがよほど大きな構造変更を行わない限り対応できるはずです。

## `voices.json`

セリフと合成音声エンジンの設定です。実質これが本体です。

スキーマは[`voices_schema.json`](./voices_schema.json)を参照してください。テンプレートを[`gen_voices_template.sh`](../scripts/misc/gen_voices_template.sh)で生成できます。

## `messages.plist` / `messages.xml`

気が向いたら書きます。雰囲気で察してください。

## `legacy_messages.xml`

古のGoogle Mapでの`messsages.xml`のサンプルです。

## `legacy.json`

古のGoogle MapでのIDと2025年9月17日現在での音声データのIDの対応表です。

今後このデータをもとにデータをマイグレーションするスクリプトを実装予定です。

スキーマは[`legacy_schema.json`](./legacy_schema.json)を参照してください。テンプレートを[`gen_legacy_template.sh`](../scripts/misc/gen_legacy_template.sh)で生成できます。
