#!/bin/sh
#
# $1: Julius log file
# $2: reference file
# output summary in stdout
#
perl=/usr/bin/perl
align_opt='-u morpheme -c -f kanji'

###################
dir=`dirname $0`
rdir=`dirname $1`/result.`basename $1`
fulldir=`${dir}/mkfullpath.pl ${dir}`

if ! test -d ${rdir}; then
  mkdir ${rdir}
fi

# output specified filenames
echo log: `${dir}/mkfullpath.pl $1`
echo ref: $2

echo '------------------------------------------------------------------------------'
echo '           Snt      Corr      Acc      Sub      Del      Ins      Err    S.Err'
echo '------------------------------------------------------------------------------'

# compute accuracy and output (final, 1st pass)
echo 'final (2pass)'
nkf -e $1 | ${perl} ${dir}/mkhyp.pl -p 2 > ${rdir}/hypo2
${perl} ${dir}/align.pl ${align_opt} -r $2 ${rdir}/hypo2 > ${rdir}/align2
(cd ${rdir}; ${fulldir}/score.pl align2)
tail -2 ${rdir}/align2.scr/align2.sys

echo 1st pass
nkf -e $1 | ${perl} ${dir}/mkhyp.pl -p 1 > ${rdir}/hypo1
${perl} ${dir}/align.pl ${align_opt} -r $2 ${rdir}/hypo1 > ${rdir}/align1
(cd ${rdir}; ${fulldir}/score.pl align1)
tail -2 ${rdir}/align1.scr/align1.sys

echo evaluation results saved to \"${rdir}/\"
