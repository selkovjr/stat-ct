package STAT::Schema::NpReason;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("np_reason");
__PACKAGE__->add_columns(
  "order",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "code",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "text",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("code");
__PACKAGE__->add_unique_constraint("np_reason_pkey", ["code"]);
__PACKAGE__->has_many(
  "evals",
  "STAT::Schema::Eval",
  { "foreign.np_reason" => "self.code" },
);


# Created by DBIx::Class::Schema::Loader v0.04003 @ 2009-06-02 08:34:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jqs5zzaIgaVedklQJY1RhQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
