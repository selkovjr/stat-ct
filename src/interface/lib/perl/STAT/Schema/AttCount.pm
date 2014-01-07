package STAT::Schema::AttCount;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("att_count");
__PACKAGE__->add_columns(
  "count",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "average",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "overall",
  {
    data_type => "integer[]",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "trainee",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "attending",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04003 @ 2009-06-02 12:39:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:l183vz6GbnR5//LqaGDwfA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
