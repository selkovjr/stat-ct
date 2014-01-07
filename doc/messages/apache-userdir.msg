
Make sure (or check with your system administrator) that your server's
http.conf has these settings:

  1. Apache module [mod_userdir.c] is enabled
  2. The <Directory> section of [http.conf] pertaiting to [UserDir]
     allows access to everyone

Also check that all directories in the path leading from ~/public_html
to this directory have the access mode required by your server's
access policy (normally, it should be [755]).

