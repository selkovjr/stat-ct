package STAT::Schema::Absent;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("absent");
__PACKAGE__->add_columns(
  "uid",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("uid");
__PACKAGE__->add_unique_constraint("absent_pkey", ["uid"]);
__PACKAGE__->belongs_to("uid", "STAT::Schema::Role", { user => "uid" });


# Created by DBIx::Class::Schema::Loader v0.04003 @ 2009-06-02 12:39:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kBKbFCHoROJQsXRlwrbnjw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
