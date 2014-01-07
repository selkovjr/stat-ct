package STAT::Schema::Service;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("service");
__PACKAGE__->add_columns(
  "uid",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "service",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04003 @ 2009-06-02 12:39:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SKET3DDDkbOzCxAckBEIRw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
