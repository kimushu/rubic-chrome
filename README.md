# Rubic
Rubic(ルービック)は、Ruby言語を用いた組込みボードのプロトタイピング環境です。

スクリプト入力画面でプログラムを書いたら、接続しているボードを選択して[実行]ボタンを押すだけで、プログラムがボード上で走り出します。

本ソフトウェアは、Google Chrome&trade;アプリとして提供され、Chromeの動作環境(Windows / Mac OS X / Linux / Chrome OS)であればどの環境でも使うことができます。

![Rubic Introduction](http://drive.google.com/uc?export=view&id=0Bwxb9sJ6SGTDZzFGb2dtM1N4OG8)

## 機能
- スケッチの編集/保存 (保存先はPCのローカルストレージ)
- Rubyからmruby中間コードへのビルドおよび対応ボードへの転送

## 対応ボード (バージョン 0.9.0 時点)
- PERIDOT (http://osafune.github.io/peridot.html)
  - 0.1.\* 時点ではボード側ファームウェアの書き込みに対応していません。
    RBF-Writer ( https://chrome.google.com/webstore/detail/peridot-rbf-writer/lchhhfhfikpnikljdaefcllbfblabibg )を用いて、下記のファームウェアを事前に書き込んでおく必要があります。

    https://github.com/kimushu/rubic-catalog/tree/v0.1.x/PERIDOT

- GR-CITRUS (https://github.com/wakayamarb/wrbb-v2lib-firm)
  - 0.2.2 から対応しました。
  - ボードは秋月電子通商(http://akizukidenshi.com/)から購入できます。

- Wakayama.rb ボード (https://github.com/tarosay/Wakayama-mruby-board)
  - 0.2.\* から対応しました。ボード側ファームウェアのバージョンは「ARIDA4-1.29(2015/12/8)f3」以降を用いて下さい。

## 仕組み
Rubicアプリ本体はCoffeeScriptから変換されたJavaScriptで構成されており、その内部には、emscriptenでビルドすることでJavaScriptに変換されたmrubyが同梱されています。

[実行]ボタンが押されると、同梱されたmrubyが起動してスケッチのRubyスクリプト(.rb)をmrubyの中間コードファイル(.mrb)に変換します。変換された中間コードファイルは接続した組込みボードに書き込まれ、ボードがリセットされてすぐに動き始めます。

## 更新履歴
- 2016/10/xx : 0.9.0 ハードウェアカタログ追加、複数ファイル編集対応
- 2016/05/14 : 0.2.2 GR-CITRUS 対応追加
- 2015/12/10 : 0.2.0 Wakayama.rb ボード対応追加、出力ウィンドウ追加
- 2015/04/19 : 0.1.0 初回リリース

## 今後の予定
- 2016/11 : 1.0.0 リリース予定。ファームウェア書き換え機能の内蔵、カタログ増強、PERIDOT向けファームウェアの追加等。

## 不具合報告や要望について
- 不具合のご報告や機能追加等のご要望は、GithubのIssuesページ( https://github.com/kimushu/rubic/issues )へ登録いただけますと幸いです。Issuesは日本語で記述して頂いて問題ありません。

## ライセンス
Rubic本体のソースコードは、MIT Licenseで公開されています。
- https://github.com/kimushu/rubic/

同梱された各ライブラリのライセンスについては、「左上のメニュー→このアプリの情報」から確認できます。
