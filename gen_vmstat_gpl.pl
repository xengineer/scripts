#!/usr/bin/perl
######################################################################
#
# [概要] Generate gnuplot script file from vmstat output
#
# $Header:$
#
# [Usage] perl gen_vmstat_gpl.pl [Options] 
#
# Author: Hideaki Nemoto (c) CyberAgent, Inc. All Rights Reserved. 2010
#
#

use Getopt::Long;
use File::Basename;
use File::Path;


######################################################################
# 以下の$revの値はcvsで自動的に設定されるため操作する必要は無い。
$rev     = '$Header:$';
$rev     =~ s/\$//g;

######################################################################
# 日付
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year += 1900;
$mon += 1;
$daytime="$year$mon$mday$hour$min$sec";

######################################################################
# 定数定義
$TEMPDIR    = "gen_graph_vmstat_$daytime";
$FILEPS    = "vmstat_$daytime.gpl";
$FILEIMG    = "vmstat_img_$daytime.gpl";
$ELMDAT        = "elm.dat";
$GPLFILEPS = "$TEMPDIR/$FILEPS";
$GPLFILEIMG = "$TEMPDIR/$FILEIMG";
$ELMDATFILE    = "$TEMPDIR/$ELMDAT";
#$PS2PDF = "/usr/bin/ps2pdf";
$GNUPLOT = "/usr/bin/gnuplot";
$XPDF = "/usr/bin/xpdf";
$GV = "/usr/bin/gv";

######################################################################
#
# 引数の処理
#

# 引数の解析 ("--"or"-"をつける)
GetOptions( "version"           => \$version,
            "f=s"               => \$fn_vmstat,
            "v"                 => \$verbose,
            "help"              => \$help,
            "h"                 => \$help);

# --versionが指定された場合
if ( $version ) {
    print "$rev\n";
    exit 0;
}

# --help, --h, -help, -h が指定された場合
# もしくは引数の数が誤っている場合
#if ( $help or $#ARGV!=0) {
if ( $help ) {
    print "[Usage] perl ./ [Options]\n";
    print "[Option] :\n";
    print "  -f {filename}        : 処理するファイル名を指定\n";
    print "  -b {bin size}        : binのsizeを指定(default:50kB)\n";
    print "  --version            : 自分のversionを表示\n";
    print "  --help,--h,-help,-h  : scriptの使用方法と、optionの一覧を表示\n";
    exit 0;
}

# -fが指定されなかった場合
if ( !defined $fn_vmstat ) {
    print "ファイルを指定してください";
    exit -1;
}

######################################################################
# 以下main処理

# Fileを開く
open ( FH , "<$fn_vmstat") || die "ファイル($fn_vmstat)を開けません :$!\n";
my @vmstat_dat = <FH>;
close FH;

system("mkdir $TEMPDIR");
open ( FH1 , ">$ELMDATFILE") || die "ファイル($ELMDATFILE)を開けません :$!\n";

# 各種情報取得済かどうか確認フラグ
$PROCINFOFLAG = 0;
$numlines = 0;

while(@vmstat_dat)
{
  my $line = shift(@vmstat_dat);
  chomp($line);

  # comment/空行は飛ばす
  #if($line =~ m/^\s*$/)
  if($line =~ m/(^\s*$|^\s*#)/)
  {
    next;
  }
  # procって書いてある行をparse
  elsif($line =~ m/^\s*procs.*/)
  {
    next;
  }
  # r b swpd等の項目のparse
  elsif($line =~ /\s*((([a-z]+\s+)+)\w+$)/ && $PROCINFOFLAG == 0)
  {
    $elem = $1;
    @elems = split(/\s+/, $elem);
    printf FH1 "%13d", $numlines;
    printf FH1 ("%13.2f" x @elems), @elem;
    printf FH1 "\n";
    $PROCINFOFLAG = 1;
  }
  elsif($line =~ /\s*(((\d+\s+)+)\d+$)/)
  {
    $analdata = $1;
    @analdats = split(/\s+/, $analdata);
    $numlines++;
    printf FH1 "%13d", $numlines;
    printf FH1 ("%13.2f" x @analdats), @analdats;
    printf FH1 "\n";
#    print "@analdats\n";
  }
}

close FH1;

open ( FHPDF , ">$GPLFILEPS") || die "ファイル($CPUGPLFILEPS)を開けません :$!\n";
open ( FHPNG , ">$GPLFILEIMG") || die "ファイル($CPUGPLFILEIMG)を開けません :$!\n";

$numelems = @elems;

###############################################################################
# グラフpng生成用コード
#
for($i = 0; $i < $numelems; $i++)
{
  $FNAME = "$GPLFILEIMG"."_$i";
  $PNGNAME = "$GPLFILEIMG"."_$i".".png";
  open ( FHPNG , ">$FNAME") || die "ファイル($FNAME)を開けません :$!\n";
  print FHPNG "# General Settings\n";
  print FHPNG "set terminal png \n";
  print FHPNG "set output \"$PNGNAME\"\n";
  print FHPNG "set grid\n";
  print FHPNG "set xlabel \"sec\"\n";
  print FHPNG "set xrange[0:$xmax]\n";
  print FHPNG "set autoscale y\n";
  print FHPNG "set title \"vmstat\"\n";
  $indx = $i + 2;
  print FHPNG "plot \"$ELMDATFILE\" using 1:$indx title \"$elems[$i]\"  w lp\n";
  print FHPNG "\n";
  close FHPNG;
  system("$GNUPLOT $FNAME");
}

open ( FHPDF , ">$GPLFILEPS") || die "ファイル($GPLFILEPS)を開けません :$!\n";
###############################################################################
# グラフps生成用コード
#
print FHPDF "# General Settings\n";
print FHPDF "set term postscript color solid\n";
print FHPDF "set output \"$GPLFILEPS.ps\"\n";
for($i = 0; $i < $numelems; $i++)
{
  print FHPDF "set grid\n";
  print FHPDF "set xlabel \"sec\"\n";
  print FHPDF "set xrange[0:$xmax]\n";
  print FHPDF "set autoscale y\n";
  print FHPDF "set title \"vmstat\"\n";
  $indx = $i + 2;
  print FHPDF "plot \"$ELMDATFILE\" using 1:$indx title \"$elems[$i]\"  w lp\n";
  print FHPDF "\n";
}
close FHPDF;

system("$GNUPLOT $GPLFILEPS");
system("$GV $GPLFILEPS.ps");

sub ceil {
   my $var = shift;
   my $a = 0;
   $a = 1 if($var > 0 and $var != int($var));
   return int($var + $a);
}

