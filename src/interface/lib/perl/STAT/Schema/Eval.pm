package STAT::Schema::Eval;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("eval");
__PACKAGE__->add_columns(
  "case",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "activity",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "assessment",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "np_reason",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->belongs_to("np_reason", "STAT::Schema::NpReason", { code => "np_reason" });
__PACKAGE__->belongs_to("activity", "STAT::Schema::Activity", { id => "activity" });
__PACKAGE__->belongs_to("case", "STAT::Schema::Case", { id => "case" });
__PACKAGE__->belongs_to(
  "assessment",
  "STAT::Schema::Rating",
  { value => "assessment" },
);


# Created by DBIx::Class::Schema::Loader v0.04003 @ 2009-06-02 08:34:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qt09hCyzR2W1l/3Jiw2k9g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
