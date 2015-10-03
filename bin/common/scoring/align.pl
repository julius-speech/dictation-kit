#!/usr/bin/perl

# 正解ファイル(*.ref)と仮説ファイル(*.hyp)に対して、
# DPを使って単語のアラインメントをとる。
# オプション -u で単位(形態素or文字)を指定、
# オプション -f で表記(漢字かな混じり or カタカナ)を指定する。
# 形態素単位でアラインメントを取る場合、複合語処理を行なうかどうかを
# オプション -c で指定する。
# なお、オプション -r の後に正解ファイルを指定する。
#
# 使用法
# % align.pl \
#       -u {morpheme|char} \
#       [-c] \
#       -f {kanji|kana} \
#       -r reference_file \
#   hypothesis_file \
#   > alignment_file

# 2003/06/11   CM 対応

# オプション処理
require "getopts.pl";
&Getopts('hu:cf:r:');

if ($opt_h || !$opt_u || !$opt_f || !$opt_r) {
    &usage;
}

if ($opt_u ne "morpheme" && $opt_u ne "char") {
    &usage;
}

if ($opt_f ne "kanji" && $opt_f ne "kana") {
    &usage;
}

if ($opt_u eq "char" && $opt_c) {
    &usage;
}

# 正解ファイルを読み込んで、連想配列に入れる。
open(REFER, "nkf -e $opt_r |");
while (<REFER>) {
    chop;

    if (/^[a-zA-Z0-9\-]+$/) {
        $r_id = $_;
    }
    else {
        $refer{$r_id} = $_;
    }
}

$h_id = "";
@idref = ();
while (<>) {
    chop;

    if (/^[a-zA-Z0-9\-]+$/) {
	if ($h_id ne "") {
	    print "\n";
	}
	# 対応する正解単語列を@referに入れる。
        $h_id = $_;
        @refer = split(' ', $refer{$h_id});
    } elsif (! /^cmscore/) {
        # 仮説単語列を@resultに入れる。
        @result = split(' ', $_);
        # alignmentを実行して結果を出力する
	&process_align();
    } elsif (/^cmscore:\s+(.*)$/) {
	# CMスコアを出力
	$cmalpha = 0;
	@cmscore = split(/[ \t\n]+/, $1);
	&output_cm();
    } elsif (/^cmscore\[(.*)\]:\s+(.*)$/) {
	# CMスコアを出力(複数)
	$cmalpha = $1;
	@cmscore = split(/[ \t\n]+/, $2);
	&output_cm();
    }
}

sub process_align {

        &ignore_pause;

        if ($opt_f eq "kanji") {
            # @rfer、@resultを漢字かな混じり表記の列にする。
            &mk_kanji_array;
        }
        elsif ($opt_f eq "kana") {
            # @rfer、@resultをカナ表記の列にする。
            &mk_yomi_array;
        }

        # @refer、@resultを文字単位の列にする。
        if ($opt_u eq "char") {
            $refer = join('', @refer);
            $result = join('', @result);

            @refer = split(//, $refer);
            @result = split(//, $result);
        }

        # @referの数を$rcountに、@resultの数を$hcountに入れる。
        $rcount = $#refer + 1;
        $hcount = $#result + 1;

        # @refer、@result、$rcout、$hcountを読み込んで、アラインメントに入る。
        ($status_str, $result_str, $refer_str) = &taiou;

        # 正解単語列、仮説単語列、アラインメント結果列を出力用に整形する。
        $refer_line = "REF:  " . $refer_str;
        $result_line = "HYP:  " . $result_str;
        $status_line = "EVAL: " . $status_str;

        # id、正解単語列、仮説単語列、アラインメント結果列を出力する。
        print "id: $h_id\n";
        print "$refer_line\n";
        print "$result_line\n";
        print "$status_line\n";

}

sub usage {
    print "align.pl <OPTS> hyp_file > alignment_file\n";
    print "  OPTS --> [-h] -u {morpheme|char} [-c] -f {kanji|kana} -r ref_file\n
";
    print "    -h                 --> show help\n";
    print "    -u {morpheme|char} --> select a unit for alignment\n";
    print "    -c                 --> do complex word process (-u morpheme)\n";
    print "    -f {kanji|kana}    --> select a face for alignment\n";
    print "    -r ref_fine        --> specify a formatted reference file\n";
    exit(-1);
}

#sub ignore_pause {
#    @refer = grep(!/\+[^ーア-ンヴァィゥェォッャュョヮ]+\+7[3-8]/, @refer);
#    @result = grep(!/\+[^ーア-ンヴァィゥェォッャュョヮ]+\+7[3-8]/, @result);
#}

sub output_cm {
    local(@cmscore_tmp, @ids);

    @ids = @idref;
    for (@ids) {
	push(@cmscore_tmp, $cmscore[$_]);
    }
    @cmscore = @cmscore_tmp;
    if ($cmalpha == 0) {
	print "CMSCORE:";
    } else {
	print "CMSCORE[$cmalpha]:";
    }
    for (@cmscore) {
	print " $_";
    }
    print "\n";
}

sub ignore_pause {
    local(@ref_tmp, @result_tmp, @idref_tmp, $c, $i, $NF);

    @idref = ();
    for ($i=0;$i<=$#result;$i++) {
	push(@idref, $i);
    }

    for (@result) {
	$c = shift(@idref);
	next if /<s>/;
	next if /<\/s>/;

	unless (/(、|。|・|？|！|「|」|『|』|―|“|”|▽|△)/) {
	    push(result_tmp, $_);
	    push(idref_tmp, $c);
	    next;
	}

	$NF = split(/\+/);

	if ($_[0] ne $_[1] && $NF > 1) {
	    push(result_tmp, $_);
	    push(idref_tmp, $c);
	}
    }

    @result = @result_tmp;
    @idref = @idref_tmp;
    
    for (@refer) {
	unless (/(、|。|・|？|！|「|」|『|』|―|“|”|▽|△)/) {
	    push(ref_tmp, $_);
	    next;
	}

	$NF = split(/\+/);

	if ($_[0] ne $_[1] && $NF > 1) {
	    push(ref_tmp, $_);
	}
	elsif (/・/ && length($_[0]) > 2) { # 読みにも表記にも・があるとき
	    $_ =~ s/・//g;
	    push(ref_tmp, $_);
	}
    }

    @refer = @ref_tmp;
}

sub mk_kanji_array {
    grep(s/\+.*$//, @refer);
    grep(s/\+.*$//, @result);
}

sub mk_yomi_array {
    grep(s/^[^\+]*\+//, @refer);
    grep(s/^[^\+]*\+//, @result);

    grep(s/\+.*$//, @refer);
    grep(s/\+.*$//, @result);
}

sub taiou {
    local($i, $j, %g, %d, %r, @status, @kekka_result, @kekka_refer);
    local($kx, $kx2) = 0;
    local($status_str, $result_str, $refer_str);
    local($status_str2, $result_str2, $refer_str2);
    local($del, $ins, $sub, $cor);
    local($del2, $ins2, $sub2, $cor2);
    local($ref2, $hyp2);

    # DPを使ってアラインメントを取る
    ($kx, $cor, $sub, $del, $ins) = &dp;

    # 読みでアラインメントを取った結果、併記読みの部分で置換誤りに
    # なっているところについて、正解判定をやり直す。
    # (併記の中に正解が含まれていれば、OKとする。)
    for ($i = $kx - 1; $i >= 0; $i--) {
	if ($status[$i] eq "S") {
	    if ($kekka_result[$i] =~ /\{.+\}/ &&
		$kekka_refer[$i] =~ /\{.+\}/) {
		$kekka_result[$i] =~ /(.*)\{(.+)\}(.*)/;
		$result_head = $1;
		$result_yomi = $2;
		$result_tail = $3;
		@resyomis = split('\/', $result_yomi);

		$kekka_refer[$i] =~ /(.*)\{(.+)\}(.*)/;
		$refer_head = $1;
		$refer_yomi = $2;
		$refer_tail = $3;
		@refyomis = split('\/', $refer_yomi);

		foreach $resyomi (@resyomis) {
		    if ($result_head) {
			$resyomi = $result_head . $resyomi;
		    }
		    if ($result_tail) {
			$resyomi = $resyomi . $result_tail;
		    }

		    foreach $refyomi (@refyomis) {
			if ($refer_head) {
			    $refyomi = $refer_head . $refyomi;
			}
			if ($result_tail) {
			    $refyomi = $refyomi . $refer_tail;
			}

			$status[$i] = "C" if $resyomi eq $refyomi;
		    }
		}
	    }
	    elsif ($kekka_result[$i] =~ /\{.+\}/ &&
		   $kekka_refer[$i] !~ /\{.+\}/) {
		$kekka_result[$i] =~ /(.*)\{(.+)\}(.*)/;
		$result_head = $1;
		$result_yomi = $2;
		$result_tail = $3;
		@resyomis = split('\/', $result_yomi);

		$ref_yomi = $kekka_refer[$i];

		foreach $resyomi (@resyomis) {
		    if ($result_head) {
			$resyomi = $result_head . $resyomi;
		    }
		    if ($result_tail) {
			$resyomi = $resyomi . $result_tail;
		    }
		    $status[$i] = "C" if $resyomi eq $ref_yomi;
		}
	    }
	    elsif ($kekka_result[$i] !~ /\{.+\}/ &&
		   $kekka_refer[$i] =~ /\{.+\}/) {
		$res_yomi = $kekka_result[$i];

		$kekka_refer[$i] =~ /(.*)\{(.+)\}(.*)/;
		$refer_head = $1;
		$refer_yomi = $2;
		$refer_tail = $3;
		@refyomis = split('\/', $refer_yomi);

		foreach $refyomi (@refyomis) {
		    if ($refer_head) {
			$refyomi = $refer_head . $refyomi;
		    }
		    if ($refer_tail) {
			$refyomi = $refyomi . $refer_tail;
		    }
		    $status[$i] = "C" if $refyomi eq $res_yomi;
		}
	    }
	    else {
		;
	    }
	}
    }

    # 複合語処理なし
    if (!$opt_c) {
	for ($i = $kx - 1; $i >= 0; $i--) {
	    local($len1, $len2, $len, $format);
	    $len1 = length($kekka_result[$i]);
	    $len2 = length($kekka_refer[$i]);
	    $len = $len1 > $len2 ? $len1 : $len2;
	    $format = "%-" . $len . "s ";

	    $status_str .= sprintf($format, $status[$i]);
	    $result_str .= sprintf($format, $kekka_result[$i]);
	    $refer_str .= sprintf($format, $kekka_refer[$i]);
	}

	($status_str, $result_str, $refer_str);
    }
    # 複合語処理あり
    else {
	for ($i = $kx - 1; $i >= 0; $i--) {
	    local($len1, $len2, $len, $format);
	    $len1 = length($kekka_result[$i]);
	    $len2 = length($kekka_refer[$i]);
	    $len = $len1 > $len2 ? $len1 : $len2;
	    $format = "%-" . $len . "s ";

	    if ($status[$i] eq "C") {
		if (@status_tmp) {
		    &fukugougo;	# 複合語処理に入る
		}

		$status_str2 .= sprintf($format, $status[$i]);
		$result_str2 .= sprintf($format, $kekka_result[$i]);
		$refer_str2 .= sprintf($format, $kekka_refer[$i]);

		$cor2++;
		$ref2++;
		$hyp2++;
	    }

	    # Sから始まりDやIが続くような認識誤り部分単語列を配列に入れる
	    if ($status[$i] eq "S") {
		$check_s = 1;

		push(@status_tmp, $status[$i]);
		push(@kekka_result_tmp, $kekka_result[$i]);
		push(@kekka_refer_tmp, $kekka_refer[$i]);
	    }

	    # Sから始まりDやIが続くような認識誤り部分単語列を配列に入れる
	    if ($status[$i] eq "D") {
		if ($check_s) {
		    push(@status_tmp, $status[$i]);
		    push(@kekka_result_tmp, $kekka_result[$i]);
		    push(@kekka_refer_tmp, $kekka_refer[$i]);
		}
		else {
		    $status_str2 .= sprintf($format, $status[$i]);
		    $result_str2 .= sprintf($format, $kekka_result[$i]);
		    $refer_str2 .= sprintf($format, $kekka_refer[$i]);

		    $del2++;
		    $ref2++;
		}
	    }

	    # Sから始まりDやIが続くような認識誤り部分単語列を配列に入れる
	    if ($status[$i] eq "I") {
		if ($check_s) {
		    push(@status_tmp, $status[$i]);
		    push(@kekka_result_tmp, $kekka_result[$i]);
		    push(@kekka_refer_tmp, $kekka_refer[$i]);
		}
		else {
		    $status_str2 .= sprintf($format, $status[$i]);
		    $result_str2 .= sprintf($format, $kekka_result[$i]);
		    $refer_str2 .= sprintf($format, $kekka_refer[$i]);

		    $ins2++;
		    $hyp2++;
		}
	    }
	}

	if (@status_tmp) {
	    &fukugougo;		# 複合語処理に入る
	}

	($status_str2, $result_str2, $refer_str2);
    }
}

sub dp {
    local($i, $j, %g, %d, %r);
    local($kx) = 0;
    local($del, $ins, $sub, $cor);

    for ($i = 1; $i <= $rcount; $i++) {
	for ($j = 1; $j <= $hcount; $j++) {
	    if ($result[$j-1] eq $refer[$i-1]) {
		$d{$i,$j} = 0;
	    } else {
		$d{$i,$j} = 1;
	    }
	}
    }

    $g{0,0} = 0;
    $r{0,0} = 0;

    for ($i = 1; $i <= $rcount; $i++) {
	$g{$i,0} = $i;
	$r{$i,0} = 1;
    }

    for ($j = 1; $j <= $hcount; $j++) {
	$g{0,$j} = $j;
	$r{0,$j} = 2;
    }

    for ($i = 1; $i <= $rcount; $i++) {
	for ($j = 1; $j <= $hcount; $j++) {
	    ($g{$i,$j}, $r{$i,$j}) = 
		&set_node($g{$i-1,$j}+1, 
			  $g{$i,$j-1}+1, 
			  $g{$i-1,$j-1}+$d{$i,$j});
	}
    }

    $i = $rcount;
    $j = $hcount;
    $kx = 0;
    
    for (;;) {
	if ($r{$i,$j} == 1) {
	    $status[$kx] = "D";
	    $kekka_result[$kx] = "";
	    $kekka_refer[$kx] = $refer[$i-1];
	    $del++;
	    $i--;
	} elsif ($r{$i,$j} == 2) {
	    $status[$kx] = "I";
	    $kekka_result[$kx] = $result[$j-1];
	    $kekka_refer[$kx] = "";
	    $ins++;
	    $j--;
	} elsif ($r{$i,$j} == 3) {
	    if ($d{$i,$j} == 1) {
		$status[$kx] = "S";
		$kekka_result[$kx] = $result[$j-1];
		$kekka_refer[$kx] = $refer[$i-1];
		$sub++;
	    } elsif ($d{$i,$j} == 0) {
		$status[$kx] = "C";
		$kekka_result[$kx] = $result[$j-1];
		$kekka_refer[$kx] = $refer[$i-1];
		$cor++;
	    } else {
		print STDERR "error\n";
	    }
	    $i--;
	    $j--;
	} elsif ($i == 0 && $j == 0) {
	    last;
	}
	$kx++;
    }

    ($kx, $cor, $sub, $del, $ins);
}

sub dp2 {
    local($i, $j, %g, %d, %r);

    for ($i = 1; $i <= $rcount2; $i++) {
	for ($j = 1; $j <= $hcount2; $j++) {
	    if ($res_lines[$j-1] eq $ref_lines[$i-1]) {
		$d{$i,$j} = 0;
	    } else {
		$d{$i,$j} = 1;
	    }
	}
    }

    $g{0,0} = 0;
    $r{0,0} = 0;

    for ($i = 1; $i <= $rcount2; $i++) {
	$g{$i,0} = $i;
	$r{$i,0} = 1;
    }

    for ($j = 1; $j <= $hcount2; $j++) {
	$g{0,$j} = $j;
	$r{0,$j} = 2;
    }

    for ($i = 1; $i <= $rcount2; $i++) {
	for ($j = 1; $j <= $hcount2; $j++) {
	    ($g{$i,$j}, $r{$i,$j}) = 
		&set_node($g{$i-1,$j}+1, 
			  $g{$i,$j-1}+1, 
			  $g{$i-1,$j-1}+$d{$i,$j});
	}
    }

    $i = $rcount2;
    $j = $hcount2;
    $kx2 = 0;
    
    for (;;) {
	if ($r{$i,$j} == 1) {
	    $status2[$kx2] = "D";
	    $kekka_result2[$kx2] = "";
	    $kekka_refer2[$kx2] = $ref_lines[$i-1];
	    $del2++;
	    $i--;
	} elsif ($r{$i,$j} == 2) {
	    $status2[$kx2] = "I";
	    $kekka_result2[$kx2] = $res_lines[$j-1];
	    $kekka_refer2[$kx2] = "";
	    $ins2++;
	    $j--;
	} elsif ($r{$i,$j} == 3) {
	    if ($d{$i,$j} == 1) {
		$status2[$kx2] = "S";
		$kekka_result2[$kx2] = $res_lines[$j-1];
		$kekka_refer2[$kx2] = $ref_lines[$i-1];
		$sub2++;
	    } elsif ($d{$i,$j} == 0) {
		$status2[$kx2] = "C";
		$kekka_result2[$kx2] = $res_lines[$j-1];
		$kekka_refer2[$kx2] = $ref_lines[$i-1];
		$cor2++;
	    } else {
		print STDERR "error\n";
	    }
	    $i--;
	    $j--;
	} elsif ($i == 0 && $j == 0) {
	    last;
	}
	$kx2++;
    }

    ($kx2);
}

sub set_node {
    local($a, $b, $c) = @_;
    if ($a <= $b) {
	if ($a <= $c) {
	    return ($a, 1);
	} else {
	    return ($c, 3);
	}
    } else {
	if ($b <= $c) {
	    return ($b, 2);
	} else {
	    return ($c, 3);
	}
    }
}

sub fukugougo {
    local($i, $j, %flag_ref, %flag_res, %same_ref, %same_res);
    local($count) = 0;
    local($rscount, $rfcount) = 0;
    local($prev_flag_ref, $prev_flag_res);
    local($ref_line, $res_line);
    local(@ref_lines, $res_lines);
    local(@status2, @kekka_refer2, @kekka_result2);

    $matubi = $#status_tmp;

    # どの部分を結合すればよいかラベリングする
    for ($i = 0; $i <= $matubi; $i++) {
	$count++;
	for ($j = 0; $j <= $matubi; $j++) {
	    if ($kekka_refer_tmp[$i] =~ /$kekka_result_tmp[$j]/) {
		$res_word = $kekka_result_tmp[$j];

		if ($flag_res{$j}) {
		    ;
		}
		else {
		    if (!$same_res{$res_word}) {
			$flag_res{$j} = $count;
			$same_res{$res_word} = $count;
		    }
		    elsif ($same_res{$res_word} != $count) {
			$flag_res{$j} = $count;
			$same_res{$res_word} = $count;
		    }
		    else {
			last;
		    }			    
		}
	    }
	}
    }

    # どの部分を結合すればよいかラベリングする
    for ($i = 0; $i <= $matubi; $i++) {
	$count++;
	for ($j = 0; $j <= $matubi; $j++) {
	    if ($kekka_result_tmp[$i] =~ /$kekka_refer_tmp[$j]/) {
		$ref_word = $kekka_refer_tmp[$j];

		if ($flag_ref{$j}) {
		    ;
		}
		else {
		    if (!$same_ref{$ref_word}) {
			$flag_ref{$j} = $count;
			$same_ref{$ref_word} = $count;
		    }
		    elsif ($same_ref{$ref_word} != $count) {
			$flag_ref{$j} = $count;
			$same_ref{$ref_word} = $count;
		    }
		    else {
			last;
		    }
		}
	    }
	}
    }

    # ラベリング結果に沿って、部分単語列を結合する
    for ($i = 0; $i <= $matubi; $i++) {
	if ($flag_res{$i}) {
	    $rscount++;

	    if ($rscount == 1 || $prev_flag_res == $flag_res{$i}) {
		$res_line .= $kekka_result_tmp[$i];
	    }
	    elsif ($flag_res{$i} < $prev_flag_res) {
		$res_line .= " " . $kekka_result_tmp[$i] . " ";
	    }
	    else {
		$res_line .= " " . $kekka_result_tmp[$i];
	    }

	    $prev_flag_res = $flag_res{$i};
	}
	else {
	    $rscount = 0;

	    $res_line .= " " . $kekka_result_tmp[$i] . " ";
	}

	if ($flag_ref{$i}) {
	    $rfcount++;

	    if ($rfcount == 1 || $prev_flag_ref == $flag_ref{$i}) {
		$ref_line .= $kekka_refer_tmp[$i];
	    }
	    elsif ($flag_ref{$i} < $prev_flag_ref) {
		$ref_line .= " " . $kekka_refer_tmp[$i] . " " ; 
	    }
	    else {
		$ref_line .= " " . $kekka_refer_tmp[$i];
	    }

	    $prev_flag_ref = $flag_ref{$i};
	}
	else {
	    $rfcount = 0;

	    $ref_line .= " " . $kekka_refer_tmp[$i] . " ";
	}
    }

    @res_lines = split(' ', $res_line);
    @ref_lines = split(' ', $ref_line);

    $rcount2 = $#ref_lines + 1;
    $hcount2 = $#res_lines + 1;

    $ref2 += $rcount2;
    $hyp2 += $hcount2;

    ($kx2) = &dp2;		# 結合後、再びアラインメントを取る

    # 読みでアラインメントを取った結果、併記読みの部分で置換誤りに
    # なっているところについて、正解判定をやり直す。
    # (併記の中に正解が含まれていれば、OKとする。)
    for ($i = $kx2 - 1; $i >= 0; $i--) {
	if ($status2[$i] eq "S") {
	    if ($kekka_result2[$i] =~ /\{.+\}/ &&
		$kekka_refer2[$i] =~ /\{.+\}/) {
		$kekka_result2[$i] =~ /(.*)\{(.+)\}(.*)/;
		$result_head = $1;
		$result_yomi = $2;
		$result_tail = $3;
		@resyomis = split('\/', $result_yomi);

		$kekka_refer2[$i] =~ /(.*)\{(.+)\}(.*)/;
		$refer_head = $1;
		$refer_yomi = $2;
		$refer_tail = $3;
		@refyomis = split('\/', $refer_yomi);

		foreach $resyomi (@resyomis) {
		    if ($result_head) {
			$resyomi = $result_head . $resyomi;
		    }
		    if ($result_tail) {
			$resyomi = $resyomi . $result_tail;
		    }

		    foreach $refyomi (@refyomis) {
			if ($refer_head) {
			    $refyomi = $refer_head . $refyomi;
			}
			if ($result_tail) {
			    $refyomi = $refyomi . $refer_tail;
			}

			$status2[$i] = "C" if $resyomi eq $refyomi;
		    }
		}
	    }
	    elsif ($kekka_result2[$i] =~ /\{.+\}/ &&
		   $kekka_refer2[$i] !~ /\{.+\}/) {
		$kekka_result2[$i] =~ /(.*)\{(.+)\}(.*)/;
		$result_head = $1;
		$result_yomi = $2;
		$result_tail = $3;
		@resyomis = split('\/', $result_yomi);

		$ref_yomi = $kekka_refer2[$i];

		foreach $resyomi (@resyomis) {
		    if ($result_head) {
			$resyomi = $result_head . $resyomi;
		    }
		    if ($result_tail) {
			$resyomi = $resyomi . $result_tail;
		    }
		    $status2[$i] = "C" if $resyomi eq $ref_yomi;
		}
	    }
	    elsif ($kekka_result2[$i] !~ /\{.+\}/ &&
		   $kekka_refer2[$i] =~ /\{.+\}/) {
		$res_yomi = $kekka_result2[$i];

		$kekka_refer2[$i] =~ /(.*)\{(.+)\}(.*)/;
		$refer_head = $1;
		$refer_yomi = $2;
		$refer_tail = $3;
		@refyomis = split('\/', $refer_yomi);

		foreach $refyomi (@refyomis) {
		    if ($refer_head) {
			$refyomi = $refer_head . $refyomi;
		    }
		    if ($refer_tail) {
			$refyomi = $refyomi . $refer_tail;
		    }
		    $status2[$i] = "C" if $refyomi eq $res_yomi;
		}
	    }
	    else {
		;
	    }
	}
    }

    for ($i = $kx2 - 1; $i >= 0; $i--) {
	local($hlen, $rlen, $lngth, $format2);
	$hlen = length($kekka_result2[$i]);
	$rlen = length($kekka_refer2[$i]);
	$lngth = $hlen > $rlen ? $hlen : $rlen;
	$format2 = "%-" . $lngth . "s ";

	$status_str2 .= sprintf($format2, $status2[$i]);
	$result_str2 .= sprintf($format2, $kekka_result2[$i]);
	$refer_str2 .= sprintf($format2, $kekka_refer2[$i]);
    }

    $check_s = "";
    undef(@status_tmp);
    undef(@kekka_result_tmp);
    undef(@kekka_refer_tmp);
}
