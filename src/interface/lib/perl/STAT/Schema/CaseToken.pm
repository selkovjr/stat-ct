package STAT::Schema::CaseToken;

use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table("NONE");
__PACKAGE__->add_columns(qw/value/);
__PACKAGE__->result_source_instance
  ->name(\"(SELECT nextval('case_token') AS value)");

1;
