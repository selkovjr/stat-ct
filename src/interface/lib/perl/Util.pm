package Util;
use Date::Manip;
use POSIX;
use strict;
use warnings;

sub add_session_id {
  my $url = shift;
  return $url if $url =~ /\.css/;
  return $url if $url =~ /\.js/;
  return $url if $url =~ /javascript/;
  return $url if $url =~ /mailto:/;
  return $url if $url =~ /logout.html/;
  return $url if $url =~ m{^\w+://}; # Don't alter external URLs
#  print STDERR "add_session_id($url)\n";
  if ($url =~ /\?/) {
    $url =~ s/session_id=[0-9a-f]+[&;]?//gi; # remove old session ids
    $url =~ s/\?/?session_id=$STAT::Session->{_session_id}&/;
  } else {
    $url .= "?session_id=$STAT::Session->{_session_id}";
  }
#  print STDERR "  --> $url\n";
  return $url;
}

sub print_revision {
  my ($rev) = @_;
  return "<p style=\"color: #999; margin-top: 1em;\"><em>$rev</em></p>";
}

sub source {
  my ($rev) = @_;
  my $source = 'Util::source => unknown';
  if ( $rev =~ /Header:.+stat\/(interface\/)?([^,]+),v/ ) {
    $source = $2;
  } elsif ( $rev =~ /Id: ([^,]+),v/ ) {
    $source = $1;
  }
  return $source;
}

sub version {
  my ($rev) = @_;
  my $version = '';
  if ($rev =~ /(,v(.+)) \d\d?:\d\d?/) {
    $version = "v.$2";
  }
  return $version;
}

sub id_of_overall {
  my ($dbh) = @_;
  my $query = q(SELECT id FROM activity WHERE label ~* '^overall.+assessment$');
  my ($ret) = $dbh->selectrow_array($query);
  die "can't run query: $query, " . $dbh->errstr if $dbh->err;
  return $ret;
}

sub sequence_of_months {
  my ($from_year, $from_month, $to_year, $to_month) = @_;

  die "wrong year range: $from_year .. $to_year" if $from_year > $to_year;
  if ( $from_year == $to_year ) {
    return map {"$from_year:$_"} $from_month .. $to_month;
  }
  else {
    my @seq = map {"$from_year:$_"} $from_month .. 12;
    foreach my $year ( $from_year + 1 .. $to_year - 1 ) {
      push @seq, map {"$year:$_"} 1 .. 12;
    }
    push @seq, map {"$to_year:$_"} 1 .. $to_month;
    return @seq;
  }
}

# this sub names (or gives absolute times, depending on $format)
# of the first and last day of each weeks
sub sequence_of_weeks {
  my ($from_date, $to_date, $format) = @_;
  $format = "%b %e %Y" unless $format;
  $from_date = UnixDate(ParseDateString("epoch $from_date"), "%b %e %Y") if $from_date =~ /^\d+$/;
  $to_date = UnixDate(ParseDateString("epoch $to_date"), "%b %e %Y") if $to_date =~ /^\d+$/;
  my @seq;
  foreach my $mon ( ParseRecur("0:0:1*:0:0:0", $from_date, $from_date, $to_date) ) { # "every monday"
    my $sun = DateCalc($mon, "+ 6 days");
    my $first_day = UnixDate($mon, $format);
    my $last_day = UnixDate($sun, $format);
    push @seq, "$first_day:$last_day";
  }
  return @seq;
}

# this returns full-week intervals in absolute times
sub sequence_of_week_intervals {
  my ($from_date, $to_date, $format) = @_;
  $format = "%b %e %Y" unless $format;
  $from_date = UnixDate(ParseDateString("epoch $from_date"), "%b %e %Y") if $from_date =~ /^\d+$/;
  $to_date = UnixDate(ParseDateString("epoch $to_date"), "%b %e %Y") if $to_date =~ /^\d+$/;
  my @seq;

  foreach my $mon ( ParseRecur("0:0:1*:0:0:0", $from_date, $from_date, $to_date) ) { # "every monday"
    my $next_mon = DateCalc($mon, "+ 7 days");
    my $from = UnixDate($mon, $format);
    my $to = UnixDate($next_mon, $format);
    push @seq, "$from:$to";
  }
  return @seq;
}

sub get_time_log_this_month {
  my ($dbh, $user) = @_;

  my $query = qq(
SELECT oid,
       to_char("in", 'DD Mon YYYY HH24:MI'),
       to_char("out", 'DD Mon YYYY HH24:MI'),
       cast(extract('epoch' FROM "out" - "in") as integer)
  FROM time_log
 WHERE "id" = '$user'
--   AND date_part('year', "in") = date_part('year', 'now'::date)
--   AND date_part('week', "in") = date_part('week', 'now'::date)
 ORDER BY "in" DESC
);
  my $log = $dbh->selectall_arrayref($query);
  die "can't run query: $query, " . $dbh->errstr if $dbh->err;
  foreach my $row ( @$log ) {
    my $interval = $row->[3];
    if ( $interval ) {
      $interval /= 3600;
      my ($whole, $frac) = split /\./, $interval;
      $frac = $frac ? sprintf("%02d", int(".$frac" * 60 + 0.5)) : "00";
      $interval = "$whole:$frac";
    } else {
      $interval = "0:00";
    }
    $row->[3] = $interval;
  }
  return $log;
}

sub get_hours_per_week {
  my ( $dbh, $user, $week_offset ) = @_;
  $week_offset = 0 unless $week_offset; # can be undef, 0, -1, -2, ...
  die "week offset must be zero or negative" if $week_offset > 0;

  my $last_monday = Date_GetPrev("epoch " . time(), 'Mon', 1, "00:00:00");
  my $next_monday = DateCalc($last_monday, '+1 week');
  $last_monday = DateCalc($last_monday, "$week_offset week");
  $next_monday = DateCalc($next_monday, "$week_offset week");

  my $total = work_hours( $dbh, $user, UnixDate($last_monday, "%o"), UnixDate($next_monday, "%o") );
  return "0:0" unless $total;
  my ($whole, $frac) = split /\./, $total;
  $frac ||= '0';
  $frac = sprintf("%02d", int(".$frac" * 60 + 0.5));
  return "$whole:$frac";
}

sub average_monthly_hours {
  my ( $dbh, $user ) = @_;

  # get the total work time
  my $query = qq(SELECT cast(extract('epoch' FROM sum("out" - "in")) AS integer)  FROM time_log WHERE "id" = '$user');
  my ( $work_time ) = $dbh->selectrow_array($query);
  die "query failed ($dbh->errstr), in: $query" if $dbh->err;

  # get the accounting period
  $query = qq(SELECT cast(extract('epoch' FROM (max("out") - min("in"))) AS integer)  FROM time_log WHERE "id" = '$user');
  my ( $accounting_period ) = $dbh->selectrow_array($query);
  die "query failed ($dbh->errstr), in: $query" if $dbh->err;
  return "" unless $accounting_period > 24*3600;

  # subtract the long gaps ( > 3 days )
  $query = qq(
SELECT sum(gap) FROM (
  SELECT l1."out", cast(extract('epoch' FROM min(l2."in" - l1."out")) as integer) as gap
    FROM time_log l1 INNER JOIN time_log l2
      ON l2."in" >= l1."out"
     AND l2."id" = l1."id"
     AND l1."id" = '$user'
   GROUP BY l1."out"
  ) AS gaps
  WHERE gap > 3*3600*24
);
  my ( $time_of_absence ) = $dbh->selectrow_array($query);
  die "query failed ($dbh->errstr), in: $query" if $dbh->err;
  $time_of_absence ||= 0;
  $time_of_absence = $accounting_period - $work_time if $time_of_absence > $accounting_period; # this can only happen if the log ends in an open interval

  my $number_of_months = ($accounting_period - $time_of_absence)/30/24/3600;
  $number_of_months = 1 if $number_of_months < 1;
  return int($work_time/$number_of_months/3600);
}

sub work_hours {
  # return the sum of work hours in the interval between $from and $to
  my ( $dbh, $trainee, $from, $to ) = @_;
  if ( $from =~ /^\d+$/ ) {
    # TZ! (why not timestamp with time zone?)
    $from = qq(TIMESTAMP 'epoch' + $from * INTERVAL '1 second');
  } else {
    $from = "'$from'";
  }
  if ( $to =~ /^\d+$/ ) {
    # TZ!
    $to = qq(TIMESTAMP 'epoch' + $to * INTERVAL '1 second');
  } else {
    $to = "'$to'";
  }
  # this query doesn't aggregate on aliases, so sum up later
  my $query = qq(
SELECT
   CASE WHEN "in" > $from -- max of the lower endpoints
     THEN "in"
     ELSE $from
   END as "from",
   CASE WHEN "out" < $to -- min of the upper endpoints
     THEN "out"
     ELSE $to
   END as "to"
  FROM "time_log"
 WHERE "id" = '$trainee'
   AND (
         (("out" >= $to) AND ("in" <= $to))
         OR
         (($to >= "out") AND ($from <= "out"))
       )
);
  my ( $res ) = $dbh->selectall_arrayref($query);
  die "query failed ($dbh->errstr), in: $query" if $dbh->err;

  return undef unless $res;

  my $sum = 0;
  foreach my $interval ( @$res ) {
    $sum += Delta_Format(DateCalc(@$interval), 4, "%ht");
  }
  $sum = sprintf("%3.1f", $sum);
  $sum =~ s/\.0$//;
  return $sum;
}

sub work_hours_per_month {
  my ( $dbh, $trainee, $year, $month ) = @_;

  my $from = ParseDateString("${year}-${month}-01 00:00");
  my $to = DateCalc($from, '+ 1 month');

  return work_hours( $dbh, $trainee, UnixDate($from, "%o"), UnixDate($to, "%o") );
}

sub change_log {
  my ( $dbh, $uid, $input, $error ) = @_;
  my $err = $error ? 't' : 'f';
  $error = $error ? "'$error'" : "NULL";
  my $query = qq(
INSERT INTO time_change_log
         ("when", "uid", "total", "err", "input", "error")
  VALUES (now(), '$uid',
                         (SELECT sum ("out" - "in") FROM time_log WHERE "id" = '$uid'),
                                  '$err', '$input', $error);
);
  $dbh->do($query);
  die "can't execute: $query; reason: " . $dbh->errstr if $dbh->err;
  $dbh->commit;
}

sub last_survey_number {
  # return the sequence number of the last survey
  my ( $dbh, $user ) = @_;
  my ($last_no) = $dbh->selectrow_array(qq(SELECT max("n") FROM survey WHERE "user" = '$user'));
  die $dbh->errstr if $dbh->err;
  return $last_no;
}

sub time_since_survey {
  # return the time elapsed since last survey
  my ( $dbh, $user ) = @_;
  my $query = qq(SELECT now() - max("when") FROM survey WHERE "user" = '$user');
  my ( $time ) = $dbh->selectrow_array($query);
  die "couldn't run query: $query; reason: " . $dbh->errstr if $dbh->err;
  return $time;
}

sub activity_table {
  my ($dbh) = @_;
  return clone_exists($dbh) ? 'activity_clone' : 'activity';
}

sub clone_exists {
  my ($dbh) = @_;
  my ($ret) = $dbh->selectrow_array(q(SELECT count(*) FROM pg_class WHERE relname = 'activity_clone'));
  die $dbh->errstr if $dbh->err;
  return $ret;
}

sub copy_buffer_exists {
  my ($dbh) = @_;
  my ($ret) = $dbh->selectrow_array(q(SELECT count(*) FROM pg_class WHERE relname = 'copy_buffer'));
  die $dbh->errstr if $dbh->err;
  return $ret;
}

sub node_label_in_clone {
  my ($dbh, $id) = @_;
  my ($label) = $dbh->selectrow_array(qq(SELECT label FROM activity_clone WHERE id = $id));
  die $dbh->errstr if $dbh->err;
  return $label;
}

sub is_general {
  my ($node, $dbh, $activity_table) = @_;
  my $query = qq(
SELECT count(*) from (
  SELECT parent.label
  FROM "$activity_table" AS node, "$activity_table" AS parent
  WHERE node.left_id BETWEEN parent.left_id AND parent.right_id
  AND node.id = $node
) AS path
  WHERE label ~* 'general capabilities'
);
  my ($ret) = $dbh->selectrow_array($query);
  die $dbh->errstr if $dbh->err;
  return $ret;
}

sub next_available_id {
  my ($dbh) = @_;
  my $query = qq(
SELECT id - 1 AS id
  FROM activity_clone t1
 WHERE NOT EXISTS(
    SELECT 1 FROM activity_clone t2
     WHERE t1.id = t2.id + 1
   )
   AND id <> 0
 LIMIT 1
);
  my ($id) = $dbh->selectrow_array($query);
  die $dbh->errstr if $dbh->err;
  unless ( $id ) {
    # if nothing was returned, there are no gaps. Take the higest id.
    $query = "SELECT max(id) + 1 FROM activity_clone";
    ($id) = $dbh->selectrow_array($query);
    die $dbh->errstr if $dbh->err;
  }

  # This is a bad cludge. Each new id must be recorded in the source table.
  # The negative parent must be cleaned up later, after the user of this
  # routine is done using it.
  $query = "INSERT INTO activity_clone (id, parent) VALUES ($id, -1)";
  $dbh->do($query);
  die $dbh->errstr if $dbh->err;

  return $id;
}

sub list_ldap_directory {
  $STAT::ldap_ssl ? require Net::LDAPS : require Net::LDAP;
  my $port = defined $STAT::ldap_port ? ":$STAT::ldap_port" : "";
  my $dir = ($STAT::ldap_ssl ? Net::LDAPS->new("$STAT::ldap_host$port") : Net::LDAP->new("$STAT::ldap_host$port")) or die "$@";
  my @attr = qw(cn sn givenName uid mail);

  $dir->bind;

  my $res;
  $res = $dir->search ( base => $STAT::ldap_base,
      filter => "(uid=*)",
      attrs  => \@attr,
          );

  $res->code and die $res->error;

  my @list;
  foreach my $entry ( $res->entries ) {
    my $uid = $entry->get_value('uid');
    my $sn = $entry->get_value('sn');
    my $cn = $entry->get_value('cn');
    my $givenName = $entry->get_value('givenName');
    my $mail = $entry->get_value('mail');
    my %res = (
  uid => $uid,
  sn => $sn,
  cn => $cn,
  givenName => $givenName,
  mail => $mail,
    );
    push @list, \%res;
  }
  return @list
}


sub raw_ldap_entry {
  my ($uid, $dept_attr) = @_;
  $STAT::ldap_ssl ? require Net::LDAPS : require Net::LDAP;
  my $port = defined $STAT::ldap_port ? ":$STAT::ldap_port" : "";
  my $dir = ($STAT::ldap_ssl ? Net::LDAPS->new("$STAT::ldap_host$port") : Net::LDAP->new("$STAT::ldap_host$port")) or die qq(Cannot connect to LDAP server "$STAT::ldap_host$port"; $@);

  my $res = $dir->bind;
  $res->code and die $res->error;

  my @attr = qw/sn cn mail givenName/;
  push @attr, $dept_attr if $dept_attr;
  $res = $dir->search (
                       base => $STAT::ldap_base,
                       filter => "(uid=$uid)",
                       attrs  => \@attr,
                      );
  $dir->unbind;

  $res->code and die $res->error;

  if ( $res->entries ) {
    my $entry = $res->entry(0);
    my $sn = $entry->get_value('sn') || "sn:$uid";
    my $cn = $entry->get_value('cn') || "cn:$uid";
    my $givenName = $entry->get_value('givenName') || "givenName:$uid";
    my $mail = $entry->get_value('mail') || "missing-addr:$uid";
    my %res = (
  uid => $uid,
  sn => $sn,
  cn => $cn,
  givenName => $givenName,
  mail => $mail,
    );
    $res{department} = $entry->get_value($dept_attr) if $dept_attr;
    return \%res;
  } else {
    return {uid => $uid, sn => "[$uid]", cn => "[$uid]", givenName => undef, mail => undef}
  }
}

# This routine protects against a very unusual error that occurs
# when one or more of the multiple LDAP servers do not return the
# required attributes. It makes multiple attempts, until it hits
# many enough functional servers to fill all attributes.
sub ldap_entry {
  my ($uid) = @_;
  my %dirent = (
    uid => $uid,
    sn => "Unknown($uid)",
    cn => "Unknown($uid)",
    mail => "Unknown($uid)",
    givenName => "Unknown($uid)"
         );

  foreach my $i ( 0 .. 5 ) {
    my $res = raw_ldap_entry($uid);
    $dirent{sn} = $res->{sn} if $res->{sn};
    $dirent{cn} = $res->{cn} if $res->{cn};
    $dirent{mail} = $res->{mail} if $res->{mail};
    $dirent{givenName} = $res->{givenName} if $res->{givenName};
    if ( not grep(/Unknown/, values %dirent) ) {
      return \%dirent;
    }
  }
}

sub ldap_password_valid {
  my ($dirent, $password) = @_;
  my $uid = $dirent->{uid};

  $STAT::ldap_ssl ? require Net::LDAPS : require Net::LDAP;
  my $port = defined $STAT::ldap_port ? ":$STAT::ldap_port" : "";
  my $dir = ($STAT::ldap_ssl ? Net::LDAPS->new("$STAT::ldap_host$port") : Net::LDAP->new("$STAT::ldap_host$port")) or die "$@";

  my $res = $dir->bind(
                       "uid=$uid,$STAT::ldap_base",
                       password => $password,
                      );

  $res->code or $dir->unbind;

  return not $res->code;
}

sub unix_passwd_entry {
  my ($pwfile, $username) = @_;
  open PASSWD, "<$pwfile" or die "can't open password file $pwfile; error: $!";
  my %user;
  while ( <PASSWD> ) {
    my ($username, $password, $uid, $gid, $gecos) = split ":";
    $user{$username} = {password => $password, gecos => $gecos};
  }
  close PASSWD;
  if ( %user ) {
    if ( exists $user{$username} ) {
      my $gecos = $user{$username}->{gecos};
      my ($cn, $mail) = split(/,\s*/, $gecos);
      my ($name, $surname) = split(/\s+/, $cn);
      return {
        uid => $username,
        cn => $cn,
        givenName => $name,
        sn => $surname,
        mail => $mail,
        password => $user{$username}->{password},
       };
    }
  }
  else {
    return undef;
  }
}

sub search_unix_passwd_file {
  my ($pwfile, $pattern) = @_;
  open PASSWD, "<$pwfile" or die "can't open password file $pwfile; error: $!";
  my @result;
  use Data::Dumper;
  while ( <PASSWD> ) {
    next unless /$pattern/;
    my %user;
    my ($user, $password, $uid, $gid, $gecos) = split ":";
    my ($cn, $mail) = split(/,\s*/, $gecos);
    my ($name, $surname) = split(/\s+/, $cn);
    push @result, {
       uid => $user,
       cn => $cn,
       givenName => $name,
       sn => $surname,
       mail => $mail,
       password => $password,
      };
  }
  return @result;
}

sub unix_password_valid {
  my ($dirent, $password) = @_;
  return undef unless "password";
  return undef unless $dirent->{password};
  return crypt($password, $dirent->{password}) eq $dirent->{password};
}

sub password_valid {
  my ( $person, $password ) = @_;

  die "person is undefined" unless $person;

  return undef unless $password;

  if ( $person->{dirtype} eq 'LDAP' ) {
    return ldap_password_valid($person, $password);
  }
  elsif ( $person->{dirtype} eq 'passwd' ) {
    return unix_password_valid($person, $password);
  }
  else {
    die "unknown directory type '$person->{dirtype}'";
  }
}

sub send_alert {
  require Mail::Sendmail;

  my ($user, $teammate_data, $assessment_id, $procedure, $date, $role) = @_;
  my ($teammate_uid, $teammate_name, $dept) = split ':', $teammate_data;
  my ( $teammate ) = Person->search_by_uid($teammate_uid);  #FQDN!
  my $url = "https://$STAT::machine/$STAT::application/eval.html?link=$assessment_id";
  my $teammate_role = $role eq 'trainee' ? 'attending' : 'trainee';
  my %mail = (
        smtp => $STAT::mail_relay,
        To => $teammate->mail,
        Bcc => $STAT::alert_bcc,
        From => $STAT::contact,
        'Reply-to' => $STAT::contact,
              Subject => "STAT alert : " . $user->cn . " submitted an assessment",
        Message => qq(

Please follow this link to assess the case submitted by your $role on $date:

$url

Or, visit the top page of STAT:

https://$STAT::machine/$STAT::application

)
       );
  require Mail::Sendmail;
  Mail::Sendmail::sendmail(%mail) or die $Mail::Sendmail::error;
}

sub find_paired {
  my ($dbh, $user, $date, $case_no, $activity, $trainee, $attending) = @_;
  my $query = qq(\
SELECT "id"
  FROM "case"
 WHERE activity = $activity
   AND date = '$date'
   AND case_no = $case_no
   AND trainee = '$trainee'
   AND attending = '$attending'
   AND assessor != '$user'
);
  my $res = $dbh->selectcol_arrayref($query);
  die $dbh->errstr . "in query: $query" if $dbh->err;
  return @$res;
}

sub is_duplicate {
  my ($dbh, $date, $case_no, $activity, $trainee, $attending, $assessor) = @_;
  my $query = qq(\
SELECT "id", "timestamp"
  FROM "case"
 WHERE activity = $activity
   AND date = '$date'
   AND case_no = $case_no
   AND trainee = '$trainee'
   AND attending = '$attending'
   AND assessor = '$assessor'
);
  my $res = $dbh->selectall_arrayref($query);
  die $dbh->errstr . "in query: $query" if $dbh->err;
  return $res;
}

sub last_similar_case {
  my ($dbh, $user, $date,  $activity, $trainee, $attending) = @_;
  my $query = qq(\
SELECT max(case_no)
  FROM "case"
 WHERE activity = $activity
   AND date = '$date'
   AND trainee = '$trainee'
   AND attending = '$attending'
);
  my ($res) = $dbh->selectrow_array($query) or 0;
  die $dbh->errstr . "in query: $query" if $dbh->err;
  return $res;
}

sub pg_escape_apostrophe {
  # duplicates each apostrophe in the source text to make it safe for postrges
  my ($text) = @_;
  $text =~ s/\'/<apostrophe>/g;
  $text =~ s/<apostrophe>/\'\'/g;
  return $text;
}

sub trim_blanks {
  # removes all leading and trailing white space, including tabs and newlines
  my ($text) = @_;
  while ( substr($text, 0, 1) =~ /[\r\n\t ]/ ) { $text = substr($text, 1); }
  while ( substr($text, -1, 1) =~ /[\r\n\t ]/ ) { $text = substr($text, 0, length($text) - 1); }
  return $text;
}

sub submit_pearl {
  my ($dbh, $person, $nodeID, $base_path, $text) = @_;
  my $uid = $person->uid;
  my $escaped_path = Util::pg_escape_apostrophe($base_path);
  $text = Util::trim_blanks(Util::pg_escape_apostrophe($text));
  my $query = qq(INSERT INTO note ("when", "user", "activity", "path", "text") VALUES ('now', '$uid', $nodeID, '$escaped_path', '$text'));
  $dbh->do($query);
  die $dbh->errstr . "in query: $query" if $dbh->err;
  $dbh->commit;
}

sub submit_feedback {
  my ($dbh, $person, $nodeID, $base_path, $text) = @_;
  my $uid = $person->uid;
  my $escaped_path = Util::pg_escape_apostrophe($base_path);
  $text = Util::pg_escape_apostrophe($text);
  $text = Util::trim_blanks($text);
  my $query = qq(INSERT INTO feedback ("when", "user", "activity", "path", "text") VALUES ('now', '$uid', $nodeID, '$escaped_path', '$text'));
  $dbh->do($query);
  die $dbh->errstr . "in query: $query" if $dbh->err;
  $dbh->commit;

  my %mail = (
        smtp => $STAT::mail_relay,
        To => $STAT::contact,
        Bcc => $STAT::alert_bcc,
        From => $person->mail,
        Subject => "STAT alert: " . $person->cn . " entered feedback",
        Message => qq(
Message regarding node $nodeID,
  $base_path:

$text
)
       );
  require Mail::Sendmail;
  Mail::Sendmail::sendmail(%mail) or die $Mail::Sendmail::error;
}

sub full_month_name {
  my ( $month ) = @_; # expect "year:month";
  my ( $y, $m ) = split ":", $month;
  my @name = qw/none January February March April May June July August September October November December/;
  return "$name[$m] of $y";
}

1;
