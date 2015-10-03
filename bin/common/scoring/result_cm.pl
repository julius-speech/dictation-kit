#!/usr/bin/perl

$gstep = 0.05;

@corr = @sub = @ins = ();
$n_corr = $n_sub = $n_ins = $n_del = 0;
$cm_exist = 0;

$cmalpha = 0.0;			# only for ID

while(<>) {
    chomp;
    if (/^id: (.*)$/) {
	$id = split(/[ \t\n]+/, $1);
    } elsif (/^REF:\s+(.*)$/) {
	@ref = split(/[ \t\n]+/, $1);
    } elsif (/^HYP:\s+(.*)$/) {
	@hyp = split(/[ \t\n]+/, $1);
    } elsif (/^EVAL:\s+(.*)$/) {
	@result = split(/[ \t\n]+/, $1);
    } elsif (/^CMSCORE:\s+(.*)$/) {
	@cmscore = split(/[ \t\n]+/, $1);
	@mark = ();
	@res = @result;
	while(@res) {
	    $r = shift(@res);
	    if ($r eq "D") {
		&reg($r, 0);
	    } else {
		$c = shift(@cmscore);
		&reg($r, $c);
	    }
	}
	$cm_exist = 1;
    } elsif (/^CMSCORE\[(.*)\]:\s+(.*)$/) {
	$cmalpha = $1;
	@cmscore = split(/[ \t\n]+/, $2);
	@mark = ();
	@res = @result;
	while(@res) {
	    $r = shift(@res);
	    if ($r eq "D") {
		&reg($r, 0);
	    } else {
		$c = shift(@cmscore);
		&reg($r, $c);
	    }
	}
	$cm_exist = 1;
    }
}

if ($cm_exist == 1) {
    &output_all();
}

sub reg {
    local ($mark, $score) = @_;
    local ($v);

    $v = int ($score / $gstep);
    if ($mark eq "C") {
	$tcorr{$cmalpha}[$v]++;
	$tn_corr{$cmalpha}++;
    } elsif ($mark eq "S") {
	$tsub{$cmalpha}[$v]++;
	$tn_sub{$cmalpha}++;
    } elsif ($mark eq "I") {
	$tins{$cmalpha}[$v]++;
	$tn_ins{$cmalpha}++;
    } elsif ($mark eq "D") {
	$tn_del{$cmalpha}++;
    }
}

sub output_all {
    local($n, @alphas, $c, $oldc);
    @alphas = sort(keys %tcorr, keys %tsub, keys %tins);
    $oldc = -1.0;
    foreach $c (@alphas) {
	next if ($c == $oldc);
	print "cmalpha = $c\n";
	$n_corr = $tn_corr{$c};
	$n_sub = $tn_sub{$c};
	$n_ins = $tn_ins{$c};
	$n_del = $tn_del{$c};
	for ($n = int(1.0/$gstep); $n >=0; $n--) {
	    $corr[$n] = $tcorr{$c}[$n];
	    $sub[$n] = $tsub{$c}[$n];
	    $ins[$n] = $tins{$c}[$n];
	}

	&output();
	$oldc = $c;
    }
}
	

sub output {
    local($n, $c, $s, $i, $num_ref);
    local($fa, $fr, $serr, $werr);

    print "==============================================================================\n";
    print "    || Accepted words| Accumulated total  |            FA+               FA+\n";
    print "thrs|| #cor #sub #ins| #cor #sub #ins #del| FA   SErr  SErr  WErr  FR    FR\n";
    print "==============================================================================\n";
    $num_ref = $n_corr + $n_sub + $n_del;
    $c = $s = $i = $d = 0;
    for ($n = int(1.0/$gstep); $n >=0; $n--) {
	$c += $corr[$n];
	$s += $sub[$n];
	$i += $ins[$n];
	$d = $num_ref - $c - $s;

	if ($c + $s + $s == 0) {
	    $fa = 0.0;
	} else {
	    $fa = 100 * ($s + $i) / ($c + $s + $i);
	}
	$fr = 100 * ($n_corr - $c) / $n_corr;
	$serr = 100 - 100 * $c / $num_ref;
	$werr = 100 - 100 * ($c - $i) / $num_ref;

	printf("%4.2f|| %4d %4d %4d| %4d %4d %4d %4d", $n * $gstep, $corr[$n], $sub[$n], $ins[$n], $c, $s, $i, $d);
	printf("|%5.2f %5.2f %5.2f %5.2f %5.2f %5.2f\n", $fa, $serr, $fa + $serr, $werr, $fr, $fa+$fr);
    }
    print "==============================================================================\n";
}

