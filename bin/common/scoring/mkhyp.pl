#!/usr/bin/perl

# Juliusの認識結果ログから、仮説ファイル(*.hyp)を作成する。
# オプション -p でどちらのパスの仮説ファイルを作成するか指定する。
# JNAS用
#
# 注意: "-quiet" "-demo" をJulius実行時につけた場合，集計がおかしくなる
# ことがあります（集計に必要な単語のN-gram形態素タグ情報が出力されないため）
#
# 使用法
# % nkf -e julius.log | \
#   perl mkhyp.pl \
#       -p {1|2} \
#   > julius.hyp

# オプション処理
require "getopts.pl";
&Getopts('hp:');

if ($opt_h || !$opt_p) {
    &usage;
}

if ($opt_p eq "1") {
    # 第1パスの仮説単語列をログから得る際に用いる。
    $res = "pass1_best_wordseq";
}
elsif ($opt_p eq "2") {
    # 第2パスの仮説単語列をログから得る際に用いる。
    $res = "wseq1";
}
else {
    &usage;
}

while (<>) {
    # フォーマットされたidを出力する。
    if (/^input (MFCC |speech)file: (.*)$/) {
	($spkrid, $sentid) = &bunkai_id($2);
	$id = $spkrid . "-" . $sentid;
	print "$id\n";
    }

    # 認識単語列を出力する。
    if (/^$res:\s+(.*)$/) {
	$sentence = $1;
	print "$sentence\n";
    }

    # CM を出力する (03/06/11)
    if (/^cmscore1:\s+(.*)$/) {
	$cmscore = $1;
	print "cmscore: $cmscore\n";
    }
    if (/^cmscore1\[(.*)\]:\s+(.*)$/) {
	$cmalpha = $1;
	$cmscore = $2;
	print "cmscore[$cmalpha]: $cmscore\n";
    }

}

sub usage {
    print "nkf -e julius_log | ";
    print "jperl -Leuc mkhyp.pl <OPTS> > hypothesis_file\n";
    print "  OPTS --> [-h] -p {1|2}\n";
    print "    -h       --> show help\n";
    print "    -p {1|2} --> select 1pass or 2pass\n";
    exit(-1);
}

sub bunkai_id {
    local($fpath) = @_;
    $fpath =~ s/^.*\///;
    $fpath =~ m/^([^0-9]+[0-9]{3})([0-9]{3})/;
    ($1, $2);
}
