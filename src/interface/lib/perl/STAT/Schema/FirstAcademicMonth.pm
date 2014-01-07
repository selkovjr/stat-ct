package STAT::Schema::FirstAcademicMonth;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table('DUMMY');
__PACKAGE__->add_columns("month");

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(q[
SELECT extract(MONTH FROM date_trunc('year', 'now'::timestamptz) + ?::interval) AS month
]);
