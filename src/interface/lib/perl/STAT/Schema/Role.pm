package STAT::Schema::Role;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("role");
__PACKAGE__->add_columns(
  "user",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "rolename",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "can_see_overview",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "can_see_results",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("user");
__PACKAGE__->add_unique_constraint("role_pkey", ["user"]);
__PACKAGE__->has_many(
  "absents",
  "STAT::Schema::Absent",
  { "foreign.uid" => "self.user" },
);
__PACKAGE__->has_many(
  "case_assessors",
  "STAT::Schema::Case",
  { "foreign.assessor" => "self.user" },
);
__PACKAGE__->has_many(
  "case_attendings",
  "STAT::Schema::Case",
  { "foreign.attending" => "self.user" },
);
__PACKAGE__->has_many(
  "case_trainees",
  "STAT::Schema::Case",
  { "foreign.trainee" => "self.user" },
);
__PACKAGE__->has_many(
  "time_logs",
  "STAT::Schema::TimeLog",
  { "foreign.id" => "self.user" },
);


# Created by DBIx::Class::Schema::Loader v0.04003 @ 2009-06-02 12:39:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WtIaEvo7O+6pJykPpL5s0w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
