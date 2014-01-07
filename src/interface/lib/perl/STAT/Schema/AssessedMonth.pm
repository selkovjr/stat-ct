package STAT::Schema::AssessedMonth;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table('DUMMY');
__PACKAGE__->add_columns("trainee", "year", "month");

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(q[
SELECT DISTINCT trainee, 
       extract(YEAR FROM "date") AS year,
       extract(MONTH FROM "date") AS month
  FROM "case"
]);
