======================================================================

                「Juliusディクテーションキット v4.5」

						      v3.0 2004/08/11
						      v3.1 2005/11/11
						      v3.2 2008/01/17
						      v4.0 2009/12/17
						      v4.1 2011/03/03
						      v4.2 2011/05/11
						    v4.2.3 2013/06/30
						    v4.3.1 2014/01/31
						      v4.4 2016/09/21
						      v4.5 2019/04/16
======================================================================

□ はじめに //////////////////////////////////////////////////////////

これは，音声認識（ディクテーション）を動作させてみるためのフリーの
キットです．任意の読み上げ文発声（対象語彙数6万語）をほぼ実時間で
90%以上認識することができます．

動作環境は Windows/Linux/MacOSX です．

Julius は Rev.4.5 を用いています．他のバージョンの Julius を使い
たい場合は，Julius のサイトからダウンロードしたバイナリや，自分で
コンパイルしたバイナリの実行ファイルを，このディレクトリの bin 内の
対応するOSのディレクトリ内に上書きコピーしてください．

最新情報や詳しい内容については，以下のページをご覧下さい．

http://julius.osdn.jp/


□ 動作環境 //////////////////////////////////////////////////////////

  ○ OS

     [Windows]
     動作確認は Windows 7/8.1/10 (64-bit) で行いました．
     DirectSound が必須です．

     [Linux]
     動作確認は CentOS 6 (64-bit) で行いました．
     Ubuntu, Debian 等でも動作するかもしれません．
     DNN版では X11 (xterm) が必須です．

     [MacOSX]
     動作確認は MacOSX 10.11 (El Capitan) で行いました．
     DNN版では X11 (XQuartz) が必須です．

  ○ ハードウェアスペック

     推奨：  Core/Xeon   3.0GHz以上，メモリ2GB，HDD 1GB 以上
     最低限：Core        1.5GHz以上，メモリ1GB，HDD 1GB 以上

     加えて，サウンドデバイス，およびマイクロフォンが必要です．

     なお，プロセスサイズは 700MB 程度なので，安定して動作させる
     ためには 1GB 程度の空きメモリが必要です．
     DNN版の実行にはマルチコアCPUやGPU(CUDA)の使用を推奨します．


□ 格納ファイル ///////////////////////////////////////////////////////

  00readme.txt		この文書

  HOWTO.txt		認識システムの起動と動作
  HOWTO-dnncli.txt	DNN(dnnclient)版による音声認識の実行
  LICENSE.txt		利用許諾書
  TROUBLE.txt		うまく認識できないときは

  main.jconf	        DNN版・GMM版のJulius共通設定ファイル
  am-dnn.jconf	        DNN版のJulius音響モデル・入力設定ファイル
  am-gmm.jconf		GMM版のJulius音響モデル・入力設定ファイル

  dnnclient.conf	DNN(dnnclient)版の特徴量変換設定ファイル
  julius.dnnconf	DNN(Julius単体)版の特徴量変換設定ファイル

  run-linux-dnn.sh	DNN(Julius単体)版の起動シェルスクリプト (Linux)
  run-linux-dnncli.sh	DNN(dnnclient)版の起動シェルスクリプト  (Linux)
  run-linux-gmm.sh	GMM版の起動シェルスクリプト             (Linux)

  run-osx-dnn.sh	DNN(Julius単体)版の起動シェルスクリプト (MacOSX)
  run-osx-dnn.sh	DNN(dnnclient)版の起動シェルスクリプト  (MacOSX)
  run-osx-gmm.sh	GMM版の起動シェルスクリプト             (MacOSX)

  run-win-dnn.bat	DNN(Julius単体)版の起動バッチファイル (Windows)
  run-win-dnncli.bat	DNN(dnnclient)版の起動バッチファイル  (Windows)
  run-win-gmm.bat	GMM版の起動バッチファイル             (Windows)

  model/		認識用の日本語音響モデルと単語3-gram言語モデル

  bin/			実行バイナリのディレクトリ
    linux|osx|windows/	(OSごとに分かれている)
      adinrec(.exe)	録音ツール
      adintool(.exe)	音声入出力ツール
      adintool-gui.exe	音声入出力ツール(GUI版，Windowsのみ)
      jcontrol(.exe)	Julius モジュールモード用のサンプルクライアント
      julius(.exe)	Julius rev.4.5

  src/			Julius rev.4.5 ソースアーカイブ


□ 使用方法 //////////////////////////////////////////////////////////

使用方法については HOWTO.txt をご覧下さい．
認識がうまく動かないときは TROUBLE.txt をご参照下さい．

実行バイナリがご利用の環境で動作しない場合は，Julius をコンパイル
し直して，バイナリを差し替えてお試し下さい．

DNN(dnnclient)版をご利用の場合は，必ず HOWTO-dnncli.txt をご覧の上
必要なセットアップを行って下さい．


□ その他 ///////////////////////////////////////////////////////////

より限られた語彙を認識するような場合は，「文法認識キット」が便利です．
文法認識キットでは，文法制約の元で決められた文パターンのみから認識を行
います．詳しくは Julius のホームページをご覧ください．

	http://julius.osdn.jp/


□ 変更履歴 //////////////////////////////////////////////////////////

(v4.3.1以降)

v4.5
・JuliusをRev.4.5 に更新
・マイク音声検出をFVAD併用の設定に変更（-lv 1500 → -lv 800 -fvad 3）
・DNN計算のCPUスレッド数は2に設定 (julius.dnnconf で変更可能)
・古いマニュアルを削除
・adintool-gui.bat を追加

v4.4
・JuliusをRev.4.4.1 に変更
  これによりDNN-HMMをJulius単体でサポート
  Intel AVX/FMA命令セットの使用
  32bit OSはこのバージョンからサポート外
・音響モデルの更新
  JNASと『日本語話し言葉コーパス』模擬講演データによるDNN-HMM音響モデル
・ベンチマーク(JNASテストセット200文における文字正解精度)
  90.8% (GMM-HMM音響モデルの場合)
  94.7% (DNN-HMM音響モデルの場合)

v4.3.1
・JuliusをRev.4.3.1に変更
  これによりDNN-HMMをサポート(dnnclientを使用)
・モデルの刷新
  『新聞記事読み上げ音声コーパス』(JNAS)によるGMM-HMM・DNN-HMM音響モデル
  『現代日本語書き言葉均衡コーパス』(BCCWJ)による言語モデル

								以上
