#!PERL_PATH
use HTML::Mason::CGIHandler;

# I have no idea why this needs to be done, but it is important:
$ENV{PATH_INFO} =~ s{STAT_URL}{}; # (!) this is a template; STATURL will be replaced with ~/public_html/stat
# Another (worse) way of doing it would be to fix /usr/lib/perl5/site_perl/5.8.6/HTML/Mason/Request.pm
# in _initialize():
#    $request_comp =~ s{~selkovjr/stat/interface/}{};
#
# Everything works fine when comp_root is part of Apache DocumentRoot:
#  comp_root  => [['root', '/home/www/root'], ['stat', '/home/www/root/stat']],

my $h = HTML::Mason::CGIHandler->new(
  data_dir => 'STAT_DIR/var/mason',
  comp_root => 'STAT_DIR',
  error_mode => 'output',
  allow_globals => [qw($Dbh $Schema $Model $User $UserID $LastUserID)],
);

$h->handle_request;
