package STAT::Schema::CurrentAcademicYear;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table('DUMMY');
__PACKAGE__->add_columns("year");

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(q[
SELECT
  CASE WHEN 'now'::timestamptz < date_trunc('year', 'now'::timestamptz) + ?::interval
    THEN extract(YEAR FROM 'now'::timestamptz) - 1
    ELSE extract(YEAR FROM 'now'::timestamptz)
  END
  AS year
]);
