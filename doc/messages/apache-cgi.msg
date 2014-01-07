
Make sure (or check with your system administrator) that your server's
http.conf has these settings:

  1. Apache module [mod_cgi.c] is enabled
  2. In <Directory /home/*/public_html/>, or in whatever directory
     designated as your public html directory, at least the
     following four overrides are allowed:

       AllowOverride [AuthConfig Indexes Options AddHandler]

     The same overrides must be allowed in all instances of .htaccess
     present in the ancestral web directories, up to and including
     ~/public_html

Also check that all directories in the path leading from ~/public_html
to this directory have the access mode required by your server's
access policy (normally, it should be [755]).

Finally, check the varible CGI_MODE in this Makefile and re-run make
if you change it. It is well to set it to [700] if your server runs with
[suexec]; otherwise, it may be necessary to set it to [755].

