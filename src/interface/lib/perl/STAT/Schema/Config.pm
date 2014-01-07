package STAT::Schema::Config;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("config");
__PACKAGE__->add_columns(
  "param",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "value",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("param");
__PACKAGE__->add_unique_constraint("config_pkey", ["param"]);


# Created by DBIx::Class::Schema::Loader v0.04003 @ 2009-06-02 08:34:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:q3VzJwx2fyHmPQv969qydA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
