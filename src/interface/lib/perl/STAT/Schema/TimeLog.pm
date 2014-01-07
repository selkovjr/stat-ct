package STAT::Schema::TimeLog;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("time_log");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "in",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "out",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->belongs_to("id", "STAT::Schema::Role", { user => "id" });


# Created by DBIx::Class::Schema::Loader v0.04003 @ 2009-06-02 10:46:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nc/bEsPY8+hCiPcW+y64pQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
