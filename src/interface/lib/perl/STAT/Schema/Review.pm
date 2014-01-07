package STAT::Schema::Review;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("review");
__PACKAGE__->add_columns(
  "when",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "attending",
  {
    data_type => "text",
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
  "plan",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04003 @ 2009-06-02 08:34:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EPIe0PkUzJ9l+AMpRim/WQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
