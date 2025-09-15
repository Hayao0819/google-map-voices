# GMV Installer

Google Map VoicesをAndroidにインストールするためのスクリプトです。

adb shellでsuコマンドが実行できる状態である必要があります。

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
