package STAT::Schema::ActivityChangeLog;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("activity_change_log");
__PACKAGE__->add_columns(
  "version",
  {
    data_type => "integer",
    default_value => "nextval(('activity_log_seq'::text)::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "when",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "who",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("version");
__PACKAGE__->add_unique_constraint("activity_change_log_pkey", ["version"]);


# Created by DBIx::Class::Schema::Loader v0.04003 @ 2009-06-02 08:34:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:B0MnlvrVvF5M35IteZoZMw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
