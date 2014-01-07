package STAT::Schema::DirectoryCache;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("directory_cache");
__PACKAGE__->add_columns(
  "uid",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "domain",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "dirtype",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "password",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "cn",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "sn",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "givenname",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "mail",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "department",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "ts",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("uid", "domain");
__PACKAGE__->add_unique_constraint("directory_cache_pkey", ["uid", "domain"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2012-01-22 14:18:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:E2/LRdcK6pMH/6IGkCUSrw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
