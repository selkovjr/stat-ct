package STAT::Schema::FergusonComponent;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("component");
__PACKAGE__->add_columns(
  "procedure",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
 "seq",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "difficulty",
  {
    data_type => "char(1)",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "tp",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "dp",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  }
);

# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-01-22 14:18:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:E2/LRdcK6pMH/6IGkCUSrw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
