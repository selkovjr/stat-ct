package Person;

use strict;

sub new {
  my $class = shift;
  my %arg = @_;
  my @argnames = qw/uid cn sn givenName mail domain department dirtype password/;
  my $self = {};
  foreach my $key ( @argnames ) {
    $self->{$key} = delete $arg{$key};
  }
  die "unrecognised argument(s) in Person->new(): " . join(", ", keys(%arg)) if %arg;
  bless $self, $class;
  return $self;
}

sub uid { shift->{uid}; }
sub cn { shift->{cn}; }
sub sn { shift->{sn}; }
sub givenName { shift->{givenName}; }
sub mail { shift->{mail}; }
sub department { shift->{department}; }
sub domain { shift->{domain}; }
sub dirtype { shift->{dirtype}; }


sub map_uids {
  my ( $self, @set ) = @_;

  my @result;

  foreach my $uid ( @set ) {
    my @ent = $self->search_by_uid($uid);
    if ( @ent == 0 ) {
      push @result, Person->new(
				uid => $uid,
				cn => "Unknown [$uid]",
				sn => "[$uid]",
				givenName => 'Unknown',
			       );
    }
    elsif ( @ent == 1 ) {
      push @result, $ent[0];
    }
    else {
      # For now, just assume it's the same person. We will later enforce fully-qualified ids
      push @result, $ent[-1];
      next;
      die "multiple directory entries for '$uid' found in [" . join(", ", map {"@" . $_->{domain}} @ent) . "]";
    }
  }
  return @result;
}



sub list_all {
  my ( $self, %args ) = @_;

  my @result;
  my $n = 0;
  foreach my $d ( @STAT::directory ) {
    $n++;
    if ( defined $d->{dirtype} ) {
      next if $args{domain} and $args{domain} ne $d->{domain};

      if ( $d->{dirtype} eq 'LDAP' ) {
	foreach my $dirent ( Util::list_ldap_directory() ) {
	  next unless $dirent->{givenName};
	  push @result, new Person(%$dirent, domain => $d->{domain}, dirtype => $d->{dirtype});
	}
      }

      elsif ( $d->{dirtype} eq 'passwd' ) {
	die "method list_all() not implemented for directory type 'passwd'";
      }

      else {
	die "unknown directory type '$d->{dirtype}' in directory #$n in STAT.pm";
      }
    }
    else {
      die "directory type must be defined in directory #$n in STAT.pm";
    }
  }
  return @result;
}

sub search {
  # Search all directories for the best matching unique name;
  # return all matches if no unique match is possible;

  my ( $self, $name_or_id ) = @_;

  my @result;
  my $n = 0;
  foreach my $d ( @STAT::directory ) {
    $n++;
    if ( defined $d->{dirtype} ) {
      if ( $d->{dirtype} eq 'LDAP' ) {
	my $port = defined $STAT::ldap_port ? ":$STAT::ldap_port" : "";
	my $dir = ($STAT::ldap_ssl ? Net::LDAPS->new("$STAT::ldap_host$port") : Net::LDAP->new("$STAT::ldap_host$port")) or die "$@";
	$dir->bind;

	my @attr = qw(cn sn givenName uid mail);
	push @attr, $d->{department_attr} if $d->{department_attr};

	$name_or_id =~ s/\s+md\.?$//i; # a fix for cn = "Amer Zureikat Md."

	# count words in $name_or_id
	my @name = split /[ ,]+/, $name_or_id;

	# remove periods, for example, in 'm. posner'
	$name[0] =~ s/[^a-zA-Z]+$//;

	# if $name_or_id has a comma, the surname and the given names are reversed
	if ( $name_or_id =~ /,/ ) {
	  my $sn = shift @name;
	  push @name, $sn;
	}

	my $res;
	if ( @name > 1 ) {
	  # assume $name_or_id consists of first name and last name
	  $res = $dir->search ( base => $STAT::ldap_base,
				filter => "(\&(givenName=$name[0]*)(sn=*$name[-1]*))",
				attrs  => \@attr,
			      );
	  $res->code and die $res->error;

	  # if the above search didn't turn anything up, try cn=$name_or_id
	  if ( $res->count == 0 ) {
	    $res = $dir->search ( base => $STAT::ldap_base, filter => "(cn=$name_or_id)", attrs  => \@attr );
	    $res->code and die $res->error;
	  }
	}

	elsif ( @name == 1 ) {
	  # assume $name_or_id is a surname
	  $res = $dir->search ( base => $STAT::ldap_base, filter => "(sn=$name_or_id)", attrs  => \@attr );
	  die "sn: too many entries" if $res->code; # there can be other causes, but I haven't encountered any

	  # if it doesn't hit a surname, try first name
	  if ( $res->count == 0 ) {
	    $res = $dir->search ( base => $STAT::ldap_base, filter => "(givenName=$name_or_id)", attrs  => \@attr );
	    die "givenName: too many entrise" if $res->code;
	  }

	  # now try CnetID
	  if ( $res->count == 0 ) {
	    $res = $dir->search ( base => $STAT::ldap_base, filter => "(uid=$name_or_id)", attrs  => \@attr );
	    $res->code and die $res->error;
	  }
	}

	$dir->unbind;

	for ( my $index = 0; $index < $res->count; $index++) {
	  my $entry = $res->entry($index);
          next unless $entry->get_value('givenName');

	  my $uid = $entry->get_value('uid');
	  my $sn = $entry->get_value('sn');
	  my $cn = $entry->get_value('cn');
	  my $givenName = $entry->get_value('givenName');
	  my $mail = $entry->get_value('mail') || "mail:$uid";
	  my %dirent = (
		     uid => $uid,
		     sn => $sn,
		     cn => $cn,
		     givenName => $givenName,
		     mail => $mail,
		    );
	  $dirent{department} = $entry->get_value($d->{department_attr}) if $d->{department_attr};
	  push @result, new Person(%dirent, domain => $d->{domain}, dirtype => $d->{dirtype});
	}
      }

      elsif ( $d->{dirtype} eq 'passwd' ) {
	foreach my $dirent ( Util::search_unix_passwd_file($d->{file}, $name_or_id) ) {
	  push @result, new Person(%$dirent, domain => $d->{domain}, dirtype => $d->{dirtype});
	}
      }

      else {
	die "unknown directory type '$d->{dirtype}' in directory #$n in STAT.pm";
      }
    }
    else {
      die "directory type must be defined in directory #$n in STAT.pm";
    }
  }
  return @result;
}


sub search_by_uid {
  # Separate the user id from the domain, and use the latter to select the directory.
  # If the domain part is not supplied, return all matching directory entries

  my ( $self, $fqn ) = @_;
  my ( $uid, $domain ) = split('@', $fqn);

  my @result;

  my $rs = $STAT::Schema->resultset('DirectoryCache')->search({uid => $uid});
  if ($rs->count) {
    foreach my $row ($rs->all) {
      push @result, bless {$row->get_columns} => 'Person';
    }
    return @result;
  }

  my $n = 0;
  foreach my $d ( @STAT::directory ) {
    $n++;
    if ( defined $d->{dirtype} ) {
      next if $domain and $domain ne $d->{domain};

      if ( $d->{dirtype} eq 'LDAP' ) {
	my $dept_attr = exists $d->{department_attr} ? $d->{department_attr} : undef;
	if ( my $dirent = Util::ldap_entry($uid, $dept_attr) ) {
	  next unless $dirent->{givenName};
	  push @result, new Person(%$dirent, domain => $d->{domain}, dirtype => $d->{dirtype});
	}
      }

      elsif ( $d->{dirtype} eq 'passwd' ) {
	if ( my $dirent = Util::unix_passwd_entry($d->{file}, $uid) ) {
	  push @result, new Person(%$dirent, domain => $d->{domain}, dirtype => $d->{dirtype});
	}
      }

      else {
	die "unknown directory type '$d->{dirtype}' in directory #$n in STAT.pm";
      }
    }
    else {
      die "directory type must be defined in directory #$n in STAT.pm";
    }
  }

  # Cache the results
  foreach my $person (@result) {
    my $entry;
    foreach my $key (qw/uid cn sn mail department domain dirtype password/) {
      $entry->{$key} = $person->{$key};
    }
    $entry->{givenname} = $person->{givenName};
    $entry->{ts} = scalar gmtime();
    my $rs = $STAT::Schema->resultset('DirectoryCache')->update_or_create(
      $entry,
      {
        key => 'directory_cache_pkey'
      }
    );
  }

  return @result;
}

sub set_schema {
  my ($self, $schema) = @_;
  die "not a schema handle: $schema" unless ref($schema) eq "STAT::Schema";
  $self->{schema} = $schema;
}

sub role {
  my $self = shift;

  if ( $STAT::application =~ /^hipec/i ) {
    # equivalent SQL:
    # --------------
    # SELECT rolename
    #   FROM role
    #  WHERE "user" = '$uid'
    #    AND "when" = (
    #        SELECT max("when") FROM role WHERE "user" = '$uid'
    #    );
    die "not implemented";
  }
  else {
    # equivalent SQL:
    # --------------
    # SELECT rolename
    #   FROM role
    #  WHERE "user" = '$uid
    my $rs = $self->{schema}->resultset('Role')->find($self->uid);
    if ( $rs ) {
      return $rs->rolename;
    }
  }
  return undef;
}

sub role_of_teammate {
  my $self = shift;
  my $role = $self->role();
  return 'attending' if $role eq 'trainee';
  return 'trainee' if $role eq 'attending';
  return undef;
}

sub can_see_all_results {
  my $self = shift;
  my $rs = $self->{schema}->resultset('Role')->find($self->uid);
  if ( $rs ) {
    return $rs->can_see_results;
  }
  return undef;
}

sub can_see_overview {
  my $self = shift;
  my $rs = $self->{schema}->resultset('Role')->find($self->uid);
  if ( $rs ) {
    return $rs->can_see_overview;
  }
  return undef;
}

1;
