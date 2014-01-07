use strict;
use warnings;

package Plot;
use Date::Manip;
use IPC::Run3 qw/run3/;

sub plot_cases_logged {
  my %arg = @_;
  my $self = $arg{-self};
  my $attending = $arg{-attending};

  # Put together the command to run gnuplot.
  my @input;
  my $read_stdout;
  my $read_stderr;

  my $max = 0;
  foreach my $row (@$self, @$attending) {
    $max = $row->[1] if $row->[1] > $max;
  }
  my $tics = 1;
  $tics = 2 if $max >= 10;
  $tics = 5 if $max >= 20;
  $tics = 10 if $max >= 50;
  $tics = 20 if $max >= 100;
  $tics = 50 if $max >= 200;
  $tics = 100 if $max >= 500;
  push @input, qq(
=cluster attending resident
colors=grey3,grey5
=sort
=nocommas
legendx=7100
legendy=1425
ylabel=Number of assessments
extraops=set ytics $tics
);

  foreach my $row (@$attending) {
    push @input, join("\t", $row->[0], $row->[1]) . "\n";
  }
  push @input, "=multi\n";
  foreach my $row (@$self) {
    push @input, join("\t", $row->[0], $row->[1]) . "\n";
  }

  my @cmd = ("$STAT::bin/bargraph", "-gnuplot-path", $STAT::path_to_gnuplot40, "-fig", "-");
  run3 \@cmd, \@input, \$read_stdout, \$read_stderr
    or die "couldnt't run3 this command: @cmd, $!\n";

  if ( $read_stderr ) {
    die "bargraph returned this error: $read_stderr";
  }

  @input = ($read_stdout);
  @cmd = ($STAT::path_to_fig2dev, '-L', 'png', '-m', '4');
  run3 [@cmd], \@input, \$read_stdout, \$read_stderr
    or die "couldnt't run3 this command: @cmd, $!\n";

  if ( $read_stderr ) {
    die "fig2dev returned this error: $read_stderr";
  }

  @input = ($read_stdout);
  @cmd = ($STAT::path_to_convert, '-', '-resize', '700x700', '-transparent', 'rgb(255,255,255)', '-');
  run3 [@cmd], \@input, \$read_stdout, \$read_stderr
    or die "couldnt't run3 this command: @cmd, $!\n";

  if ( $read_stderr ) {
    die "convert returned this error: $read_stderr";
  }

  return $read_stdout;
}

sub plot_ratings {
  my %arg = @_;
  my $table = delete $arg{-table};
  my $range = $arg{-range};
  my $range2 = $arg{-range2};
  my $ytics = $arg{-ytics};
  my $ytics2 = $arg{-ytics2};
  my $xrange = $arg{-xrange};
  my $legend = $arg{-legend};

  # Put together the command to run gnuplot.
  my @cmd;
  my @input;
  my $read_stdout;
  my $read_stderr;

  my $a_lt = '7';
  my $t_lt = '31';
  if ( $STAT::gnuplot_version =~ / 4.0 / ) {
    push @input, qq(
set term postscript eps color portrait 'Fixed' 14
set size 1.12, 0.28
);
  } else {
    push @input, qq(
set term postscript eps color 'Fixed' 28
set size 1.56, 0.8
);
  }
  push @input, qq(
set lmargin 15
set rmargin 15
set datafile missing 'x'
set nokey
#unset border
set border 10
set grid ytics
set grid y2tics
unset xtics
set xlabel "Case Sequence"
set style fill solid 0.5 border
);
  if ( $STAT::gnuplot_version =~ / 4.0 / ) {
    push @input, qq(
set style line 1 linetype $t_lt linewidth 2 pt 7 ps 0.8
set style line 2 linetype $a_lt linewidth 2 pt 7 ps 0.8
);
  }
  else {
    push @input, qq(
set style line 1 linetype $t_lt linewidth 6 pt 7 ps 1.8
set style line 2 linetype $a_lt linewidth 6 pt 7 ps 1.8
);
  }
  push @input, qq(
set boxwidth 0.5

set title '$legend'
set yrange [$range->[0]:$range->[1]]
set y2range [$range2->[0]:$range2->[1]]
set xrange [$xrange->[0]:$xrange->[1]]
set ylabel "trainee" textcolor lt $t_lt
set y2label "attending" textcolor lt $a_lt
set ytics($ytics) textcolor lt $t_lt
set y2tics($ytics2)

plot '-'  using 1:(\$2) axis x1y1 with linespoints ls 1, '-' using 1:(\$2) axis x1y2 with linespoints ls 2
);
  foreach my $row (@$table) {
    push @input, join("\t", $row->[0], $row->[1]) . "\n";
  }
  push @input, "e\n";
  foreach my $row (@$table) {
    push @input, join("\t", $row->[0], $row->[2]) . "\n";
  }
  push @input, "e\n";

#  open DUMP, ">/tmp/gnuplot-$legend.dump" or die "can't open gnuplot file: $!";
#  print DUMP join("\n", @input) or die "can't write to gnuplot file: $!";
#  close DUMP;
  run3 [$STAT::path_to_gnuplot40], \@input, \$read_stdout, \$read_stderr
    or die "couldnt't run3: $!\n";

  if ( $read_stderr ) {
    unless ( $read_stderr =~ m/warning: Skipping data file with no valid points/gm ) {
      die "gnuplot returned this error: $read_stderr";
    }
  }

  @input = ($read_stdout);
  @cmd = ($STAT::path_to_convert, '-', '-transparent', 'rgb(255,255,255)', '-modulate', '90,50,85', '-gamma', '0.8', 'png:-');
  run3 [@cmd], \@input, \$read_stdout, \$read_stderr
    or die "couldnt't run3 this command: @cmd, $!\n";

  if ( $read_stderr ) {
    die "convert returned this error: $read_stderr";
  }
  return $read_stdout;
}

sub time_chart {
  my %arg = @_;
  my $table = delete $arg{-table};
  my $range = delete $arg{-range};
  my $trainee = delete $arg{-trainee};
  my $dbh = delete $arg{-dbh};
  my $first_day = int($range->[0]/(24*3600))*24*3600;
  my $last_day = (int($range->[1]/(24*3600)) + 1)*24*3600;


  # Put together the command to run gnuplot.
  my @input;
  my @buf;
  my $n;
  my $read_stdout;
  my $read_stderr;

  my $length = 60*int(($range->[1] - $range->[0])/24/3600);
  $length = 500 if $length < 500;
  $length = 20000 if $length > 20000;

  # plot twice, first plotting a flat line to coerce xtics to time format

  push @input, qq(\
set term png transparent truecolor size $length, 90
unset ytics
unset mxtics
unset key
set multiplot
);

  # -------------------------------------------------------
  # do the weekly summaries first
  push @input, qq(\
set xdata
set xrange [$first_day:$last_day] reverse
unset grid
unset ytics
unset mxtics
unset xtics
unset key
set bmargin 2
set tmargin 0
set rmargin 2
set size 1,0.5
set origin 0,0.3
set style fill transparent solid 0.2 noborder
);

  my @weeks = Util::sequence_of_week_intervals(@$range, "%o");

  if ( @weeks ) {
    # set labels
    $n = 1000;
    foreach (@weeks) {
      my ($from, $to) = split ":";
      my $lx = $from + int(($to - $from)/2);
      my $hours = sprintf("%3.1f", Util::work_hours($dbh, $trainee, $from, $to));
      $hours =~ s/\.0//;
      push @input, qq(
set label $n "$hours" at $lx, 0.5 front center nopoint tc lt -1;
);
      $n++;
    }

    undef @buf;
    foreach (@weeks) {
      push @buf, " '-' u 1:2:3 w filledcu";
    }
    push @input, "plot" . join(",", @buf);

    # write data for the plot command
    foreach (@weeks) {
      my ($from, $to) = split ":";
      push @input, qq(
$from	0	0
$from	0	1
$to	0	1
$to	0	0
e
);
    }
  }

  # ----------------------------------------------------------
  # plot an invisible set of work times, to establish the time axis
  push @input, qq(
unset object
unset label
set xdata time
set timefmt "%s"
set xrange [*:*] reverse
set xtics 60*60*24
set grid xtics
set grid front
set tmargin 0
set bmargin 2
set rmargin 2
set size 1,0.5
set origin 0,0
set style fill transparent solid 0 noborder # this is a trick to get a time axis with correct dates !!
);

  # list plot functions for each interval and write the plot command
  undef @buf;
  foreach (@$table) {
    push @buf, " '-' u 1:2:3 w filledcu";
  }
  push @input, "plot" . join(",", @buf);

  # write data for the plot command
  foreach my $row (@$table) {
    my ($from, $to) = @$row;
    push @input, qq(
$from	0	0
$from	0	1
$to	0	1
$to	0	0
e
);
  }

  # ------------------------------------------------------------
  # now repeat without "xdata time" and plot the boxes and labels
  push @input, qq(\
set xdata
set xrange [$first_day:$last_day] reverse
unset grid
unset ytics
unset mxtics
unset xtics
unset key
set bmargin 2
set tmargin 0
set rmargin 2
set size 1,0.5
set origin 0,0
);

  # set labels
  $n = 1;
  foreach my $row (@$table) {
    my ($from, $to) = @$row;
    my $lx = $from + int(($to - $from)/2);
    my $hours = sprintf("%3.1f", ($to - $from)/3600);
    $hours =~ s/\.0//;
    push @input, qq(
set label $n "$hours" at $lx, 0.5 front center nopoint tc lt -1;
set object $n rect from $from,0 to $to,1 fillstyle transparent solid 0.2 noborder fc rgb "blue"
);
    $n++;
  }

  push @input, qq(
set yrange [0:1]
plot '-' u 1:2 w l
$range->[0]	0
$range->[1]	0
e
);


#  open DUMP, ">/tmp/gnuplot-timechart.dump" or die "can't open gnuplot file: $!";
#  print DUMP join("\n", @input) or die "can't write to gnuplot file: $!";
#  close DUMP;

  run3 [$STAT::path_to_gnuplot43], \@input, \$read_stdout, \$read_stderr
    or die "couldnt't run3: $!\n";

  if ( $read_stderr ) {
    print STDERR "gnuplot returned this error: $read_stderr";
    die "gnuplot returned this error: $read_stderr";
  }

#   @input = ($read_stdout);
#   run3 [qw(/opt/local/bin/convert ps:- -transparent white -modulate 90,50,85, -gamma 0.8 png:-)], \@input, \$read_stdout, \$read_stderr
#     or die "couldnt't run3: $!\n";

#   if ( $read_stderr ) {
#     print STDERR "convert returned this error: $read_stderr";
#   }
  return $read_stdout;
}

1;
