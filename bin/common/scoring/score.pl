#!/usr/bin/perl

# アラインメントファイル(*.ali)から、認識率等を算出する。
# JNAS用
#
# 使用法
# % score.pl alignment_file

$system_name = $ARGV[0];
$system_name =~ s/^.*\///;
$tmp = $system_name;
$tmp =~ s/\.[^\.]+$//;
$outsysfile = $tmp . ".sys";
$outsysdtlfile = $tmp . ".sys_dtl";

$outdir = $system_name . ".scr";

if (! -d $outdir) {
    system("mkdir $outdir");
}

$prev_speaker = "";

while (<>) {
    chop;

    if (/^id: ([^-]+)-([^-]+)$/) {
	$speaker = $1;
	$snt_num = $2;
	$snt{$speaker}++;
	$total_snt++;

	push(@spkr, $speaker) if $snt{$speaker} == 1;
    }

    if (/^REF:\s+(.*)/) {
	$ref_line = $_;
	$ref_str = $1;
	@reference = split(' ', $ref_str);
	$ref_count = $#reference + 1;
	$rc{$speaker} += $ref_count;
	$total_ref += $ref_count;
    }

    if (/^HYP:\s+(.*)/) {
	$hyp_line = $_;
	$hyp_str = $1;
	@hypothesis = split(' ', $hyp_str);
	$hyp_count = $#hypothesis + 1;
	$hc{$speaker} += $hyp_count;
	$total_hyp += $hyp_count;
    }

    if (/^EVAL:\s+(.*)/) {
	$eva_line = $_;
	$eva_str = $1;
	@evaluation = split(' ', $eva_str);
	$eva_count = $#evaluation + 1;
	$ec{$speaker} += $eva_count;
	$total_eva += $eva_count;

	($c, $s, $d, $i, $e,
	 $confusion, $deletion, $insertion, $misrecognition, $substitution,
	 $spconfusion, $spdeletion, $spinsertion,
	 $spmisrecognition, $spsubstitution) = &cnt;

	$tconfusion{$speaker} .= $spconfusion;
	$tdeletion{$speaker} .= $spdeletion;
	$tinsertion{$speaker} .= $spinsertion;
	$tmisrecognition{$speaker} .= $spmisrecognition;
	$tsubstitution{$speaker} .= $spsubstitution;

	$total_confusion .= $confusion;
	$total_deletion .= $deletion;
	$total_insertion .= $insertion;
	$total_misrecognition .= $misrecognition;
	$total_substitution .= $substitution;

	if ($s >= 1 || $d >= 1 || $i >=1) {
	    $snterr{$speaker}++;
	    $total_snterr++;
	}

	if ($s >= 1) {
	    $sntsub{$speaker}++;
	    $total_sntsub++;
	}

	if ($d >= 1) {
	    $sntdel{$speaker}++;
	    $total_sntdel++;
	}

	if ($i >= 1) {
	    $sntins{$speaker}++;
	    $total_sntins++;
	}

	$tc{$speaker} += $c;
	$ts{$speaker} += $s;
	$td{$speaker} += $d;
	$ti{$speaker} += $i;
	$te{$speaker} += $e;

	$total_c += $c;
	$total_s += $s;
	$total_d += $d;
	$total_i += $i;
	$total_e += $e;

	&prntsnt;
    }
}

&score;

sub cnt {
    local($c, $s, $d, $i, $o, $e);
    local($confusion, $deletion, $insertion, $misrecognition, $substitution);
    local($spconfusion, $spdeletion, $spinsertion,
	  $spmisrecognition, $spsubstitution);

    foreach $eva (@evaluation) {
	if ($eva eq "C") {
	    $c++;

	    shift(@reference);
	    shift(@hypothesis);
	}
	elsif ($eva eq "S") {
	    $s++;

	    $ref = shift(@reference);
	    $hyp = shift(@hypothesis);

	    $conf = $ref . ":" . $hyp;
	    $spconf = $speaker . ":" . $conf;
	    $cnt_conf{$conf}++;
	    $cnt_spconf{$spconf}++;
	    $confusion .=  $conf . " " if $cnt_conf{$conf} == 1;
	    $spconfusion .=  $conf . " " if $cnt_spconf{$spconf} == 1;

	    $spmisr = $speaker . ":" . $ref;
	    $cnt_misr{$ref}++;
	    $cnt_spmisr{$spmisr}++;
	    $misrecognition .= $ref . " " if $cnt_misr{$ref} == 1;
	    $spmisrecognition .= $ref . " " if $cnt_spmisr{$spmisr} == 1;

	    $spsubs = $speaker . ":" . $hyp;
	    $cnt_subs{$hyp}++;
	    $cnt_spsubs{$spsubs}++;
	    $substitution .= $hyp . " " if $cnt_subs{$hyp} == 1;
	    $spsubstitution .= $hyp . " " if $cnt_spsubs{$spsubs} == 1;
	}
	elsif ($eva eq "D") {
	    $d++;

	    $ref = shift(@reference);

	    $spdele = $speaker . ":" . $ref;
	    $cnt_dele{$ref}++;
	    $cnt_spdele{$spdele}++;
	    $deletion .=  $ref . " " if $cnt_dele{$ref} == 1;
	    $spdeletion .=  $ref . " " if $cnt_spdele{$spdele} == 1;
	}
	elsif ($eva eq "I") {
	    $i++;

	    $hyp = shift(@hypothesis);

	    $spinse = $speaker . ":" . $hyp;
	    $cnt_inse{$hyp}++;
	    $cnt_spinse{$spinse}++;
	    $insertion .=  $hyp . " " if $cnt_inse{$hyp} == 1;
	    $spinsertion .=  $hyp . " " if $cnt_spinse{$spinse} == 1;
	}
	else {
	    die "alignment file is wrong.\n";
	}
    }

    $e = $s + $d + $i;

    ($c, $s, $d, $i, $e,
     $confusion, $deletion, $insertion, $misrecognition, $substitution,
     $spconfusion, $spdeletion, $spinsertion, $spmisrecognition, $spsubstitution);
}

sub prntsnt {
    if ($speaker ne $prev_speaker) {
	$outsntfile = $speaker . ".snt";
	open(SNT, ">$outdir/$outsntfile");
	select((select(SNT), $~ = "SNTT")[0]);
	write(SNT);

	$prev_speaker = $speaker;
    }
    else {
	;
    }

    print SNT "SPEAKER  $speaker\n";
    print SNT "SENTENCE $snt_num\n\n";

    print SNT "$ref_line\n";
    print SNT "$hyp_line\n";
    print SNT "$eva_line\n\n";

    $corr = ($c / $ref_count) * 100;
    $sub = ($s / $ref_count) * 100;
    $del = ($d / $ref_count) * 100;
    $ins = ($i / $ref_count) * 100;
    $err = ($e / $ref_count) * 100;

    select((select(SNT), $~ = "SNT")[0]);
    write(SNT);
}

sub score {
    open(SYS, ">$outdir/$outsysfile");

    foreach $sp (@spkr) {
	@confusions = split(' ', $tconfusion{$sp});
	@deletions = split(' ', $teletion{$sp});
	@insertions = split(' ', $tinsertion{$sp});
	@misrecognitions = split(' ', $tmisrecognition{$sp});
	@substitutions = split(' ', $tsubstitution{$sp});

	$corr = ($tc{$sp} / $rc{$sp}) * 100;
	$acc = (($rc{$sp} - $ts{$sp} - $td{$sp} - $ti{$sp}) / $rc{$sp}) * 100;

	$sub = ($ts{$sp} / $rc{$sp}) * 100;
	$del = ($td{$sp} / $rc{$sp}) * 100;
	$ins = ($ti{$sp} / $rc{$sp}) * 100;

	$err = ($te{$sp} / $rc{$sp}) * 100;

	$serr = ($snterr{$sp} / $snt{$sp}) * 100;
	$ssub = ($sntsub{$sp} / $snt{$sp}) * 100;
	$sdel = ($sntdel{$sp} / $snt{$sp}) * 100;
	$sins = ($sntins{$sp} / $snt{$sp}) * 100;

	&prntsum;

	select((select(SYS), $^ = "SYS_TOP", $~ = "SYS")[0]);
	write(SYS);
    }

    @confusions = split(' ', $total_confusion);
    @deletions = split(' ', $total_deletion);
    @insertions = split(' ', $total_insertion);
    @misrecognitions = split(' ', $total_misrecognition);
    @substitutions = split(' ', $total_substitution);

    $sp = "Sum/Avg";
    $snt{$sp} = $total_snt;

    $corr = ($total_c / $total_ref) * 100;
    $acc = (($total_ref - $total_s - $total_d - $total_i) / $total_ref) * 100;

    $sub = ($total_s / $total_ref) * 100;
    $del = ($total_d / $total_ref) * 100;
    $ins = ($total_i / $total_ref) * 100;

    $err = ($total_e / $total_ref) * 100;

    $serr = ($total_snterr / $total_snt) * 100;
    $ssub = ($total_sntsub / $total_snt) * 100;
    $sdel = ($total_sntdel / $total_snt) * 100;
    $sins = ($total_sntins / $total_snt) * 100;

    &prntsysdtl;

    select((select(SYS), $^ = "SYS_TOP", $~ = "SYS2")[0]);
    write(SYS);
}

sub prntsum {
    $outsumfile = $sp . ".sum";
    open(SUM, ">$outdir/$outsumfile");

    select((select(SUM), $~ = "SUM")[0]);
    write(SUM);

    $num = $r = "";

    $title = "CONFUSION PAIRS";
    $all = $#confusions + 1;

    select((select(SUM), $~ = "SUM2")[0]);
    write(SUM);

    foreach $pair (@confusions) {
	$num++;
	$sppair = $sp . ":" . $pair;
	$count = $cnt_spconf{$sppair};
	($r, $h) = split(':', $pair);

	print SUM "$num: $count  $r -> $h\n";
    }

    $num = $r = "";

    $title = "INSERTED WORDS";
    $all = $#insertions + 1;
    select((select(SUM), $~ = "SUM2")[0]);
    write(SUM);

    foreach $h (@insertions) {
	$num++;
	$sph = $sp . ":" . $h;
	$count = $cnt_spinse{$sph};

	print SUM "$num: $count  -> $h\n";
    }

    $num = $r = "";

    $title = "DELETED WORDS";
    $all = $#deletions + 1;
    select((select(SUM), $~ = "SUM2")[0]);
    write(SUM);

    foreach $h (@deletions) {
	$num++;
	$sph = $sp . ":" . $h;
	$count = $cnt_spdele{$sph};

	print SUM "$num: $count  -> $h\n";
    }

    $num = $r = "";

    $title = "MISRECOGNIZED WORDS";
    $all = $#misrecognitions + 1;
    select((select(SUM), $~ = "SUM2")[0]);
    write(SUM);

    foreach $h (@misrecognitions) {
	$num++;
	$sph = $sp . ":" . $h;
	$count = $cnt_spmisr{$sph};

	print SUM "$num: $count  -> $h\n";
    }

    $num = $r = "";

    $title = "SUBSTITUTED WORDS";
    $all = $#substitutions + 1;
    select((select(SUM), $~ = "SUM2")[0]);
    write(SUM);

    foreach $h (@substitutions) {
	$num++;
	$sph = $sp . ":" . $h;
	$count = $cnt_spsubs{$sph};

	print SUM "$num: $count  -> $h\n";
    }
}

sub prntsysdtl {
    open(SYSDTL, ">$outdir/$outsysdtlfile");

    select((select(SYSDTL), $~ = "SYSDTL")[0]);
    write(SYSDTL);

    $title = "CONFUSION PAIRS";
    $all = $#confusions + 1;
    select((select(SYSDTL), $~ = "SYSDTL2")[0]);
    write(SYSDTL);

    $num = $r = "";

    foreach $pair (@confusions) {
	$num++;
	$count = $cnt_conf{$pair};
	($r, $h) = split(':', $pair);

	print SYSDTL "$num: $count  $r -> $h\n";
    }

    $num = $r = "";

    $title = "INSERTED WORDS";
    $all = $#insertions + 1;
    select((select(SYSDTL), $~ = "SYSDTL2")[0]);
    write(SYSDTL);

    foreach $h (@insertions) {
	$num++;
	$count = $cnt_inse{$h};

	print SYSDTL "$num: $count  -> $h\n";
    }

    $num = $r = "";

    $title = "DELETED WORDS";
    $all = $#deletions + 1;
    select((select(SYSDTL), $~ = "SYSDTL2")[0]);
    write(SYSDTL);

    foreach $h (@deletions) {
	$num++;
	$count = $cnt_dele{$h};

	print SYSDTL "$num: $count  -> $h\n";
    }

    $num = $r = "";

    $title = "MISRECOGNIZED WORDS";
    $all = $#misrecognitions + 1;
    select((select(SYSDTL), $~ = "SYSDTL2")[0]);
    write(SYSDTL);

    foreach $h (@misrecognitions) {
	$num++;
	$count = $cnt_misr{$h};

	print SYSDTL "$num: $count  -> $h\n";
    }

    $num = $r = "";

    $title = "SUBSTITUTED WORDS";
    $all = $#substitutions + 1;
    select((select(SYSDTL), $~ = "SYSDTL2")[0]);
    write(SYSDTL);

    foreach $h (@substitutions) {
	$num++;
	$count = $cnt_subs{$h};

	print SYSDTL "$num: $count  -> $h\n";
    }
}


################ format ################

format SNTT = 
================================================================================

    SENTENCE LEVEL REPORT FOR THE SYSTEM:
       Name: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
             $system_name
       Desc: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
             $system_name

================================================================================

.

format SNT = 
Correct           = @###.##%  @####  (@####)
                    $corr,    $c,   $tc{$speaker}

substitutions     = @###.##%  @####  (@####)
                    $sub,     $s,   $ts{$speaker}

Deletions         = @###.##%  @####  (@####)
                    $del,     $d,   $td{$speaker}

Insertions        = @###.##%  @####  (@####)
                    $ins,     $i,   $ti{$speaker}

Errors            = @###.##%  @####  (@####)
                    $err,     $e,   $te{$speaker}

Ref. words        =           @####  (@####)
                              $ref_count, $rc{$speaker} 
Hyp. words        =           @####  (@####)
                              $hyp_count, $hc{$speaker}
Aligned words     =           @####  (@####)
                              $eva_count, $ec{$speaker}

--------------------------------------------------------------------------------

.

format SYS_TOP =

                    SYSTEM SUMMARY PERCENTAGES BY SPEAKER
------------------------------------------------------------------------------
SPKR       Snt      Corr      Acc      Sub      Del      Ins      Err    S.Err
------------------------------------------------------------------------------
.

format SYS = 
@<<<<<<<  @###   @###.##  @###.##  @###.##  @###.##  @###.##  @###.##  @###.##
$sp, $snt{$sp}, $corr, $acc, $sub, $del, $ins, $err, $serr
.

format SYS2 = 
==============================================================================
@<<<<<<<@#####   @###.##  @###.##  @###.##  @###.##  @###.##  @###.##  @###.##
$sp, $snt{$sp}, $corr, $acc, $sub, $del, $ins, $err, $serr
------------------------------------------------------------------------------
.

format SUM = 
SCORING FOR SPEAKER: @<<<<<
                     $sp
     of @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        $system_name

SENTENCE RECOGNITION PERFORMANCE

 sentences                                    @####
                                              $snt{$sp} 
 with errors                       @###.##%  (@####)
                                   $serr,     $snterr{$sp} 

   with substitutions              @###.##%  (@####)
                                   $ssub,     $sntsub{$sp}

   with deletions                  @###.##%  (@####)
                                   $sdel,     $sntdel{$sp}

   with insertions                 @###.##%  (@####)
                                   $sins,     $sntins{$sp}


WORD RECOGNITION PERFORMANCE

Percent Total Error      =  @###.##%  (@####)
                            $err,      $te{$sp}

Percent Correct          =  @###.##%  (@####)
                            $corr,     $tc{$sp}
Percent Substitution     =  @###.##%  (@####)
                            $sub,      $ts{$sp}
Percent Deletions        =  @###.##%  (@####)
                            $del,      $td{$sp}
Percent Insertions       =  @###.##%  (@####)
                            $ins,      $ti{$sp}
Percent Word Accuracy    =  @###.##%
                            $acc


Ref. words               =            (@####)
                                       $rc{$sp}
Hyp. words               =            (@####)
                                       $hc{$sp}
Aligned words            =            (@####)
                                       $ec{$sp} 

.

format SUM2 =

@<<<<<<<<<<<<<<<<<<<<     (@####)
$title,             $all

.

format SYSDTL = 
DETAILED OVERALL REPORT FOR THE SYSTEM @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                       $system_name

SENTENCE RECOGNITION PERFORMANCE

 sentences                                    @########
                                              $total_snt
 with errors                       @###.##%  (@########)
                                   $serr,     $total_snterr

   with substitutions              @###.##%  (@########)
                                   $ssub,     $total_sntsub

   with deletions                  @###.##%  (@########)
                                   $sdel,     $total_sntdel

   with insertions                 @###.##%  (@########)
                                   $sins,     $total_sntins


WORD RECOGNITION PERFORMANCE

Percent Total Error      =  @###.##%  (@########)
                            $err,      $total_e

Percent Correct          =  @###.##%  (@########)
                            $corr,     $total_c
Percent Substitution     =  @###.##%  (@########)
                            $sub,      $total_s
Percent Deletions        =  @###.##%  (@########)
                            $del,      $total_d
Percent Insertions       =  @###.##%  (@########)
                            $ins,      $total_i
Percent Word Accuracy    =  @###.##%
                            $acc


Ref. words               =            (@########)
                                       $total_ref
Hyp. words               =            (@########)
                                       $total_hyp
Aligned words            =            (@########)
                                       $total_eva
.

format SYSDTL2 =

@<<<<<<<<<<<<<<<<<<<<     (@########)
$title,             $all

.
