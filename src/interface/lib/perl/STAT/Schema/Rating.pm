package STAT::Schema::Rating;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("rating");
__PACKAGE__->add_columns(
  "value",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 0,
    size => 2,
  },
  "symbol",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "desc",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("value");
__PACKAGE__->add_unique_constraint("rating_pkey", ["value"]);
__PACKAGE__->has_many(
  "evals",
  "STAT::Schema::Eval",
  { "foreign.assessment" => "self.value" },
);


# Created by DBIx::Class::Schema::Loader v0.04003 @ 2009-06-02 08:34:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:f4rwe5nI3fjY13u3HX3SfQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
