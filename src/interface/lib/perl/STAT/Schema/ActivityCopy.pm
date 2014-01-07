package STAT::Schema::ActivityCopy;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("activity_copy");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "parent",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "left_id",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "right_id",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "required",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "opt",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "label",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04003 @ 2009-06-02 08:34:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/oeKGKRxmifJjUsXIM5+3g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
