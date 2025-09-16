# Core スクリプト

合成音声エンジンの呼び出し部分を実装している部分です。

現時点ではVOICEVOXのみのサポートです。気が向いたら他の合成音声エンジンもサポートします。しないかも。

## 呼び出しの実装

呼び出しの実装はシェルスクリプト関数として実装します。

引数形式は以下のインターフェースに従う必要があります。

```bash
hogehoge text output [options...]
```

キャラ名と呼び出す関数名、オプションは[`voices.json`](../data/voices.json)で設定します。

## ファイル

### `run.py`

<https://github.com/VOICEVOX/voicevox_core/tree/main/example/python>

MITライセンスのもとで配布されているexampleを利用しています。

### `voicevox.sh`

`run.py`を`uv`経由で起動するスクリプト。

IDとスタイルについてが[対応表](https://github.com/VOICEVOX/voicevox_vvm/blob/main/README.md#%E9%9F%B3%E5%A3%B0%E3%83%A2%E3%83%87%E3%83%ABvvm%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E3%81%A8%E5%A3%B0%E3%82%AD%E3%83%A3%E3%83%A9%E3%82%AF%E3%82%BF%E3%83%BC%E3%82%B9%E3%82%BF%E3%82%A4%E3%83%AB%E5%90%8D%E3%81%A8%E3%82%B9%E3%82%BF%E3%82%A4%E3%83%AB-id-%E3%81%AE%E5%AF%BE%E5%BF%9C%E8%A1%A8)を参照してください。
