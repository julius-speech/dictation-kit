GMM-HMM音響モデルについて

【ファイル一覧】

jnas-mono-16mix-gid.binhmm   GMM-HMM音響モデル (monophone, Julius binhmm形式)
jnas-mono-16mix-gid.hmmdefs  GMM-HMM音響モデル (monophone, HTK形式)
jnas-tri-3k16-gid.binhmm     GMM-HMM音響モデル (triphone, Julius binhmm形式)
jnas-tri-3k16-gid.hmmdefs    GMM-HMM音響モデル (triphone, HTK形式)
jnas-tri-rtree.base          Triphoneモデルの回帰木情報 (HTKによるMLLR用)
jnas-tri-rtree.tree          Triphoneモデルの回帰木情報 (HTKによるMLLR用)
logicalTri                   Triphoneリスト

【学習データ】

学習データはASJ-JNASコーパス(86時間)である．

特徴量はMFCC12次元およびその1次差分，エネルギーの1次差分の計25次元(いわゆる
MFCC_E_D_N_Z)で，ケプストラム平均正規化(CMN)が適用されている．

【GMM-HMMモデル】

monophone, triphoneのいずれのモデルも最尤推定による性別非依存(GID)モデル
である．形態は実質3状態のLR型対角共分散HMMで，1状態あたり16混合となっている．
triphoneモデルは8,443個のtriphone，3,090個の状態からなる状態共有モデルである．

どちらのモデルも，HTK形式とJulius binhmm形式が含まれている．これらは
ファイルの形式は異なるが，HMMとしては同内容である．

Triphoneモデルのみ，付属の回帰木情報(base, tree)を用いて，HTKによりMLLR
適応を行うことができる．回帰木のクラス数は32となっている．

【作成者】

三村 正人 (京都大学)
2014年1月

以上
