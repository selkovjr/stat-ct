#!PERL_PATH
use HTML::Mason::CGIHandler;
#use MasonX::Profiler;

my $h = HTML::Mason::CGIHandler->new(
  #preamble => 'my $p = MasonX::Profiler->new($m, $r);',
  data_dir => 'STAT_DIR/var/mason',
  comp_root => [['root', 'DOCROOT'], ['stat', 'THIS_DIR']],
  error_mode => 'output',
  allow_globals => [qw($Cache $Dbh $Schema $Model $User $LastUserID)],
);

$h->handle_request;
