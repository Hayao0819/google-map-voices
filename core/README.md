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
