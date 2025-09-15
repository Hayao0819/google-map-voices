# Google Map Voices

## これは何?

Google Mapの音声案内をかわいい女の子にやってもらおうというプロジェクトです。

## ビルド方法

```bash
cd scripts/misc
./setup.sh
cd ..
./main.sh
```

## 適用方法

### インストーラ

### 手動

1. 設定→ナビ→音声の選択→日本語を選択 (ここ重要)
2. アプリを終了
3. 何らかの方法で`/storage/emulated/0/Android/data/com.google.android.apps.maps/testdata/voice/ja_JP(文字列)/`を開く
4. 以下のファイルを置き換える
   - `/storage/emulated/0/Android/data/com.google.android.apps.maps/testdata/voice/ja_JP(文字列)/voice_instructions_unitless.zip`
   - `/storage/emulated/0/Android/data/com.google.android.apps.maps/testdata/voice/ja_JP(文字列)/ja/voice_instructions_unitless.zip`
5. Google Mapアプリのキャッシュを消す
6. 設定→ナビ→音声の選択→デフォルトを選択
7. アプリを終了
8. 設定→ナビ→音声の選択→日本語を選択
