package STAT::ServerLog;

# Described in http://www.stonehenge.com/merlyn/LinuxMag/col77.html
# (Randall's 77th column in Linux Magazine)

use 5.010001;
use strict;
use warnings;
our $VERSION = '0.01';

## usage: PerlPostConfigHandler STAT::ServerLog

## config
my $PNOTE_IDENTIFIER = 'DBILog_Times';  # Defines pnote name that will
                                        # be used to hold the initial
                                        # wall clock and CPU time
                                        # values. I'll set this up as
                                        # an array ref at the
                                        # beginning of the service
                                        # cycle, and when we arrive at
                                        # the logging phase, I can
                                        # pull the values back to see
                                        # what to subtract from the
                                        # current values to get the
                                        # deltas.

my $LOGGER = "/home/stat/bin/logger";         # Defines the external program
                                        # to accept the logging values
                                        # and write them into the
                                        # database.
## end config

use Apache2::Const qw(DECLINED OK NOT_FOUND);
use Apache2::Util qw(ht_time);
use Apache2::RequestUtil;
use Apache2::ServerRec;
use Apache2::RequestRec;
use Apache2::Connection;
use CGI::Cookie;

my $logger_handle;  # handle for the pipe to the logger program


# The subroutine that will be triggered in the parent Apache process
# just after the configuration files have been read, but before Apache
# begins forking children.
sub handler {
  my ($conf_pool, $log_pool, $temp_pool, $s) = @_;   # $s is a server handle

  print STDERR "Installing " . __PACKAGE__ . ":\n";

  ## warn "executed in $$\n";

  ## set this up in the "real" server:
  for (my $vs = $s; $vs; $vs = $vs->next) {
    print STDERR "  server " . $vs->server_hostname . ":" . $vs->port . " ...";
    if ( $vs->is_virtual ) {
      print STDERR "\n";
      next;
    }
    else {
      print STDERR " this is the real server; setting up PerlLogHandler and PerlPostReadRequestHandler\n";
#       Randal uses PerlPostReadRequestHandler to mark the start of
#       transaction, and it works in most cases, but for some reason
#       the requests served by Catalyst never reach that stage.
#       $vs->push_handlers(
#         # start of transaction
#         PerlPostReadRequestHandler => __PACKAGE__ . '::PerlPostReadRequestHandler'
#       );
      $vs->push_handlers(
        # start of transaction for Catalyst requests
        PerlHeaderParserHandler => __PACKAGE__ . '::PerlPostReadRequestHandler'
      );
      $vs->push_handlers(
        # end of transaction
        PerlLogHandler => __PACKAGE__ . '::PerlLogHandler'
      );
    }
  }

  open $logger_handle, "|$LOGGER"
    or die "Cannot create |$LOGGER: $!";  # this death is fatal to apache

  {  # unbuffer the pipe
    my $old = select($logger_handle);
    $| = 1;
    select($old);
  }

  return OK;  # this value is probably ignored, because we're not in a phase
              # which is actually serving a response.
}


# ---------------------------------------------------------------------------
# Once the child apache process has accepted a connection and read the headers,
# this handler is executed, signaling the start of the transaction
sub PerlPostReadRequestHandler {
  my $r = shift;    # request object

  # Filter out the unwanted requests
  if ( $r->uri =~ m{^/(~|SCAN|projects|people|faculty)} ) {
    $r->pnotes($PNOTE_IDENTIFIER, "ignore");
    return NOT_FOUND;
  }
  if ( $r->uri =~ /http:/ ) {
    $r->pnotes($PNOTE_IDENTIFIER, "ignore");
    return NOT_FOUND;
  }

  # Ignore (do not log) those that are not interesting
  if ( $r->uri =~ m{^/(robots.txt)} ) {
    $r->pnotes($PNOTE_IDENTIFIER, "ignore");
    return DECLINED;
  }

  # Reject subrequests, because we don't want to reset the counters if
  # a page uses a subrequest, such as to perform an include file or to
  # check the MIME type of a file in a directory listing.
  return DECLINED unless $r->is_initial_req;

  # The UNIX-epoch wall-clock time, plus four accumulated CPU times
  # (user CPU, system CPU, child-user CPU, and child-system
  # CPU). These values will form the start time for current hit.
  my @times = (time, times);
  $r->pnotes($PNOTE_IDENTIFIER, \@times);
  ## warn "saved @times in pnote\n";

  return DECLINED;  # so that other handlers at this phase will also
                    # be run. (I don't recall, but I suspect I can
                    # return OK as well, but this is safer and more
                    # familiar)
}


# ---------------------------------------------------------------------------
# The handler that is called at the end of the request cycle, during
# the Log phase.
sub PerlLogHandler {
  my $r = shift;
  # warn "running the handler for ", $r->uri, "\n";

  ## first, reap any zombies so child CPU is proper:
  {
    # Generally, child processes are finished anyway, so this is
    # typically a no-op, but if there are still some children running
    # that would have been reaped in the cleanup phase, I want to make
    # sure that their child CPU values don't get charged to the wrong
    # process.
    my $kid = waitpid(-1, 1);
    if ($kid > 0) {
      # $r->warn("found kid $kid"); # DEBUG
      redo;
    }
  }

  # recall the start time
  if ( $r->pnotes($PNOTE_IDENTIFIER) and $r->pnotes($PNOTE_IDENTIFIER) eq 'ignore' ) {
    return DECLINED;
  }
  my @times = @{$r->pnotes($PNOTE_IDENTIFIER) || []};
  unless (@times) {
    # "I have seen this message trigger occasionally, when a request
    # comes in but the browser disconnects before sending a complete
    # header, for example."
    $r->warn($r->uri, "   " . __PACKAGE__ . ": where is \@times?");
    return DECLINED;
  }

  ## delta these times:
  @times = map { $_ - shift @times } time, times;
  # Yikes! "I create a new list that results in pairing the new values
  # with each element of the old list one by one, subtracting the old
  # value"

  # Attempt to extract the $orig (original) and $last request record
  # from the current request record. When a request receives an
  # internal redirect, such as for a 404 handler, an additional
  # request record is added to the chain. I was having difficulty
  # finding my wanted values, as you'll see in the code a few lines
  # later, and decided to try looking at most of the likely elements
  # of the request chain.
  my $orig = $r->main || $r;
  my $last = $orig; $last = $last->next while $last->next;
  my $s = $orig->server;
  my $c = $orig->connection;

  # Fetch the server value, so that I can tell whether this is the
  # lightweight reverse-proxy server or the heavyweight backend
  # server. In the httpd.conf, I have:
  #
  #   PerlSetVar "DBILogServer" "[* kind *]"
  #
  # and "kind" expands to "P" for the proxy server and "B" for
  # the back server. This string ends up in $server for logging.
  my $server = $orig->dir_config->get("DBILogServer");


  my %data;

  # Try to find my unique-id (added by mod_unique_id). I was having
  # trouble finding it on some of the requests, so this is probably
  # overkill now, but I'm impatient.
  $data{uid} =
    $orig->headers_in->{"x-stonehenge-unique-id"} ||
      $r->headers_in->{"x-stonehenge-unique-id"} ||
        $last->headers_in->{"x-stonehenge-unique-id"} ||
          $orig->subprocess_env->{UNIQUE_ID} ||
            $r->subprocess_env->{UNIQUE_ID} ||
              $last->subprocess_env->{UNIQUE_ID};

  # "Try to find the cookie I created with my own Perl version of mod_usertrack."
  # It works as is with apache mod_usertrack.
  $data{cookie} =
    $orig->notes->{"cookie"} ||
      $r->notes->{"cookie"} ||
        $last->notes->{"cookie"};

  $data{stamp} = Apache2::Util::ht_time($r->pool, $orig->request_time);
  $data{host} = $c->get_remote_host;
  $data{server} = $server;
  # $data{vhost} = join(":", $s->server_hostname, $s->port);  # $s->port is always 0; query the request instead
  $data{vhost} = $s->server_hostname;
  $data{port} = $orig->get_server_port;
  $data{method} = $orig->method;
  $data{url} = ($orig->the_request =~ /^\S+\s+(\S+)/)[0];
  $data{session} = ($data{url} =~ /session_id(=|\%3D)([0-9a-f]+)/)[1];
  $data{basicauth} = $orig->user;
  $data{referer} = $orig->headers_in->{'Referer'};
  $data{useragent} = $orig->headers_in->{'User-agent'};
  $data{status} = $orig->status;
  $data{bytes} = $r->bytes_sent;
  @data{qw(wall cpuuser cpusys cpucuser cpucsys)} = @times;

  # use Data::Dumper;
  # print STDERR Dumper(\%data);

  my $data = join(" ",
                  map { defined $data{$_} ?
                          "$_=" . unpack("H*", $data{$_}) :
                            () }
                  sort keys %data
                 );

  ## we hope we get an atomic write here...
  print $logger_handle "<$data>\n"
    or die "Write error on $logger_handle: $!";
  ## hopefully, angle bracket markers will tell us if we got scrambled

  return OK;
}

1;

=head1 STAT::ServerLog

STAT::ServerLog - Apache-DBI log handler copied from Randal Schwarz's Stonehenge::DBILog

=head1 SYNOPSIS

In Apache configuration:

  PerlPostConfigHandler STAT::ServerLog

In the backend:

create table request (
  uid text,
  cookie text,
  session text,
  stamp timestamptz default now(),
  host inet not null,
  server text,
  vhost text not null,
  port int,
  method text not null,
  url text not null,
  basicauth text,
  referer text,
  useragent text,
  status int default 0,
  bytes int,
  wall int,
  cpuuser real,
  cpusys real,
  cpucuser real,
  cpucsys real
);

=head1 DESCRIPTION

Described in:

  http://www.stonehenge.com/merlyn/LinuxMag/col77.html
  http://www.stonehenge.com/merlyn/LinuxMag/col78.html

=head1 AUTHOR

Randal L. Schwartz <merlyn@stonehenge.com>


=head1 COPYRIGHT AND LICENSE

The original text was copyright by InfoStrada Communications, Inc.,
and was posted by Randall with their permission. Further distribution
or use was not permitted. The full text has appeared in an edited form
in Linux Magazine.

However, this version is a digest and is free of copyright.

=cut
