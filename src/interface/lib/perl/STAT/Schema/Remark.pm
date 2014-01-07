package STAT::Schema::Remark;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("remark");
__PACKAGE__->add_columns(
  "case",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "text",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->belongs_to("case", "STAT::Schema::Case", { id => "case" });


# Created by DBIx::Class::Schema::Loader v0.04003 @ 2009-06-02 08:34:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RkPB64a82ONPnmDGS4XaLg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
