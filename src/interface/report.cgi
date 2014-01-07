#!/usr/bin/perl -w


use strict;
use lib qw{config lib/perl};
use warnings;
use POSIX;
use DBI;
use FileHandle;
use Statistics::Descriptive::Discrete;
use Statistics::PointEstimation;
use Statistics::TTest;
use STAT;

my $dbname = $STAT::stat_db;
my $dbuser = $STAT::pg_user;
my $Dbh = DBI->connect(
                       "dbi:Pg:dbname=$dbname",
                       $dbuser,
                       "",
                       {AutoCommit => 0, RaiseError => 1}
                      );
die "DBI: Can't connect to $dbname as $dbuser -- $DBI::errstr" if $DBI::state;

my %reciprocal = (
                  attending => 'trainee',
                  trainee => 'attending'
                 );

my %total_cases = (
                   attending => 0,
                   trainee => 0
                  );

my %total_cases_pending = (
                   attending => 0,
                   trainee => 0
                  );

my %total_persons = (
                     attending => 0,
                     trainee => 0
                    );

my $query;
my %role;
############################################################
# remember user role
$query = qq(SELECT DISTINCT "user", "rolename" FROM "role");
my $res = $Dbh->selectall_arrayref($query);
$Dbh->err and die $Dbh->errstr . "in query: [$query]";
foreach my $row ( @$res ) {
  my ($user, $role) = @$row;
  $role{$user} = $role;
}

##################################################################################
#   T R E E   U S A G E
#

print qq(

T R E E   U S A G E
);

$query = qq(
SELECT count(*)
  FROM activity
 WHERE parent IN (
         SELECT id from activity where parent = 0 and label != 'Common'
       )
);
my ( $cases_in_tree ) = $Dbh->selectrow_array($query);
$Dbh->err and die $Dbh->errstr . "in query: [$query]";

$query = qq(SELECT count(DISTINCT "activity") FROM "case");
my ( $cases_done ) = $Dbh->selectrow_array($query);
$Dbh->err and die $Dbh->errstr . "in query: [$query]";

print qq(
  $cases_done case types were done out of $cases_in_tree in tree.

);

##################################################################################
#   P A R T I C I P A N T S
#

print qq(

P A R T I C I P A N T S
);

$query = qq(SELECT count(DISTINCT "user") FROM "role");
my ( $registered_users ) = $Dbh->selectrow_array($query);
$Dbh->err and die $Dbh->errstr . "in query: [$query]";

$query = qq(SELECT count(DISTINCT "user") FROM "role" WHERE "rolename" = 'attending');
my ( $registered_attendings ) = $Dbh->selectrow_array($query);
$Dbh->err and die $Dbh->errstr . "in query: [$query]";

$query = qq(SELECT count(DISTINCT "user") FROM "role" WHERE "rolename" = 'trainee');
my ( $registered_trainees ) = $Dbh->selectrow_array($query);
$Dbh->err and die $Dbh->errstr . "in query: [$query]";

print qq(
  Registered Users (from the role table):

    attendings: $registered_attendings
      trainees: $registered_trainees
    --------------
         total: $registered_users
);

$query = qq(SELECT count(DISTINCT "assessor") FROM "case");
my ( $active_users ) = $Dbh->selectrow_array($query);
$Dbh->err and die $Dbh->errstr . "in query: [$query]";

$query = qq(SELECT count(DISTINCT "assessor") FROM "case" WHERE "assessor" = "attending");
my ( $active_attendings ) = $Dbh->selectrow_array($query);
$Dbh->err and die $Dbh->errstr . "in query: [$query]";

$query = qq(SELECT count(DISTINCT "assessor") FROM "case" WHERE "assessor" = "trainee");
my ( $active_trainees ) = $Dbh->selectrow_array($query);
$Dbh->err and die $Dbh->errstr . "in query: [$query]";

print qq(
  Active Users (those who made submissions):

    attendings: $active_attendings
      trainees: $active_trainees
    --------------
         total: $active_users
);


# $query = qq(SELECT count(DISTINCT "user") FROM "survey" WHERE n > 1);
# ( $registered_users ) = $Dbh->selectrow_array($query);
# $Dbh->err and die $Dbh->errstr . "in query: [$query]";

# $query = qq(SELECT count(DISTINCT "user") FROM "survey" WHERE n > 1 AND "role" = 'attending');
# ( $registered_attendings ) = $Dbh->selectrow_array($query);
# $Dbh->err and die $Dbh->errstr . "in query: [$query]";

# $query = qq(SELECT count(DISTINCT "user") FROM "survey" WHERE n > 1 AND "role" = 'trainee');
# ( $registered_trainees ) = $Dbh->selectrow_array($query);
# $Dbh->err and die $Dbh->errstr . "in query: [$query]";

# print qq(
#   Follow-up survey taken by:
# 
#     attendings: $registered_attendings
#       trainees: $registered_trainees
#     --------------
#          total: $registered_users
# );

#----------------------------------------------------------------------------------------
print qq(

S U B M I S S I O N S
);

$query = qq(SELECT extract('day' FROM max("timestamp") - min("timestamp")) FROM "case");
my ( $duration ) = $Dbh->selectrow_array($query);
$Dbh->err and die $Dbh->errstr . "in query: [$query]";

print qq(
  Duration of the program: $duration days
);

$query = qq(
SELECT extract('year' FROM "timestamp") AS year,
       extract('month' from "timestamp") AS month,
       count(*) AS count
  FROM "case"
 GROUP BY year, month;
);
$res = $Dbh->selectall_arrayref($query);
$Dbh->err and die $Dbh->errstr . "in query: [$query]";
my %monthly_stats;
foreach my $row ( @$res ) {
  my ($year, $month, $submissions) = @$row;
  my $m = sprintf("%02d", $month);
  $monthly_stats{"$year-$m"}->{submissions} += $submissions;
}

$query = qq(
SELECT extract('year' FROM "date") AS year,
       extract('month' from "date") AS month,
       "date", "case_no", "activity", trainee, count(*) as count
  FROM "case"
 GROUP BY year, month, "date", case_no, activity, trainee;
);
$res = $Dbh->selectall_arrayref($query);
$Dbh->err and die $Dbh->errstr . "in query: [$query]";
foreach my $row ( @$res ) {
  my ($year, $month, $date, $case_no, $activity, $id, $submissions) = @$row;
  my $m = sprintf("%02d", $month);
  $monthly_stats{"$year-$m"}->{cases} += 1;
  $monthly_stats{"$year-$m"}->{linked} += 1 if $submissions > 1;
}

my $total_cases = 0;
my $total_submissions = 0;
my $total_linked = 0;
my ($m, $submissions, $cases, $linked);
print qq(
  Submissions by month:

             submissions  cases  linked
    -----------------------------------
);
format Form3 =
    @>>>>>>:        @###   @###    @###
    $m, $submissions, $cases, $linked
.
format_name STDOUT "Form3";

foreach $m ( sort keys %monthly_stats ) {
  $submissions = $monthly_stats{$m}->{submissions};
  $cases = $monthly_stats{$m}->{cases};
  $linked = $monthly_stats{$m}->{linked};
  $total_submissions += $submissions;
  $total_cases += $cases;
  $total_linked += $linked;
  write;
}
($m, $submissions, $cases, $linked) = ("total", $total_submissions, $total_cases, $total_linked);
write;

#----------------------------------------------------------------------------------------
print qq(

S U B M I S S I O N S  B Y  A T T E N D I N G S
);

$query = qq(
SELECT extract('year' FROM "timestamp") AS year,
       extract('month' from "timestamp") AS month,
       count(*) AS count
  FROM "case" WHERE assessor = attending
 GROUP BY year, month;
);
$res = $Dbh->selectall_arrayref($query);
$Dbh->err and die $Dbh->errstr . "in query: [$query]";
undef %monthly_stats;
foreach my $row ( @$res ) {
  my ($year, $month, $submissions) = @$row;
  my $m = sprintf("%02d", $month);
  $monthly_stats{"$year-$m"}->{submissions} += $submissions;
}

my $submissions_by_attending = 0;
print qq(
  Submissions by month:

             submissions
    --------------------
);
format Form4 =
    @>>>>>>:        @###
    $m, $submissions
.
format_name STDOUT "Form4";

foreach $m ( sort keys %monthly_stats ) {
  $submissions = $monthly_stats{$m}->{submissions};
  $submissions_by_attending += $submissions;
  write;
}
($m, $submissions) = ("total", $submissions_by_attending);
write;

#----------------------------------------------------------------------------------------
print qq(

S U B M I S S I O N S  B Y  T R A I N E E S
);

$query = qq(
SELECT extract('year' FROM "timestamp") AS year,
       extract('month' from "timestamp") AS month,
       count(*) AS count
  FROM "case" WHERE assessor = trainee
 GROUP BY year, month;
);
$res = $Dbh->selectall_arrayref($query);
$Dbh->err and die $Dbh->errstr . "in query: [$query]";
undef %monthly_stats;
foreach my $row ( @$res ) {
  my ($year, $month, $submissions) = @$row;
  my $m = sprintf("%02d", $month);
  $monthly_stats{"$year-$m"}->{submissions} += $submissions;
}

my $submissions_by_trainee = 0;
print qq(
  Submissions by month:

             submissions
    --------------------
);
format Form5 =
    @>>>>>>:        @###
    $m, $submissions
.
format_name STDOUT "Form5";

foreach $m ( sort keys %monthly_stats ) {
  $submissions = $monthly_stats{$m}->{submissions};
  $submissions_by_trainee += $submissions;
  write;
}
($m, $submissions) = ("total", $submissions_by_trainee);
write;

#----------------------------------------------------------------------------------------

$query = qq(
SELECT CASE WHEN assessor = trainee THEN 'T' ELSE 'A' END AS role,
       assessor, 
       count(*) AS count
  FROM "case"
 GROUP BY role, assessor
 ORDER BY count DESC;
);
$res = $Dbh->selectall_arrayref($query);
$Dbh->err and die $Dbh->errstr . "in query: [$query]";

my $tid = 'T00';
my $aid = 'A00';

print qq(

  S U B M I S S I O N S   B Y   I N D I V I D U A L   P A R T I C I P A N T S:

  (* = 2)

);

foreach my $row ( @$res ) {
  my ($role, undef, $count) = @$row;
  $tid++ if $role eq 'T';
  $aid++ if $role eq 'A';
  my $id = $role eq 'T' ? $tid : $aid;
  print "  $id: " . ('*' x floor($count/2)) . "\n";
  print "       $count\n";
}


print qq(



T I M E   S P E N T

  Distribution of assessment times for all attendings and trainsees combined:
  ===========================================================================

);

my @time = `src/tools/analyze-logs`;
my @time_all;
my @time_attending;
my @time_trainee;
my ($min, $max, $min_a, $max_a, $min_t, $max_t) = (10000, 0, 10000, 0, 10000, 0);
foreach my $fact (@time) {
  chomp $fact;
  my ($id, $time) = split "\t", $fact;
  next if $time > 600;
  push @time_all, $time;
  $min = $time if $time < $min;
  $max = $time if $time > $max;
  if ( $role{$id} eq 'attending' ) {
    push @time_attending, $time;
    $min_a = $time if $time < $min_a;
    $max_a = $time if $time > $max_a;
  }
  else {
    push @time_trainee, $time;
    $min_t = $time if $time < $min_t;
    $max_t = $time if $time > $max_t;
  }
}

# make a histogram
my $nbins = 20;
foreach my $i (0 .. $nbins - 1) {
  my $span = $max - $min + 1;
  my $binsize = $span / $nbins;
  my $lower = sprintf("%3.f", $min + $i * $binsize);
  my $upper = sprintf("%3.f", $min + ($i + 1)*$binsize);
  my $n = grep {$_ >= $lower and $_ < $upper} @time_all;
  print "    $lower .. $upper: " . ('*' x $n) . "\n";
}

print "---------- table -----------\n";
foreach my $i (0 .. $nbins - 1) {
  my $span = $max - $min + 1;
  my $binsize = $span / $nbins;
  my $lower = sprintf("%3.f", $min + $i * $binsize);
  my $upper = sprintf("%3.f", $min + ($i + 1)*$binsize);
  my $n = grep {$_ >= $lower and $_ < $upper} @time_all;
  print "$lower .. $upper\t$n\n";
}

my $stat = new Statistics::Descriptive::Discrete;
$stat->add_data(@time_all);
print "\n    Output from Statistics::Descriptive::Discrete\n";
print "    ---------------------------------------------\n";
print "    count = ", $stat->count(),"\n";
print "    uniq  = ", $stat->uniq(),"\n";
print "    sum = ", $stat->sum(),"\n";
print "    min = ", $stat->min(),"\n";
print "    max = ", $stat->max(),"\n";
print "    mean = ", sprintf("%.3g\n", $stat->mean());
print "    standard_deviation = ", sprintf("%.3g\n", $stat->standard_deviation());
print "    variance = ", sprintf("%d\n", $stat->variance());
print "    sample_range = ",$stat->sample_range(),"\n";
print "    mode = ",$stat->mode(),"\n";
print "    median = ",$stat->median(),"\n";

$stat = new Statistics::PointEstimation;
$stat->set_significance(95);
$stat->add_data(@time_all);
print "\n    Output from Statistics::PointEstimation\n";
print "    ---------------------------------------\n";
print "    ";
$stat->output_confidence_interval;

print qq(

  Distribution of trainee times:
  ==============================

);

foreach my $i (0 .. $nbins - 1) {
  my $span = $max - $min + 1;
  my $binsize = $span / $nbins;
  my $lower = sprintf("%3.f", $min + $i * $binsize);
  my $upper = sprintf("%3.f", $min + ($i + 1)*$binsize);
  my $n = grep {$_ >= $lower and $_ < $upper} @time_trainee;
  print "    $lower .. $upper: " . ('*' x $n) . "\n";
}
print "---------- table -----------\n";
foreach my $i (0 .. $nbins - 1) {
  my $span = $max - $min + 1;
  my $binsize = $span / $nbins;
  my $lower = sprintf("%3.f", $min + $i * $binsize);
  my $upper = sprintf("%3.f", $min + ($i + 1)*$binsize);
  my $n = grep {$_ >= $lower and $_ < $upper} @time_trainee;
  print "$lower .. $upper\t$n\n";
}


$stat = new Statistics::Descriptive::Discrete;
$stat->add_data(@time_trainee);
print "\n    Output from Statistics::Descriptive::Discrete\n";
print "    ---------------------------------------------\n";
print "    count = ", $stat->count(),"\n";
print "    uniq  = ", $stat->uniq(),"\n";
print "    sum = ", $stat->sum(),"\n";
print "    min = ", $stat->min(),"\n";
print "    max = ", $stat->max(),"\n";
print "    mean = ", sprintf("%.3g\n", $stat->mean());
print "    standard_deviation = ", sprintf("%.3g\n", $stat->standard_deviation());
print "    variance = ", sprintf("%d\n", $stat->variance());
print "    sample_range = ",$stat->sample_range(),"\n";
print "    mode = ",$stat->mode(),"\n";
print "    median = ",$stat->median(),"\n";

$stat = new Statistics::PointEstimation;
$stat->set_significance(95);
$stat->add_data(@time_trainee);
print "\n    Output from Statistics::PointEstimation\n";
print "    ---------------------------------------\n";
print "    ";
$stat->output_confidence_interval;

print q(

  Attendings' times:
  ==================

);

foreach my $i (0 .. $nbins - 1) {
  my $span = $max - $min + 1;
  my $binsize = $span / $nbins;
  my $lower = sprintf("%3.f", $min + $i * $binsize);
  my $upper = sprintf("%3.f", $min + ($i + 1)*$binsize);
  my $n = grep {$_ >= $lower and $_ < $upper} @time_attending;
  print "    $lower .. $upper: " . ('*' x $n) . "\n";
}
print "---------- table -----------\n";
foreach my $i (0 .. $nbins - 1) {
  my $span = $max - $min + 1;
  my $binsize = $span / $nbins;
  my $lower = sprintf("%3.f", $min + $i * $binsize);
  my $upper = sprintf("%3.f", $min + ($i + 1)*$binsize);
  my $n = grep {$_ >= $lower and $_ < $upper} @time_attending;
  print "$lower .. $upper\t$n\n";
}


$stat = new Statistics::Descriptive::Discrete;
$stat->add_data(@time_attending);
print "\n    Output from Statistics::Descriptive::Discrete\n";
print "    ---------------------------------------------\n";
print "    count = ", $stat->count(),"\n";
print "    uniq  = ", $stat->uniq(),"\n";
print "    sum = ", $stat->sum(),"\n";
print "    min = ", $stat->min(),"\n";
print "    max = ", $stat->max(),"\n";
print "    mean = ", sprintf("%.3g\n", $stat->mean());
print "    standard_deviation = ", sprintf("%.3g\n", $stat->standard_deviation());
print "    variance = ", sprintf("%d\n", $stat->variance());
print "    sample_range = ",$stat->sample_range(),"\n";
print "    mode = ",$stat->mode(),"\n";
print "    median = ",$stat->median(),"\n";

$stat = new Statistics::PointEstimation;
$stat->set_significance(95);
$stat->add_data(@time_attending);
print "\n    Output from Statistics::PointEstimation\n";
print "    ---------------------------------------\n";
print "    ";
$stat->output_confidence_interval;


my $ttest = new Statistics::TTest;
$ttest->set_significance(95);
$ttest->load_data(\@time_trainee, \@time_attending);
#$ttest->output_t_test();
print "\n    Output from Statistics::TTest\n";
print "    -----------------------------\n";
print "    Comparison of samples:\n";
print "\t F-statistic=",$ttest->f_statistic()," , cutoff F-statistic=",$ttest->f_cutoff(),
  " with alpha level=",$ttest->alpha*2," and  df =(",$ttest->df1,",",$ttest->df2,")\n"; 
if($ttest->{equal_variance})
  { print "\tequal variance assumption is accepted(not rejected) since F-statistic < cutoff F-statistic\n";}
else
  { print "\tequal variance assumption is  rejected since F-statistic > cutoff F-statistic\n";} 
print "\tdegree of freedom=",$ttest->df," , t-statistic=T=",$ttest->t_statistic," Prob >|T|=",$ttest->{t_prob},"\n";
print "\tthe null hypothesis (the 2 samples have the same mean) is ",$ttest->null_hypothesis(),
  " since the alpha level is ",$ttest->alpha()*2,"\n";
print "\tdifference of the mean=",$ttest->mean_difference(),", standard error=",$ttest->standard_error(),"\n";
print "\t the estimate of the difference of the mean is ", $ttest->mean_difference()," +/- ",$ttest->delta(),"\n\t",
  " or (",$ttest->lower_clm()," to ",$ttest->upper_clm," ) with ",$ttest->significance," % of confidence\n"; 

print qq(
    Point Estimation

);

print "        trainee:  mean = ", sprintf("%4.2f", $ttest->{s1}->mean),
  "; s.d. = ", sprintf("%.3g", $ttest->{s1}->standard_deviation),
  "; variance = ", sprintf("%d", $ttest->{s1}->variance),
  "\n";
print "      attending:  mean = ", sprintf("%4.2f", $ttest->{s2}->mean),
  "; s.d. = ", sprintf("%.3g", $ttest->{s2}->standard_deviation),
  "; variance = ", sprintf("%d", $ttest->{s2}->variance),
  "\n";

print qq(
    Comparison

);
if ( $ttest->{equal_variance} ) {
  print "      Equal variance assumption is accepted.\n";
}
else {
  print "      Equal variance assumption is rejected.\n";
}

print "      The null hypothesis (the 2 samples have the same mean) is " . $ttest->null_hypothesis,
  "; alpha = " . 2*$ttest->alpha,
  "; p-value = " . sprintf("%.2g", $ttest->{t_prob}),
  "\n";

print "      Difference of the mean is (", sprintf("%.3g", $ttest->lower_clm),
  " .. ", sprintf("%.3g", $ttest->upper_clm),
  ") with ", $ttest->significance, "% of confidence\n";

print qq(
      **********************************************************************************************
      *                                                                                            *
      *  N O T E: This estimation is incorrect because the variables are not distributed normally  *
      *                                                                                            *
      **********************************************************************************************
);

print qq(



A S S E S S M E N T S

  Overall Assessment
);

my %overall_symbol;
$query = qq(
SELECT value - 30, symbol
  FROM "rating"
 WHERE value >= 30 AND value <= 42
);
$res = $Dbh->selectall_arrayref($query);
$Dbh->err and die $Dbh->errstr . "in query: [$query]";

foreach my $row ( @$res ) {
  my ( $value, $symbol) = @$row;
  $overall_symbol{$value} = $symbol;
}

my $id_of_overall = Util::id_of_overall($Dbh);
$query = qq(
SELECT CASE WHEN assessor = trainee THEN 'trainee' ELSE 'attending' END as role,
       assessment - 30
  FROM eval, "case"
 WHERE eval."case" = "case".id
   AND eval.activity = $id_of_overall
);
$res = $Dbh->selectall_arrayref($query);
$Dbh->err and die $Dbh->errstr . "in query: [$query]";

my %overall_grade_hist;
my @overall;
my @overall_trainee;
my @overall_attending;
foreach my $row ( @$res ) {
  my ( $role, $grade ) = @$row;
  $overall_grade_hist{both}->{$grade}++;
  $overall_grade_hist{attending}->{$grade}++ if $role eq 'attending';
  $overall_grade_hist{trainee}->{$grade}++ if $role eq 'trainee';
  push @overall, $grade;
  push @overall_attending, $grade if $role eq 'attending';
  push @overall_trainee, $grade if $role eq 'trainee';
}

print qq(
    Distribution of ratings:


      attendings and trainees combined:
      =================================

      (* = 5)

);

foreach my $rating (0 .. 12) {
  my $r = sprintf("%2d", $rating);
  print "      $r: ". ('*' x floor(($overall_grade_hist{both}->{$rating} or 0)/5)) . "\n";
}
print "---------- table -----------\n";
foreach my $rating (0 .. 12) {
  my $r = sprintf("%2d", $rating);
  print "$r\t$overall_symbol{$rating}\t$overall_grade_hist{both}->{$rating}\n";
}


$stat = new Statistics::Descriptive::Discrete;
$stat->add_data(@overall);
print "\n    Output from Statistics::Descriptive::Discrete\n";
print "    ---------------------------------------------\n";
print "    count = ", $stat->count(),"\n";
print "    uniq  = ", $stat->uniq(),"\n";
print "    sum = ", $stat->sum(),"\n";
print "    min = ", $stat->min(),"\n";
print "    max = ", $stat->max(),"\n";
print "    mean = ", sprintf("%.3g\n", $stat->mean());
print "    standard_deviation = ", sprintf("%.3g\n", $stat->standard_deviation());
print "    variance = ", sprintf("%d\n", $stat->variance());
print "    sample_range = ",$stat->sample_range(),"\n";
print "    mode = ",$stat->mode(),"\n";
print "    median = ",$stat->median(),"\n";

$stat = new Statistics::PointEstimation;
$stat->set_significance(95);
$stat->add_data(@overall);
print "\n    Output from Statistics::PointEstimation\n";
print "    ---------------------------------------\n";
print "    ";
$stat->output_confidence_interval;


print qq(


      attending:
      ==========

      (* = 5)

);

foreach my $rating (0 .. 12) {
  my $r = sprintf("%2d", $rating);
  print "      $r: ". ('*' x floor(($overall_grade_hist{attending}->{$rating} or 0)/5)) . "\n";
}
print "---------- table -----------\n";
foreach my $rating (0 .. 12) {
  my $r = sprintf("%2d", $rating);
  print "$r\t$overall_symbol{$rating}\t$overall_grade_hist{attending}->{$rating}\n";
}

$stat = new Statistics::Descriptive::Discrete;
$stat->add_data(@overall_attending);
print "\n    Output from Statistics::Descriptive::Discrete\n";
print "    ---------------------------------------------\n";
print "    count = ", $stat->count(),"\n";
print "    uniq  = ", $stat->uniq(),"\n";
print "    sum = ", $stat->sum(),"\n";
print "    min = ", $stat->min(),"\n";
print "    max = ", $stat->max(),"\n";
print "    mean = ", sprintf("%.3g\n", $stat->mean());
print "    standard_deviation = ", sprintf("%.3g\n", $stat->standard_deviation());
print "    variance = ", sprintf("%d\n", $stat->variance());
print "    sample_range = ",$stat->sample_range(),"\n";
print "    mode = ",$stat->mode(),"\n";
print "    median = ",$stat->median(),"\n";

$stat = new Statistics::PointEstimation;
$stat->set_significance(95);
$stat->add_data(@overall_attending);
print "\n    Output from Statistics::PointEstimation\n";
print "    ---------------------------------------\n";
print "    ";
$stat->output_confidence_interval;

print qq(


      trainee:
      ========

      (* = 5)

);

foreach my $rating (0 .. 12) {
  my $r = sprintf("%2d", $rating);
  print "      $r: ". ('*' x floor(($overall_grade_hist{trainee}->{$rating} or 0)/5)) . "\n";
}
print "---------- table -----------\n";
foreach my $rating (0 .. 12) {
  my $r = sprintf("%2d", $rating);
  print "$r\t$overall_symbol{$rating}\t$overall_grade_hist{trainee}->{$rating}\n";
}

$stat = new Statistics::Descriptive::Discrete;
$stat->add_data(@overall_trainee);
print "\n    Output from Statistics::Descriptive::Discrete\n";
print "    ---------------------------------------------\n";
print "    count = ", $stat->count(),"\n";
print "    uniq  = ", $stat->uniq(),"\n";
print "    sum = ", $stat->sum(),"\n";
print "    min = ", $stat->min(),"\n";
print "    max = ", $stat->max(),"\n";
print "    mean = ", sprintf("%.3g\n", $stat->mean());
print "    standard_deviation = ", sprintf("%.3g\n", $stat->standard_deviation());
print "    variance = ", sprintf("%d\n", $stat->variance());
print "    sample_range = ",$stat->sample_range(),"\n";
print "    mode = ",$stat->mode(),"\n";
print "    median = ",$stat->median(),"\n";

$stat = new Statistics::PointEstimation;
$stat->set_significance(95);
$stat->add_data(@overall_trainee);
print "\n    Output from Statistics::PointEstimation\n";
print "    ---------------------------------------\n";
print "    ";
$stat->output_confidence_interval;

$ttest = new Statistics::TTest;
$ttest->set_significance(95);
$ttest->load_data(\@overall_trainee, \@overall_attending);
#$ttest->output_t_test();
print "\n    Output from Statistics::TTest\n";
print "    -----------------------------\n";
print "    Comparison of samples:\n";
print "\t F-statistic=",$ttest->f_statistic()," , cutoff F-statistic=",$ttest->f_cutoff(),
  " with alpha level=",$ttest->alpha*2," and  df =(",$ttest->df1,",",$ttest->df2,")\n"; 
if($ttest->{equal_variance})
  { print "\tequal variance assumption is accepted(not rejected) since F-statistic < cutoff F-statistic\n";}
else
  { print "\tequal variance assumption is  rejected since F-statistic > cutoff F-statistic\n";} 
print "\tdegree of freedom=",$ttest->df," , t-statistic=T=",$ttest->t_statistic," Prob >|T|=",$ttest->{t_prob},"\n";
print "\tthe null hypothesis (the 2 samples have the same mean) is ",$ttest->null_hypothesis(),
  " since the alpha level is ",$ttest->alpha()*2,"\n";
print "\tdifference of the mean=",$ttest->mean_difference(),", standard error=",$ttest->standard_error(),"\n";
print "\t the estimate of the difference of the mean is ", $ttest->mean_difference()," +/- ",$ttest->delta(),"\n\t",
  " or (",$ttest->lower_clm()," to ",$ttest->upper_clm," ) with ",$ttest->significance," % of confidence\n"; 

print qq(
    Point Estimation

);

print "        trainee:  mean = ", sprintf("%4.2f", $ttest->{s1}->mean),
  "; s.d. = ", sprintf("%.3g", $ttest->{s1}->standard_deviation),
  "; variance = ", sprintf("%.3g", $ttest->{s1}->variance),
  "\n";
print "      attending:  mean = ", sprintf("%4.2f", $ttest->{s2}->mean),
  "; s.d. = ", sprintf("%.3g", $ttest->{s2}->standard_deviation),
  "; variance = ", sprintf("%.3g", $ttest->{s2}->variance),
  "\n";

print qq(
    Comparison

);
if ( $ttest->{equal_variance} ) {
  print "      Equal variance assumption is accepted.\n";
}
else {
  print "      Equal variance assumption is rejected.\n";
}

print "      The null hypothesis (the 2 samples have the same mean) is " . $ttest->null_hypothesis,
  "; alpha = " . 2*$ttest->alpha,
  "; p-value = " . sprintf("%.2g", $ttest->{t_prob}),
  "\n";

print "      Difference of the mean is (", sprintf("%.3g", $ttest->lower_clm),
  " .. ", sprintf("%.3g", $ttest->upper_clm),
  ") with ", $ttest->significance, "% of confidence\n";

#----------------------------------------------------------------------------------------
#  mean difference
