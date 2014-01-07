
Make sure (or check with your system administrator) that your server's
http.conf has these settings:

  1. Apache module [mod_auth_ldap.c] is enabled
  2. The <Directory> section of [http.conf] pertaining to [UserDir]
     allows access to everyone and allows the following overrides:

       AllowOverride [AuthConfig] Indexes Options

     The same overrides must be allowed in all instances of .htaccess
     present in the ancestral web directories, up to and including
     [UserDir]. (Note: by convention, [UserDir] is set to [~/public_html])

The probable cause for this failure is that the [AuthConfig] override is
not allowed, so the server is not letting us use the [AuhtLDAP.*]
directives in our [.htaccess] file.

