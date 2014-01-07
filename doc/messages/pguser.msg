
  Postgres did not allow this user to create a database. The solution
  to this problem is to either use another postgres user account, or
  to make sure that this user is allowed to create databases. One
  possible way of doing that is dropping this user account and
  re-creating it:

    $ [dropuser] <[username]>
    DROP ROLE
    $ [createuser] <[username]>
    Shall the new role be a superuser? (y/n) [n]
    Shall the new role be allowed to create databases? (y/n) [y]
    Shall the new role be allowed to create more new roles? (y/n) [n]
    CREATE ROLE

    See [man createuser] for more details.

