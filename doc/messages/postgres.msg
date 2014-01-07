
The possible reasons for failure to connect to postmaster include:

  1. Postmaster is not running on the specified host (check the
     [PG_HOST] variable in this Makefile).
  2. Postmaster is not listening to the specified port ([PG_PORT])
  3. If [PG_HOST] is not local, postmaster may not be listening to an
     intertet socket (by default, it opens a unix socket). It needs
     [-i] in its command line to create an internet socket. 
     Additionally, check that the file [pg_hba.conf] exists and has a
     rule allowing connections from the the client machine.
  4. The user name specified in [PG_USER] variable in this Makefile
     is not recognized by postgres. Make sure that the user exsits
     in postgres, or read

       [man createuser]

     for instructions on how to add a new user account to postgres.

In all cases, read the above error message, check the server
configuration and use the following command on [PG_HOST} to see whether
the postmaster process is running and has been started with the right
options:

  ps -wfC postmaster

The following are examples of the correct postmaster command line and
host access rule necessary to accept internet connections:

  /usr/bin/postmaster [-i] -p 5432 -D /var/lib/pgsql/data

pg_hba.conf:
  [host]    all         all         0.0.0.0         0.0.0.0   trust

This example rule allows connections from all machines on the
internet. For detailed explanation of client authentication, follow
this link:

  http://www.postgresql.org/docs/8.2/interactive/client-authentication.html

