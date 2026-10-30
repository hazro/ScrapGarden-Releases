# SCRAP GARDEN

Windows用の配布専用リポジトリです。

## 最新版をダウンロード

[**SCRAP GARDEN for Windows（ZIP）**](https://github.com/hazro/ScrapGarden-Releases/releases/latest/download/ScrapGarden-Windows.zip)

現在の版：**27.25.0-B**

このリンクは今後の更新でも変わりません。ZIPをすべて展開してから「SCRAP GARDEN B.exe」を起動してください。

公開中のゲーム配布は最新版だけを保持します。ゲームのソースコード・ユーザーの保存データはこのリポジトリに含みません。

## Windows自動ダウンロードBAT

[Download-ScrapGarden.batをダウンロード](https://github.com/hazro/ScrapGarden-Releases/releases/latest/download/Download-ScrapGarden.bat)

ダブルクリックすると、BATの隣の`Downloads`フォルダーに最新版のZIPを保存します。
保存先を指定する場合：

```bat
Download-ScrapGarden.bat "D:\Games\ScrapGarden"
```

第2引数に`/nopause`を付けると、完了後のキー待ちを省略します。
ダウンロード完了・サイズ・SHA-256を確認してから同名ZIPを置き換えます。
ゲームの自動起動・自動展開は行いません。Windows標準のPowerShellを使います。
