package STAT::Schema::Case;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table('"case"');
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval(('case_id_seq'::text)::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "date",
  { data_type => "date", default_value => undef, is_nullable => 1, size => 4 },
  "timestamp",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "case_no",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "activity",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "trainee",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "attending",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "assessor",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("case_pkey", ["id"]);
__PACKAGE__->belongs_to("assessor", "STAT::Schema::Role", { user => "assessor" });
__PACKAGE__->belongs_to("activity", "STAT::Schema::Activity", { id => "activity" });
__PACKAGE__->belongs_to("attending", "STAT::Schema::Role", { user => "attending" });
__PACKAGE__->belongs_to("trainee", "STAT::Schema::Role", { user => "trainee" });
__PACKAGE__->has_many("evals", "STAT::Schema::Eval", { "foreign.case" => "self.id" });
__PACKAGE__->has_many(
  "remarks",
  "STAT::Schema::Remark",
  { "foreign.case" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04003 @ 2009-06-02 08:34:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PUZVUbr7I6hrEIQmaLukAw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
