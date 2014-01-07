package STAT::Schema::Activity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("activity");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 0,
    size => 2,
  },
  "parent",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "left_id",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "right_id",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "required",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "opt",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "label",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("activity_pkey", ["id"]);
__PACKAGE__->belongs_to("parent", "STAT::Schema::Activity", { id => "parent" });
__PACKAGE__->has_many(
  "activities",
  "STAT::Schema::Activity",
  { "foreign.parent" => "self.id" },
);
__PACKAGE__->has_many(
  "cases",
  "STAT::Schema::Case",
  { "foreign.activity" => "self.id" },
);
__PACKAGE__->has_many(
  "evals",
  "STAT::Schema::Eval",
  { "foreign.activity" => "self.id" },
);
__PACKAGE__->has_many(
  "feedbacks",
  "STAT::Schema::Feedback",
  { "foreign.activity" => "self.id" },
);
__PACKAGE__->has_many(
  "notes",
  "STAT::Schema::Note",
  { "foreign.activity" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04003 @ 2009-06-02 08:34:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YC2HVDGU7/dkq0Wbbwm7Kw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
