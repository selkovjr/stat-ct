
Due to the considerable complexity of HTML::Mason, it is hard to
pinpoint a single reason for its failure.

If any problems arise, check the server logs ([access_log],
[error_log] and [suexec.log]) and verify the settings in these four
configuration files:

  [.htaccess]
  [mason_handler.cgi]
  [syshandler]
  [autohandler]

For a detailed explanation of how to run Mason in a CGI environment,
refer to this document:

  http://www.masonhq.com/docs/manual/CGIHandler.html

The goal of this setup procedure is to create a CGI environment for
Mason inside a user's public_html directory. The most obvious
requirements for such an environment include:

  1. The web server must be configured to run CGI scripts in the
     user's web directory.

  2. The .cgi suffix must be recognized by the server; otherwise,
     the URI of the mason handler must be specified in [.htaccess],
     as in:

     <FilesMatch "(\.html|\.css)$">
       Action html-mason /~userid/stat/[mason_handler.cgi]
       AddHandler html-mason .css
       AddHandler html-mason .html
     </FilesMatch>

     and this handler script must be recognized as a CGI by the server.

  3. The Mason handler script ([mason_handler.cgi] in the above
     example) must be granted write permissions within the Mason cache
     directory, which is defined in the [data_dir] parameter to
     CGIHandler's constructor:

     my $h = HTML::Mason::CGIHandler->new(
       [data_dir] => '/home/username/public_html/stat/var',
       [comp_root] => '/home/username/public_html/stat',
     );`

  4. Also note that the absolute path to the component root for this
     site must be supplied in the [comp_root] argument to CGIHandler.

  5. At least in a couple instances (tested with Mason vv. 1.28 and
     1.3101), the CGI environment had to be cleaned up in order to
     avoid the following error:

        could not find component for initial path '/~userid/stat/index.html'

     The solution is to remove all references to the user's home
     directory from [PATH_INFO] before calling CGIHandler->new()

     $ENV{PATH_INFO} =~ s{~userid/stat/}{};

  6. Each Mason application must have its own [data_dir]. Configuring
     more than one site (as defined by [comp_root]) to use the same
     cache directory may result in wrong pages being sent to the wrong
     clients.


