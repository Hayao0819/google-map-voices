# GMV Installer

Google Map VoicesをAndroidにインストールするためのスクリプトです。

## 利用条件

Android OSの制約により、以下の何れかの条件を満たしている必要があります。

- 何らかの方法によりRoot化され`su`コマンドが利用可能である
- Android 9以下のデバイス
- その他何らかの方法によりScoped Storageを回避したデバイス

インストーラのデフォルトでは`su`コマンドによりScoped Storage制約の回避を試みます。

`-n`オプション付きで実行することで、`su`無しでの実行を試みます。

## 依存関係

スクリプトを実行するPCには以下のコマンドが必要です。

- wget
- adb

インストール対象のAndroid端末には以下のコマンドが必要です。

- su
- cp

## 実行方法

1. Google Mapを起動し、ナビの設定から言語を日本語にしておく
2. `su`コマンドを実行できるようにroot化する
3. PCから`adb shell`を実行できる状態にする
4. 次のコマンドを実行する

    ```bash
    wget -O - "https://raw.githubusercontent.com/Hayao0819/google-map-voices/refs/heads/master/scripts/installer/install.sh" | bash

    ```

## 引数

受け取る引数は1つのみです。

zipファイルへのパスを渡すと、それを使います。URLを渡すと、ダウンロードを自動で行います。

`ttchan`, `kiritan`の文字列を渡すと自動でダウンロードします。

## 自分の手でｺﾈｺﾈ作った温かいzipファイルを使いたい方へ

自分で作った`voice_instructions_unitless.zip`を使い方もこのインストーラスクリプトを用いることで配置を自動で行えます。

```bash
wget "https://raw.githubusercontent.com/Hayao0819/google-map-voices/refs/heads/master/scripts/installer/install.sh"
bash ./install.sh /path/to/your_hot_file.zip
```

## 権限チェック

インストーラは実行前に簡易的な権限チェックを実行します。

Root無しのオプション(`-n`)で実行する場合、一部のデバイスで'見かけ上は適用に成功している'挙動をしますが、実際には書き換えには成功していません。

この挙動はnubia Z60 Ultraで確認していますが、詳細は不明です。これらについてご存じの方は連絡を頂けると幸いです。
