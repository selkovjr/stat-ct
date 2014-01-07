package STAT::Model;

use strict;
use warnings;

use Time::localtime;

my @monthAbbr = qw/none Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
my @monthName = qw/none January February March April May June July August September October November December/;

# --- constructor -----------------------------------------------------------
sub set_schema {
  my $self = {};
  my ($class, $schema) = @_;
  $self->{schema} = $schema;
  bless $self, $class;
}


# --- query methods ---------------------------------------------------------

sub assessments_of_case {
  # Return all assessments associated with the case.
  # The query returns each assessment as an aggregate hash of given and self-assessments,
  #   of the following form:
  #   {
  #     'given' => '"assessment_id_2:node_id"=>"value", "assessment_id_3:node_id"=>"value"',
  #     'self' =>  '"assessment_id_1:node_id"=>"value"'
  #   }
  #
  # The query generates hashes in the form suitable for being eval()'ed in perl. They
  # are pacted into the following structure:
  #
  #   $assessment = {
  #     given => {
  #       submissions => {
  #         assessment_id_2 => [number of ratings given in this submission],
  #         assessment_id_3 => [number of ratings given in that submission]
  #       },
  #       assessment_id_2 => {
  #         node => rating,
  #         node => rating,
  #            . . .
  #       },
  #       assessment_id_3 => {
  #         node => rating,
  #         node => rating,
  #            . . .
  #       },
  #     },
  #     self => {
  #       submissions => {
  #         assessment_id_1 => [number of ratings in self-assessment],
  #       },
  #       assessment_id_1 => {
  #         node => rating,
  #         node => rating,
  #            . . .
  #       }
  #     }
  #   }

  my ($self, %args) = @_;
  my $date = delete $args{date} or die "expecting a date argument";
  my $case_no = delete $args{case_no} or die "expecting a case_no argument";
  my $activity = delete $args{activity} or die "expectiing activity => nodeID";
  my $trainee = delete $args{trainee} or die "expecting trainee => uid";
  die "extraneous arguments: (" . join(", ", keys %args) . ")" if %args;

  # equivalent SQL:
  # --------------
  # SELECT add(
  #           hstore_in(textout(
  #            CASE WHEN c.assessor = c.trainee THEN
  #              c.id::text || ':' || e.activity::text || '=>' ||
  #                CASE WHEN e.assessment = -1 THEN
  #                  '-1:'::text || e.np_reason::text
  #                ELSE e.assessment::text END
  #            ELSE
  #              NULL
  #            END
  #          ))
  #        ) AS self,
  #        add(
  #          hstore_in(textout(
  #            CASE WHEN c.assessor = c.attending THEN
  #              c.id::text || ':' || e.activity::text || '=>' ||
  #                CASE WHEN e.assessment = -1 THEN
  #                  '-1:'::text || e.np_reason::text
  #                ELSE e.assessment::text END
  #            ELSE
  #              NULL
  #            END
  #          ))
  #        ) AS given
  #   FROM "case" c, eval e
  #  WHERE e."case" = c.id
  #    AND c."date" = '$date'
  #    AND c.case_no = $case_no
  #    AND c.activity = $activity
  #    AND c.trainee = '$trainee'
  #  GROUP BY c."date", c.trainee, c.case_no, c.activity, e.activity;

  my $rs = $self->schema->resultset('Case')->search({
      'me.date' => $date,
      'me.case_no' => $case_no,
      'me.activity' => $activity,
      'me.trainee' => $trainee,
    },
    {
      join => 'evals', # 'evals' is a relationship, not a table,
                         # but in the generated query it is actuallly a table alias
      +select => [
        { 'add' => [{ 'hstore_in' => [{ 'textout' => [q(
CASE WHEN me.assessor = me.trainee THEN
  me.id::text || ':' || evals.activity::text || '=>' ||
    CASE WHEN evals.assessment = -1 THEN
      '-1:'::text || evals.np_reason::text
    ELSE evals.assessment::text END
ELSE
  NULL
END
)
          ]}]}]
        },
        { 'add' => [{ 'hstore_in' => [{ 'textout' => [q(
CASE WHEN me.assessor = me.attending THEN
  me.id::text || ':' || evals.activity::text || '=>' ||
    CASE WHEN evals.assessment = -1 THEN
      '-1:'::text || evals.np_reason::text
    ELSE evals.assessment::text END
ELSE
  NULL
END
)
          ]}]}]
        },
      ],
      +as => ['self', 'given'],
      group_by => [ 'me.date', 'me.trainee', 'me.case_no', 'me.activity', 'evals.activity'],
    }
  );

  my $assessment;
  foreach my $row ( $rs->all ) {
    my %hash = $row->get_columns;
    foreach my $source ( 'self', 'given' ) {
      my %grade = eval $hash{$source};
      foreach my $key ( keys %grade ) {
        my ($assID, $node) = split ":", $key;
        $assessment->{$source}->{submissions}->{$assID}++;
        $assessment->{$source}->{$assID}->{$node} = $grade{$key} unless $grade{$key} =~ /-1:NR/;
      }
    }
  }
  return $assessment;
}


sub case_assessors {
  # return a hash of assessors indexed by assessment ids
  my ($self, %args) = @_;
  my $date = delete $args{date} or die "expecting a date argument";
  my $case_no = delete $args{case_no} or die "expecting a case_no argument";
  my $activity = delete $args{activity} or die "expectiing activity => nodeID";
  my $trainee = delete $args{trainee} or die "expecting trainee => uid";
  die "extraneous arguments: (" . join(", ", keys %args) . ")" if %args;

  # equivalent SQL:
  # --------------
  # SELECT id, assessor
  #   FROM "case"
  #  WHERE "date" = '$date'
  #    AND case_no = $case_no
  #    AND activity = $activity
  #    AND trainee = '$trainee'

  my $rs = $self->schema->resultset('Case')->search(
    {
      '"date"' => $date,
      case_no => $case_no,
      activity => $activity,
      trainee => $trainee,
    },
    {
      columns => ['id', 'assessor'],
    }
  );

  my %hash;
  foreach my $row ( $rs->all ) {
    $hash{$row->id} = $row->assessor->user; # this is quite odd because $row->assessor is a Role (?)
  }
  return \%hash;
}


sub cases_done_by {
  my ($self, $trainee_uid) = @_;
  return $self->schema->resultset('Case')->count({trainee => $trainee_uid})
}


sub number_of_cases {
  my ($self, %constraint) = @_;

  # equivalent SQL:
  # SELECT count(*) FROM (
  #   SELECT DISTINCT "date", "case_no", "activity", "trainee"
  #     FROM "case"
  #    WHERE $date_constraint
  #      AND $trainee_constraint
  # )

  my $rs = $self->schema->resultset('Case')->search(
    {
      %constraint
    },
    {
      columns  => [ qw/date case_no activity trainee/ ],
      group_by  => [ qw/date case_no activity trainee/ ]
    }
  );
  return $rs->count;
}


sub cases_like_this {
  my ($self, $trainee, $nodeID) = @_;
  my $rs = $self->schema->resultset('Case')->search(
    {
      activity => $nodeID,
      trainee => $trainee,
    },
    {
      select => [{
        distinct => [ qw/date case_no activity trainee/ ]
      }]
    }
  );
  return $rs;
}


sub case_token {
  my ($self) = @_;
  my ($res) = $self->schema->resultset('CaseToken')->search;
  return $res->value;
}


sub children_of {
  # return all children of the given node, preserving the order
  my ($self, $nodeID, %args) = @_;

  my $rs;

  if ( $args{extra_data} ) {
    $rs = $self->schema->resultset('Activity')->search(
      {
        parent => $nodeID
      },
      {
        join => [ 'notes' ],
        select => [ qw/id left_id required opt label/, { count => 'notes.user' } ],
        as     => [ qw/id left_id required opt label pearl_count / ],
        order_by => ['left_id'],
        group_by => [ qw/id left_id required opt label/ ],
      },
    );
  }
  else {
    $rs = $self->schema->resultset('Activity')->search(
      {
        parent => $nodeID
      },
      {
        columns => ['id', 'label'],
        order_by => ['left_id'],
      },
    );
  }
  return $rs->all;
}

sub config {
  my ($self, $param) = @_;
  my $p = $self->schema->resultset('Config')->find($param);
  if ( $p ) {
    return $p->value;
  }
  return '';
}

sub id_of {
  # return the tree node id for the given category name
  my ($self, $name) = @_;
  my $pattern = "^$name\$";
  my $rs = $self->schema->resultset('Activity')
    -> search({label => {'~*', $pattern}});
  die "pattern not found: '$pattern'" if $rs->count < 1;
  die "multiple matches found for '$pattern'" if $rs->count > 1;

  $rs->next->id;
}


sub id_of_overall {
  # return the tree node id for the Overall category

  #  equivalent SQL:
  #  --------------
  #  SELECT id FROM activity WHERE label ~* '^overall.+assessment$'

  my $pattern = '^overall.+assessment$';
  my $rs = shift->schema->resultset('Activity')
    -> search({label => {'~*', $pattern}});
  die "pattern not found: '$pattern'" if $rs->count < 1;
  die "multiple matches found for '$pattern'" if $rs->count > 1;

  $rs->next->id;
}


sub id_of_general {
  # return the tree node id for General Capabilities

  #  equivalent SQL:
  #  --------------
  #  SELECT id FROM "activity" WHERE label ~* 'general capabilities'

  my $pattern = '^general capabilities$';
  my $rs = shift->schema->resultset('Activity')
    -> search({label => {'~*', $pattern}});
  die "pattern not found: '$pattern'" if $rs->count < 1;
  die "multiple matches found for '$pattern'" if $rs->count > 1;

  $rs->next->id;
}


sub id_of_specific {
  # return the tree node id for General Capabilities

  #  equivalent SQL:
  #  --------------
  #  SELECT id FROM "activity" WHERE label ~* 'general capabilities'

  my $pattern = '^specific$';
  my $rs = shift->schema->resultset('Activity')->search({label => {'~*', $pattern}});
  die "pattern not found: '$pattern'" if $rs->count < 1;
  die "multiple matches found for '$pattern'" if $rs->count > 1;

  $rs->next->id;
}


sub nonleaf {
  # return a true value if this is a non-leaf node
  my ($self, $nodeID) = @_;
  my $rs = shift->schema->resultset('Activity')->search(
    {
      parent => $nodeID
    },
    {
      select => ['id']
    }
  );
  return $rs->cursor->next; # gets raw data for speed; will be 0 or 1 in scalar context
}


sub np_codes {
  # return a ordered list of the NP (non-participatory) codes
  my ($self) = @_;

  # equivalent SQL:
  # --------------
  # SELECT id FROM np_reason ORDER BY "order"

  my $rs = $self->schema->resultset('NpReason')
    -> search( undef, { columns => [ 'code' ], order_by => '"order"' } );

  my @list;
  foreach my $row ( $rs->all ) {
    push @list, $row->code;
  }

  return @list;
}

sub np_description_hash {
  # return a hash of descriptions corresponding to the NP (non-participatory) codes
  my ($self) = @_;

  # equivalent SQL:
  # --------------
  # SELECT "code", "text" FROM np_reason

  my $rs = $self->schema->resultset('NpReason')
    -> search( undef, { columns => [ 'code', 'text' ] } );

  my %hash;
  foreach my $row ( $rs->all ) {
    $hash{$row->code} = $row->text;
  }

  return %hash;
}

sub number_of_attached_pearls {
  # return the number of this user's pearls attached to the given node
  # (but not to its subordinate nodes)

  my ($self, $uid, $nodeID) = @_;
  my $rs = $self->schema->resultset('Note')->search({
    '"user"' => $uid,
    activity => $nodeID
  });

  return $rs->count;
}


sub number_of_contained_pearls {
  # return the number of this user's pearls contained in the given node
  # and all its subordinate nodes

  my ($self, $uid, $nodeID) = @_;
  my $rs = $self->schema->resultset('Activity')->search(
    { 'parent.id' => $nodeID },
    {
      alias => 'child',
      columns => ['child.id'],
      from => [
        { child => 'activity' },
        [
          { parent => 'activity', -join_type => 'inner'},
          { '(child.left_id BETWEEN parent.left_id AND parent.right_id)' => 'TRUE' }
        ]
      ],
    }
  )->search_related('notes', {'"user"' => $uid});
# )->search_related('notes');

  return $rs->count;
}


sub path_to_node {
  # return all ancestors of the given node as an ordererd list, starting with root
  my ($self, $nodeID) = @_;

  #  equivalent SQL:
  #  --------------
  #  SELECT parent.label
  #    FROM activity AS child, activity AS parent
  #   WHERE child.left_id BETWEEN parent.left_id AND parent.right_id
  #     AND child.id = $nodeID
  #   ORDER BY parent.left_id

  my $rs = $self->schema->resultset('Activity')->search(
    { 'child.id' => $nodeID },
    {
      alias => 'parent',
      columns => ['parent.label'],
      order_by => ['parent.left_id'],
      from => [
        { parent => 'activity' },
        [
          { child => 'activity', -join_type => 'inner'},
          { '(child.left_id BETWEEN parent.left_id AND parent.right_id)' => 'TRUE' }
        ]
      ],
    }
  );

  return $rs->get_column('parent.label')->all;
}


sub parent_of_node {
  # return the parent node for the node with the given id
  my ($self, $nodeID) = @_;

  # note the ambiguity of "parrent" in the following call:
  my $rs = $self->schema->resultset('Activity')->find($nodeID)->parent; # here "parent" is the parent in relationship,
                                                                        # not the value of the 'parent' column in selected row

  my %hash= $rs->get_columns;
  return \%hash;
}


sub pearls_attached_to_node {
  # return this user's pearls attached to the given node
  # (but not to its subordinate nodes)

  my ($self, $uid, $nodeID) = @_;
  my $rs = $self->schema->resultset('Note')->search(
    {
      '"user"' => $uid,
      activity => $nodeID
    },
    {
      select   => ['"user"', 'activity', 'path', 'text', [ '"when"::date' ], { extract => [\'EPOCH FROM "when"'] } ],
      as       => ['"user"', 'activity', 'path', 'text', 'date', 'ts'],
      order_by => ['"when" DESC'],
    },
  );
  return $rs->all;
}


sub pearls_by_path {
  # return this user's pearls attached to the node
  # determined by the given path, and to all its children

  my ($self, $uid, $path) = @_;

  # escape vertical bars and other regexp syntax so they are matched literally
  $path =~ s/([\|\(\)\[\]])/[\\$1]/g; # couldn't escape with backslashes, have to use sets

  #  equivalent SQL:
  #  --------------
  #  SELECT "path", "text", "when"::date
  #    FROM "note"
  #   WHERE "user" = '$uid'
  #     AND "path" ~* E'^$path'
  #   ORDER BY "when" DESC

  my $rs = $self->schema->resultset('Note')->search(
    {
      '"user"' => $uid,
      path => {'~*', "^$path"}
    },
    {
      select   => ['"user"', 'activity', 'path', 'text', [ '"when"::date' ], { extract => [\'EPOCH FROM "when"'] } ],
      as       => ['"user"', 'activity', 'path', 'text', 'date', 'ts'],
      order_by => ['"when" DESC'],
    },
  );
  return $rs->all;
}


sub rating_desc_hash {
  # return a hash of short grade descriptions indexed by their numeric value
  my ($self) = @_;

  # equivalent SQL:
  # --------------
  # SELECT "value", "desc" FROM rating

  my $rs = $self->schema->resultset('Rating')
    -> search( undef, { columns => [ 'value', 'desc', 'description' ] } );
    # we're lucky that DBIC turns 'desc' into 'me.desc', so no need to used double quotes

  my %hash;
  foreach my $row ( $rs->all ) {
    if ($row->description) {
      $hash{$row->value} = $row->desc . '; ' . $row->description;
    }
    else {
      $hash{$row->value} = $row->desc;
    }
  }

  return %hash;
}


sub rating_symbol_hash {
  # return a hash of grade symbols indexed by their numeric value
  my ($self) = @_;

  # equivalent SQL:
  # --------------
  # SELECT value, symbol FROM rating

  my $rs = $self->schema->resultset('Rating')
    -> search( undef, { columns => [ 'value', 'symbol' ] } );

  my %hash;
  foreach my $row ( $rs->all ) {
    $hash{$row->value} = $row->symbol;
  }

  return %hash;
}


sub range_of_ratings_for {
  # return an ordered list of ratings in the rage corresponding to
  # to the given subtree and role
  my ($self, %args) = @_;

  my $rs = $self->schema->resultset('RatingMap')->search(
    {
      subtree => $args{subtree},
      role => $args{role},
    },
    {
      alias => 'r',
      columns => ['r.value'],
      order_by => ['r.value'],
      from => [
        { r => 'rating' },
        [
          { m => 'rating_map', -join_type => 'inner'},
          { '(r.value >= m.low AND r.value <= m.high)' => 'TRUE' }
        ]
      ],
    }
  );
  my $cursor = $rs->cursor;
  my @list;
  while ( my ( $value ) = $cursor->next ) {
    push @list, $value;
  }
  return @list;
}


sub components_for {
  # return the ordered list of Ferguson components for a given subtree
  my ($self, %args) = @_;

  my $rs = $self->schema->resultset('FergusonComponent')->search(
    {
      procedure => $args{subtree}
    },
    {
      alias => 'r',
      select => ['r.seq', 'r.name', 'r.difficulty', 'r.tp', 'r.dp'],
      order_by => ['r.seq'],
    }
  );

  my @list;
  foreach my $row ($rs->all) {
    push @list, {$row->get_columns()};
  }
  return @list;
}


sub remarks_on_case {
  # return all remarks associated with the case
  my ($self, %args) = @_;
  my $date = delete $args{date} or die "expecting a date argument";
  my $case_no = delete $args{case_no} or die "expecting a case_no argument";
  my $activity = delete $args{activity} or die "expectiing activity => nodeID";
  my $trainee = delete $args{trainee} or die "expecting trainee => uid";
  die "extraneous arguments: (" . join(", ", keys %args) . ")" if %args;

  # equivalent SQL:
  # --------------
  # SELECT assessor, text
  #   FROM remark, "case"
  #  WHERE remark."case" = "case".id
  #    AND "date" = '$date'
  #    AND case_no = $case_no
  #    AND activity = $activity
  #    AND trainee = '$trainee'

  my $rs = $self->schema->resultset('Case')->search({
      '"date"' => $date,
      case_no => $case_no,
      activity => $activity,
      trainee => $trainee,
    },
    {
      join => 'remarks',
      +select => ['me.assessor', 'remarks.text'],
      +as => ['assessor', 'text'],
    }
  );

  return $rs->all;
}

sub trainees {
  my ($self) = @_;

  # equivalent SQL:
  # SELECT "user", count(*) as submissions, max("date") as last_active
  #   FROM role, "case"
  #  WHERE rolename = 'trainee'
  #    AND trainee = "user"
  #  GROUP BY "user"
  #  ORDER BY last_active;

  my $rs = $self->schema->resultset('Role') ->search(
    {
      rolename => 'trainee',
    },
    {
      join     => [ qw/ case_trainees time_logs absents / ],
      select   => [
        '"user" AS username',
        q(CASE WHEN absents.uid = "user" THEN true ELSE false END AS absent),
        { count => { distinct => 'case_trainees.id' }},
        q(max(CASE WHEN "date" IS NULL THEN '2000-1-1'::date ELSE "date" END) AS last_active),
        q(max(CASE WHEN "in" IS NULL THEN '2000-1-1'::date ELSE "in"::date END) AS last_logged),
      ],
      as       => [ qw/ username absent submissions last_active last_logged/ ],
      group_by => [ qw/ username absent / ],
      order_by => [ qw/ last_logged last_active / ],
    }
  );
  return $rs->all;
}


sub is_absent {
  my ($self, $uid) = @_;
  my $res = $self->schema->resultset('Absent')->find($uid);
  return $res;
}


sub mark_absent {
  my ($self, $uid) = @_;
  my $rs = $self->schema->resultset('Absent');
  $rs->update_or_create( { uid => $uid } );
}

sub unmark_absent {
  my ($self, $uid) = @_;
  my $rs = $self->schema->resultset('Absent');
  if ( my $row = $rs->find( $uid ) ) {
    $row->delete;
  }
}


sub system_date {
  use Time::localtime;

  my $tm = localtime;
  sprintf("%04d-%02d-%02d", $tm->year+1900, $tm->mon + 1, $tm->mday);
}

sub range_of_dates {
  my ($self, %constraint) = @_;

  # equivalent SQL:
  # SELECT min("date"), max("date") FROM "case" WHERE ...;

  my $rs = $self->schema->resultset('Case')->search(
    { %constraint },
    {
      'select'  => [
        { min => '"date"' },
        { max => '"date"' }
      ],
      'as'      => [ qw/earliest latest/ ]
    }
  )->single();

  if ($rs) {
    return {$rs->get_columns};
  }
  else {
    return {};
  }
}

sub range_of_academic_years {
  my ($self, %constraint) = @_;
  my $start = $self->config('year_start');

  # equivalent SQL (171 == year start):
  # SELECT
  #    CASE WHEN extract(DOY FROM MIN( "date" )::date) < '171'::integer THEN
  #      extract(YEAR FROM MIN( "date" )::date) - 1
  #    ELSE
  #      extract(YEAR FROM MIN( "date" )::date)
  #    END,
  #    CASE WHEN extract(DOY FROM MAX( "date" )::date) < '171'::integer THEN
  #      extract(YEAR FROM MAX( "date" )::date) - 1
  #    ELSE
  #      extract(YEAR FROM MAX( "date" )::date)
  #    END
  #    FROM "case"
  #    WHERE ( trainee = 'tbabrowski' AND "date" > '2008-6-19');


  my $rs = $self->schema->resultset('Case')->search(
    { %constraint },
    {
      'select'  => [
        \qq(
    CASE WHEN extract(DOY FROM MIN( "date" )::date) < '$start'::integer THEN
      extract(YEAR FROM MIN( "date" )::date) - 1
    ELSE
      extract(YEAR FROM MIN( "date" )::date)
    END),
        \qq(
    CASE WHEN extract(DOY FROM MAX( "date" )::date) < '$start'::integer THEN
      extract(YEAR FROM MAX( "date" )::date) - 1
    ELSE
      extract(YEAR FROM MAX( "date" )::date)
    END
)
      ],
      'as'      => [ qw/earliest latest/ ]
    }
  )->single();
  if ($rs) {
    return {$rs->get_columns};
  }
  else {
    return {};
  }
}

sub current_academic_year {
  my ($self) = @_;
  my $rs = $self->schema->resultset('CurrentAcademicYear')->search(
     undef,
     {
      bind => [$self->config('year_start') . ' days']
     }
  )->single();
  if ($rs) {
    return $rs->year;
  }
  else {
    return undef;
  }
}

sub first_academic_month {
  my ($self) = @_;
  my $rs = $self->schema->resultset('FirstAcademicMonth')->search(
     undef,
     {
      bind => [$self->config('year_start') . ' days']
     }
  )->single();
  if ($rs) {
    return $rs->month;
  }
  else {
    return undef;
  }
}

sub academic_months {
  my ($self, $year) = @_;
  my $next_year = $year;
  my $first = $self->first_academic_month;
  my $ts = localtime;
  my @list;
  foreach my $i (0 .. 12) {
    my $month = ($first + $i) % 12;
    my $next_month = ($first + $i + 1) % 12;
    if ($month == 0) {
      $month = 12;
    }
    if ($next_month == 0) {
      $next_month = 12;
    }
    if ($next_month == 1) {
      $next_year++;
    }
    if ($next_month == 2 and $next_year != $year) {
      $year = $next_year;
    }
    push @list, {
                 year => $year,
                 month => $month,
                 abbr => $monthAbbr[$month],
                 name => $monthName[$month],
                 start => "$year-$month-01",
                 end => "$next_year-$next_month-01"
                };

    last if sprintf("%4d-%02d", $next_year, $next_month) gt  sprintf("%4d-%02d", $ts->year + 1900, $ts->mon + 1);
  }
  return @list;
}

sub trainees_in_year {
  my ($self, $year) = @_;
  my $next_year = $year + 1;
  my $start = $self->config('year_start');

  # equivalent SQL (171 == year start):
  # SELECT DISTINCT "trainee"
  #   FROM "case"
  #  WHERE "date" >= '2006-1-1'::timestamptz + '171 days'
  #    AND "date" <  '2007-1-1'::timestamptz + '171 days';


  my $rs = $self->schema->resultset('Case')->search(
    { qq(("date" BETWEEN '$year-01-01'::timestamptz + '$start days' AND '$next_year-01-01'::timestamptz + '$start days')) => 'TRUE' },
    {
      'select'  => [ { distinct => 'trainee' } ],
      'as'  => [ 'id' ]  # Using 'trainee' here creates havoc. It gets interpreted as an object ref.
    }
  );

  my @list;
  foreach my $row ( $rs->all ) {
    push @list, $row->id;
  }
  return @list;
}

sub months_hit {
  my ($self) = @_;

  # equivalent SQL:
  # SELECT DISTINCT trainee,
  #       extract(YEAR FROM "date") AS year,
  #       extract(MONTH FROM "date") AS month
  #  FROM "case"

  my $rs = $self->schema->resultset('AssessedMonth');
  my $result;
  foreach my $row ($rs->all) {
    $result->{$row->trainee} = {} unless exists $result->{$row->trainee};
    $result->{$row->trainee}->{$row->year} = {} unless exists $result->{$row->trainee}->{$row->year};
    $result->{$row->trainee}->{$row->year}->{$row->month}++;
  }
  return $result;
}


# The following two routines were supposed to be used in Person.pm,
# but for some reason the model object is not accessible there, so
# they were cloned in place.
sub cache_directory_entry {
  my ($self, $entry) = @_;

  $entry->{ts} = scalar gmtime();
  my $rs = $self->schema->resultset('DirectoryCache')->update_or_create(
    $entry,
    {
     key => 'directory_cache_pkey'
    }
  );
  return $rs;
}

sub query_directory_cache {
  my ($self, $query) = @_;

  my $rs = $self->schema->resultset('DirectoryCache')->search($query);

  my @list;
  foreach my $row ($rs->all) {
    push @list, {$row->get_columns()};
  }
  return @list;
}

sub schema {
  return shift->{schema};
}


1;
