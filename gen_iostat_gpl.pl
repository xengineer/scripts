#!/usr/bin/perl
######################################################################
#
# [概要] Generate gnuplot script file from iostat output
#
# $Header:$
#
# [Usage] perl gen_iostat_gpl.pl [Options] 
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
$TEMPDIR    = "gen_graph_iostat_$daytime";
$FILEPS    = "iostat_$daytime.gpl";
$FILEIMG    = "iostat_img_$daytime.gpl";
$CPU        = "cpuelm.dat";
$DEV        = "develm.dat";
$CPUGPLFILEPS = "$TEMPDIR/$FILEPS";
$CPUGPLFILEIMG = "$TEMPDIR/$FILEIMG";
$DEVGPLFILEPS = "$TEMPDIR/dev_$FILEPS";
$DEVGPLFILEIMG = "$TEMPDIR/dev_$FILEIMG";
$CPUFILE    = "$TEMPDIR/$CPU";
$DEVFILE    = "$TEMPDIR/$DEV";
#$GPLFILEPS = "iostat_$daytime.gpl";
#$GPLFILEIMG = "iostat_img_$daytime.gpl";
#$CPUFILE = "cpuelm.dat";
#$DEVFILE = "develm.dat";
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
            "f=s"               => \$fn_iostat,
            "dev=s"             => \$dev,
            "b=s"               => \$bin,
            "max=s"             => \$max,
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
if ( !defined $fn_iostat ) {
    print "ファイルを指定してください";
    exit -1;
}

if ( !defined $bin ) {
    $bin=50;
    print "";
}

if ( !defined $dev ) {
    $dev = "sda1";
    print "Drawing a graph for /dev/$dev\n";
}

######################################################################
# 以下main処理

# Fileを開く
open ( FH , "<$fn_iostat") || die "ファイル($fn_iostat)を開けません :$!\n";
my @iostat_dat = <FH>;
close FH;

system("mkdir $TEMPDIR");
open ( FH1 , ">$CPUFILE") || die "ファイル($CPUFILE)を開けません :$!\n";
open ( FH2 , ">$DEVFILE") || die "ファイル($DEVFILE)を開けません :$!\n";

# CPU/Device情報取得済かどうか確認フラグ
$CPUFLAG = 0;
$CPU1stFLAG = 0;
$DEVFLAG = 0;

$numlines_cpu = 0;
$numlines_dev = 0;

while(@iostat_dat)
{
  my $line = shift(@iostat_dat);
  chomp($line);

  # comment/空行は飛ばす
  #if($line =~ m/^\s*$/)
  if($line =~ m/(^\s*$|^\s*#)/)
  {
    next;
  }
  # CPUって書いてある行をparse
  #elsif($line =~ m/^\s*CPU.*:\s+(.+)/)
  elsif($line =~ m/^\s*.*(CPU|cpu).*:\s+(.+)/)
  {
    if($CPU1stFLAG == 0)
    {
      $CPU1stFLAG = 1;
      $CPUFLAG = 1;
      $elm = $2;
      @elmlst = split(/\s+/,$elm);
      $numelm = @elmlst;
      #print FH1 "#linenum   @elmlst\n";
      printf FH1 ("%10s" x @elmlst), @elmlst;
      printf FH1 "\n";
    }
    else
    {
      $CPUFLAG = 1;
    }
  }
#CPU平均:  %user   %nice    %sys %iowait   %idle
#           0.76    0.01    1.09    0.41   97.73
  # 実際にCPU使用率データがある行をparse
  elsif($line =~ /\s+(.+)/ && $CPUFLAG == 1)
  {
    $cpudat = $1;
    @cpudats = split(/\s+/, $cpudat);
    $numlines_cpu++;
    printf FH1 "%10d", $numlines_cpu;
    printf FH1 ("%10.2f" x @cpudats), @cpudats;
    printf FH1 "\n";
    $CPUFLAG = 0;
  }
  # 該当IO device line parse
  elsif($line =~ /$dev\s+(.+)/)
  {
    $dvcelmdat = $1; 
    @devdat = split(/\s+/, $dvcelmdat); 

    if($lineprev =~ m/.+:\s+(.*)/ && $DEVFLAG == 0)
    {
      $develm = $1;
      @develmlst = split(/\s+/,$develm);
      $DEVFLAG = 1;
      $numdevelm = @develmlst;
      #print FH2 "#@develmlst\n";
      printf FH2 "%10d", $numlines_dev;
      printf FH2 ("%10s" x @develmlst), @develmlst;
      printf FH2 "\n";
    }
    else
    {
      #print FH2 "@devdat\n";
      $numlines_dev++;
      printf FH2 "%10d", $numlines_dev;
      printf FH2 ("%10.2f" x @devdat), @devdat;
      printf FH2 "\n";
    }
    next;
  }
  # それ以外
  else
  {
    $lineprev = $line;
  }
}

$xmax = ceil($numlines_cpu / 100) * 100;

# For Debug
#for($i = 0;$i < @elmlst; $i++)
#{
#  print "$elmlst[$i]\n";
#}
#for($i = 0;$i < @develmlst; $i++)
#{
#  print "$develmlst[$i]\n";
#}
#  print "$numdevelm\n";

close FH1;
close FH2;

open ( FHPDF , ">$CPUGPLFILEPS") || die "ファイル($CPUGPLFILEPS)を開けません :$!\n";
open ( FHPNG , ">$CPUGPLFILEIMG") || die "ファイル($CPUGPLFILEIMG)を開けません :$!\n";

###############################################################################
# CPU使用率グラフpng生成用コード
#
print FHPNG "# General Settings\n";
print FHPNG "#set nokey\n";
print FHPNG "set grid\n";
print FHPNG "set xlabel \"sec\"\n";
print FHPNG "set terminal png \n";
print FHPNG "set output \"$CPUGPLFILEIMG.png\"\n";
print FHPNG "#set autoscale x\n";
#print FHPNG "set logscale y\n";
print FHPNG "set xrange[0:$xmax]\n";
#print FHPNG "set yrange[0:]\n";
print FHPNG "set autoscale y\n";
print FHPNG "\n";
print FHPNG "set title \"iostat\"\n";

print FHPNG "plot \"$CPUFILE\" using 1:2 title \"$elmlst[0]\"  w l, \\\n";
for($i = 1; $i < $numelm - 1; $i++)
{
  $indx = $i + 2;
  print FHPNG "     \"$CPUFILE\" using 1:$indx title \"$elmlst[$i]\"  w l, \\\n";
}
$indx = $i + 2;
print FHPNG "     \"$CPUFILE\" using 1:$indx title \"$elmlst[$i]\" w l\n";

close FHPNG;

system("$GNUPLOT $CPUGPLFILEIMG");

###############################################################################
# CPU使用率グラフps生成用コード
#
print FHPDF "# General Settings\n";
print FHPDF "#set nokey\n";
print FHPDF "set grid\n";
print FHPDF "set xlabel \"sec\"\n";
print FHPDF "set term postscript color solid\n";
print FHPDF "set output \"$CPUGPLFILEPS.ps\"\n";
print FHPDF "#set autoscale x\n";
#print FHPDF "set logscale y\n";
print FHPDF "set xrange[0:$xmax]\n";
#print FHPDF "set yrange[0:]\n";
print FHPDF "set autoscale y\n";
print FHPDF "\n";
print FHPDF "set title \"iostat\"\n";

print FHPDF "plot \"$CPUFILE\" using 1:2 title \"$elmlst[0]\"  w l, \\\n";
for($i = 1; $i < $numelm - 1; $i++)
{
  $indx = $i + 2;
  print FHPDF "     \"$CPUFILE\" using 1:$indx title \"$elmlst[$i]\"  w l, \\\n";
}
$indx = $i + 2;
print FHPDF "     \"$CPUFILE\" using 1:$indx title \"$elmlst[$i]\" w l\n";

close FHPDF;

system("$GNUPLOT $CPUGPLFILEPS");
#system("$PS2PDF $CPUGPLFILEPS.ps $CPUGPLFILEPS.pdf");
system("$GV $CPUGPLFILEPS.ps &");

###############################################################################
# device使用率グラフpng生成用コード
#
for($i = 0; $i < $numdevelm; $i++)
{
  $FNAME = "$DEVGPLFILEIMG"."_$i";
  $PNGNAME = "$DEVGPLFILEIMG"."_$i".".png";
  open ( FHPNG , ">$FNAME") || die "ファイル($FNAME)を開けません :$!\n";
  print FHPNG "# General Settings\n";
  print FHPNG "set terminal png \n";
  print FHPNG "set output \"$PNGNAME\"\n";
  print FHPNG "set grid\n";
  print FHPNG "set xlabel \"sec\"\n";
  print FHPNG "#set autoscale x\n";
  print FHPNG "set xrange[0:$xmax]\n";
  print FHPNG "set autoscale y\n";
  print FHPNG "set title \"iostat\"\n";
  $indx = $i + 2;
  print FHPNG "plot \"$DEVFILE\" using 1:$indx title \"$develmlst[$i]\"  w lp\n";
  print FHPNG "\n";
  close FHPNG;
  system("$GNUPLOT $FNAME");
}

open ( FHPDF , ">$DEVGPLFILEPS") || die "ファイル($DEVGPLFILEPS)を開けません :$!\n";
###############################################################################
# device使用率グラフps生成用コード
#

print FHPDF "# General Settings\n";
print FHPDF "set term postscript color solid\n";
print FHPDF "set output \"$DEVGPLFILEPS.ps\"\n";
for($i = 0; $i < $numdevelm; $i++)
{
print FHPDF "set grid\n";
print FHPDF "set xlabel \"sec\"\n";
print FHPDF "#set autoscale x\n";
#print FHPDF "set logscale y\n";
print FHPDF "set xrange[0:$xmax]\n";
#print FHPDF "set yrange[0:]\n";
print FHPDF "set autoscale y\n";
print FHPDF "set title \"iostat\"\n";
$indx = $i + 2;
print FHPDF "plot \"$DEVFILE\" using 1:$indx title \"$develmlst[$i]\"  w lp\n";
print FHPDF "\n";
print FHPDF "\n";
}
close FHPDF;


system("$GNUPLOT $DEVGPLFILEPS");
system("$GV $DEVGPLFILEPS.ps");

sub ceil {
   my $var = shift;
   my $a = 0;
   $a = 1 if($var > 0 and $var != int($var));
   return int($var + $a);
}

