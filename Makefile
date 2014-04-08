# This Makefile is for the new STAT server at stat.uchicago.edu


# configuration variables ----------------------------------
INSTITUTION = The University of Chicago
DOMAIN = uchicago.edu
MACHINE = `hostname`
ROOT_CA = "JCS Lab Root CA"
CONTACT = main_contact\@email.com
ALERT_BCC = "$(CONTACT),other@email.net"
#LDAP_SSL = yes
LDAP_PORT = 389
LDAP_VERS = ldap
LDAP_HOST = `hostname`
LDAP_BASE = o=ct,dc=uchicago-stat,dc=org
LDAP_TEST_UID = mferguso
LDAP_TEST_EXPECT = Mark
#MAIL_RELAY = smtp.uchicago.edu
MAIL_RELAY = localhost
PG_HOST = localhost
PG_PORT = 5432
PG_USER = $(USER)
APPLICATION = ct
DATABASE = stat-$(APPLICATION)
TESTDB = stat-test
HTTP_PORT = 443
HTTP_VERS = https

# user mode (with suexec) should be 700, server mode is 755
CGI_MODE = 755
HTML_MODE = 644

DOCROOT = /home/stat/web/ssl

# THIS_DIR has our web path relative to document root
THIS_DIR := `echo $(PWD) | sed 's%^$(DOCROOT)/%%'`

BASE_URL := $(HTTP_VERS)://`hostname`:$(HTTP_PORT)

STAT_URL := $(BASE_URL)/$(THIS_DIR)

WGET_URL := $(HTTP_VERS)://`hostname`:$(HTTP_PORT)/$(THIS_DIR)

export PATH := $(PATH):/usr/sbin:/sbin:./bin

# can't use `which perl` because that would result in nested backticks later on
PERL_PATH := /usr/bin/perl

# end of configuration -------------------------------------

DOC = sed 's/\[\([^\[]*\)\]/\d27[1m\1\d27[22m/g' <

all: deps message

message:
	@echo "Installation is complete. Please direct your browser to [$(STAT_URL)]" | sed 's/\[\([^\[]*\)\]/\d27[1m\1\d27[22m/g'
	@echo "Refer to instructions in README on how to use the site"

deps: tools ldap apache postgres modules test install

tools: perl wget gnuplot bargraph gs imagemagick transfig psql

perl: perl.dep
perl.dep:
	@if [ -x "$(PERL_PATH)" ]; then echo "found perl"; else rm -f perl.dep && echo "Please install the current version of perl."; false; fi
	@if [ `$(PERL_PATH) -e 'print $$] > 5.006'` -eq 1 ]; then touch perl.dep && echo "perl verison OK"; else rm -f perl.dep && echo "You have an obsolete version of perl. Please update to current (> 5.6)"; false; fi

wget: wget.dep
wget.dep:
	@if [ -x "`which wget`" ]; then touch wget.dep && echo "found wget"; else rm -f wget.dep && echo "please install wget -- I need it for testing"; false; fi

gs: gs.dep
gs.dep:
	@if [ -x "`which gs`" ]; then touch gs.dep && echo "found gs"; else rm -f gs.dep && echo "please install ghostscript and make sure magick's convert can use it as delegate"; false; fi

gnuplot: gnuplot.dep
gnuplot.dep:
	@if [ -x "`which gnuplot`" ]; then touch gnuplot.dep && echo "found gnuplot"; else rm -f gnuplot.dep && echo "please install gnuplot"; false; fi

bargraph: bargraph.dep
bargraph.dep:
	@if [ -x "`which bargraph`" ]; then if ( grep Bruening `which bargraph` ) >& /dev/null; then touch bargraph.dep && echo "found bargraph"; else rm -f bargraph.dep && echo "'bargraph' found in your PATH is not the bargraph tool by Derek Bruening from http://www.burningcutlery.com/derek/bargraph/bargraph.pl"; false; fi; else echo "installing install bargraph from http://www.burningcutlery.com/derek/bargraph/bargraph.pl" && wget -O bin/bargraph http://www.burningcutlery.com/derek/bargraph/bargraph.pl && chmod $(CGI_MODE) bin/bargraph && touch bargraph.dep; fi

imagemagick: imagemagick.dep
imagemagick.dep:
	@if [ ! -x "`which convert`" ]; then rm -f imagemagick.dep && echo "please install imagemagick"; false; fi
	@if ( convert -version | grep -w ImageMagick ) >& /dev/null; then touch imagemagick.dep && echo "found imagemagick"; else rm -f imagemagick.dep && echo "please install imagemagick"; false; fi

transfig: transfig.dep
transfig.dep:
	@if [ -x "`which fig2dev`" ]; then touch transfig.dep && echo "found transfig"; else rm -f transfig.dep && echo "please install transfig"; false; fi

psql: psql.dep
psql.dep:
	@if [ -x "`which psql`" ]; then echo "found psql"; touch psql.dep; else rm -f psql.dep && echo "Please install the current version of postgres (server and clients)."; false; fi


ldap: ldapsearch ldap-test

apache: check_server check_index check_cgi

check_server: check_server.dep
check_server.dep:
	@if (netstat -tan | grep -w LISTEN | grep -w $(HTTP_PORT)) >& /dev/null; then touch check_server.dep && echo "HTTP serrver is listening at port $(HTTP_PORT)"; else rm -f check_server.dep && echo "Couldn't find HTTP server at port $(HTTP_PORT). Make sure it is running or change the HTPP_PORT variable near the top of this Makefile" && false; fi


check_index: check_index.dep
check_index.dep: wget.dep
	@echo "test-a-test" > test.html
	@echo "DirectoryIndex test.html" > .htaccess
	@chmod $(HTML_MODE) test.html
	@echo -ne "Testing DirectoryIndex at $(STAT_URL)/ ... "
	@if ( wget --no-check-certificate -qO- /dev/null $(WGET_URL)/ | grep test-a-test ) >& /dev/null; then touch check_index.dep && echo "OK"; else rm -f check_index.dep && echo "Failed." && $(DOC) doc/messages/apache-dirindex.msg && false; fi

check_cgi: check_cgi.dep
check_cgi.dep: wget.dep
	@echo "#!`which sh`" > test.cgi
	@echo "echo \"Content-type: text/plain\"" >> test.cgi
	@echo "echo \"\"" >> test.cgi
	@echo "echo \"test-a-test\"" >> test.cgi
	@chmod $(CGI_MODE) test.cgi
	@echo "Options ExecCGI FollowSymLinks" > .htaccess
	@echo "AddHandler cgi-script .cgi" >> .htaccess
	@echo -ne "Testing ExecCGI with $(WGET_URL)/test.cgi ... "
	@if ( wget --no-check-certificate -qO- /dev/null $(WGET_URL)/test.cgi | grep test-a-test ) >& /dev/null; then touch check_cgi.dep && echo "OK"; else rm -f check_cgi.dep && echo "Failed." && $(DOC) doc/messages/apache-cgi.msg && false; fi

ldapsearch: ldapsearch.dep
ldapsearch.dep:
	@if [ -x "`which ldapsearch`" ]; then touch ldapsearch.dep && echo "found ldapsearch"; else echo "please install openldap-clients -- I need ldapsearch for testing"; false; fi

ldap-test: ldap-test.dep
ldap-test.dep:
	@echo -ne "testing ldap ... "
#	if (ldapsearch -H $(LDAP_VERS)://$(LDAP_HOST):$(LDAP_PORT) -x -b $(LDAP_BASE) uid=$(LDAP_TEST_UID) | grep $(LDAP_TEST_EXPECT)) >& /dev/null; then touch ldap-test.dep && echo "OK"; else rm -f ldap-test.dep && echo "Failed. $!" && false; fi
#	 for some reason, ldaps does not work in this environment (on stat.uchicago.edu)
	@if (ldapsearch -H ldap://$(LDAP_HOST) -x -b $(LDAP_BASE) uid=$(LDAP_TEST_UID) | grep $(LDAP_TEST_EXPECT)) >& /dev/null; then touch ldap-test.dep && echo "OK"; else rm -f ldap-test.dep && echo "Failed. $!" && false; fi

postgres: check_connection check_pguser

check_connection: check_connection.dep
check_connection.dep:
	@echo -ne "Testing postgres connection at $(PG_HOST):$(PG_PORT); connecting as user '$(PG_USER)' ... "
	@if (psql -U $(PG_USER) -h $(PG_HOST) -p $(PG_PORT) -c "\\copyright" template1) > /dev/null; then echo "OK"; touch check_connection.dep; else rm -f check_connection.dep && echo "Failed." && $(DOC) doc/messages/postgres.msg && false; fi

check_pguser: check_pguser.dep
check_pguser.dep:
	@echo -ne "Testing postgres user rights for '$(PG_USER)' ... "
	@if (createdb -U $(PG_USER) -h $(PG_HOST) -p $(PG_PORT) test-a-test && dropdb -U $(PG_USER) -h $(PG_HOST) -p $(PG_PORT) test-a-test) > /dev/null; then echo "OK"; touch check_pguser.dep; else rm -f check_pguser.dep && echo "Failed." && $(DOC) doc/messages/pguser.msg && false; fi

modules: masonx mason dbi dbd uri net_ldap socket_ssl sub_recursive ipc_run3 text_diff text_diff_html

masonx: masonx.dep
masonx.dep:
	@if [ x`$(PERL_PATH) -MMasonX::Profiler -e 'print $$MasonX::Profiler::VERSION >= 0.06'` = x1 ]; then echo "found MasonX::Profiler"; touch masonx.dep; else echo "perl module MasonX::Profiler is missing or obsolete" && rm -f masonx.dep && false; fi

mason: mason.dep
mason.dep:
	@if [ x`$(PERL_PATH) -MHTML::Mason -e 'print $$HTML::Mason::VERSION >= 1.28'` = x1 ]; then echo "found HTML::Mason"; touch mason.dep; else echo "perl module HTML::Mason is missing or obsolete" && rm -f mason.dep && false; fi

dbi: dbi.dep
dbi.dep:
	@if [ x`$(PERL_PATH) -MDBI -e 'print $$DBI::VERSION >= 1.43'` = x1 ]; then echo "found DBI"; touch dbi.dep; else echo "perl module DBI is missing or obsolete" && rm -f dbi.dep && false; fi

dbd: dbd.dep
dbd.dep:
	@if [ x`$(PERL_PATH) -MDBD::Pg -e 'print $$DBD::Pg::VERSION >= 1.32'` = x1 ]; then echo "found DBD::Pg"; touch dbd.dep; else echo "perl module DBD::Pg is missing or obsolete" && rm -f dbd.dep && false; fi

uri: uri.dep
uri.dep:
	@if [ x`$(PERL_PATH) -MURI -e 'print $$URI::VERSION >= 1.35'` = x1 ]; then echo "found URI"; touch uri.dep; else echo "perl module URI is missing or obsolete" && rm -f uri.dep && false; fi

net_ldap: net_ldap.dep
net_ldap.dep:
	@if [ x`$(PERL_PATH) -MNet::LDAP -e 'print $$Net::LDAP::VERSION >= 0.33'` = x1 ]; then echo "found Net::LDAP"; touch net_ldap.dep; else echo "perl module Net::LDAP is missing or obsolete" && rm -f net_ldap.dep && false; fi

socket_ssl: socket_ssl.dep
socket_ssl.dep:
	@if [ x`$(PERL_PATH) -MIO::Socket::SSL -e 'print $$IO::Socket::SSL::VERSION >= 0.97'` = x1 ]; then echo "found IO::Socket_SSL"; touch socket_ssl.dep; else echo "perl module IO::Socket::SSL is missing or obsolete" && rm -f socket_ssl.dep && false; fi

sub_recursive: sub_recursive.dep
sub_recursive.dep:
	@if [ x`$(PERL_PATH) -MSub::Recursive -e 'print $$Sub::Recursive::VERSION >= 0.03'` = x1 ]; then echo "found Sub::Recursive"; touch sub_recursive.dep; else echo "perl module Sub::Recursive is missing or obsolete" && rm -f sub_recursive.dep && false; fi

ipc_run3: ipc_run3.dep
ipc_run3.dep:
	@if [ x`$(PERL_PATH) -MIPC::Run3 -e 'print $$IPC::Run3::VERSION >= 0.034'` = x1 ]; then echo "found IPC::Run3"; touch ipc_run3.dep; else echo "perl module IPC::Run3 is missing or obsolete" && rm -f ipc_run3.dep && false; fi

text_diff: text_diff.dep
text_diff.dep:
	@if [ x`$(PERL_PATH) -MText::Diff -e 'print $$Text::Diff::VERSION >= 0.034'` = x1 ]; then echo "found Text::Diff"; touch text_diff.dep; else echo "perl module Text::Diff is missing or obsolete" && rm -f text_diff.dep && false; fi

text_diff_html: text_diff_html.dep
text_diff_html.dep:
	@if [ x`$(PERL_PATH) -MText::Diff::HTML -e 'print $$Text::Diff::HTML::VERSION >= 0.034'` = x1 ]; then echo "found Text::Diff::HTML"; touch text_diff_html.dep; else echo "perl module Text::Diff::HTML is missing or obsolete" && rm -f text_diff_html.dep && false; fi


test: test_mason test_pg

test_mason: test_mason.dep
test_mason.dep:
	@echo "DirectoryIndex index.html" > .htaccess
	@echo "Options ExecCGI FollowSymLinks" >> .htaccess
	@echo "AddHandler cgi-script .cgi" >> .htaccess
	@echo "<FilesMatch \"(\\.html|\\.css)$$\">" >> .htaccess
	@echo "  Action html-mason $(STAT_URL)/mason_handler.cgi" >> .htaccess
	@echo "  AddHandler html-mason .css" >> .htaccess
	@echo "  AddHandler html-mason .html" >> .htaccess
	@echo "</FilesMatch>" >> .htaccess
	@echo "<FilesMatch \"(autohandler|dhandler|\.mason)$$\">" >> .htaccess
	@echo "  Order allow,deny" >> .htaccess
	@echo "  Deny from all" >> .htaccess
	@echo "</FilesMatch>" >> .htaccess
	@echo -ne "Testing HTML::Mason at $(STAT_URL)/ ... "
	@sudo rm -rf var/mason && mkdir var/mason && chmod 777 var/mason
	@echo "s%PERL_PATH%$(PERL_PATH)%" > mason_handler.sed
	@echo "s%DOCROOT%$(DOCROOT)/%g" >> mason_handler.sed
	@echo "s%THIS_DIR%$(DOCROOT)/$(THIS_DIR)%g" >> mason_handler.sed
	@echo "s%STAT_URL%$(STAT_URL)/%g" >> mason_handler.sed
	@echo "s%STAT_DIR%$(PWD)%g" >> mason_handler.sed
	@echo "s% *\# (!).*%%g" >> mason_handler.sed
	@cat config/template/mason_handler-root.cgi | sed -f mason_handler.sed > mason_handler.cgi
	@rm mason_handler.sed
	@chmod $(CGI_MODE) mason_handler.cgi
	@echo "<%init>" > syshandler
	@echo "  our \$$User = 'nobody';" >> syshandler
	@echo "  \$$m->call_next( %ARGS );" >> syshandler
	@echo "</%init>" >> syshandler
	@echo "<%flags>" >> syshandler
	@echo "  inherit => undef" >> syshandler
	@echo "</%flags>" >> syshandler
	@echo -ne "test:" > autohandler
	@echo "<% \$$m->call_next %>" >> autohandler
	@echo "<%flags>" >> autohandler
	@echo "  inherit => 'syshandler'" >> autohandler
	@echo "</%flags>" >> autohandler
	@echo "<% \$$User %>" > index.html
	@if ( wget --no-check-certificate -qO- /dev/null $(WGET_URL) | grep test:nobody ) >& /dev/null; then touch test_mason.dep && echo "OK"; else rm -f test_mason.dep && echo "Failed." && $(DOC) doc/messages/mason-general.msg && false; fi


test_pg: test_pg.dep
test_pg.dep:
	@echo -ne "Testing DBI connection to demo database ... "
	@if (dropdb -U $(PG_USER) -h $(PG_HOST) -p $(PG_PORT) $(TESTDB)) >& /dev/null; then echo -ne "dropping ... "; else if (dropdb -U $(PG_USER) -h $(PG_HOST) -p $(PG_PORT) $(TESTDB) 2>&1 | grep "does not exist") >& /dev/null; then echo -ne "no need to drop ... "; else echo "Can't connect" && rm -f test_pg.dep && false; fi; fi
	@echo -ne "creating ... "
	@createdb -U $(PG_USER) -h $(PG_HOST) -p $(PG_PORT) $(TESTDB) >& /dev/null
	@echo -ne "loading ... "
	@cat src/data/demo.dump | sed 's/PG_USER/$(PG_USER)/g' | psql -U $(PG_USER) -h $(PG_HOST) -p $(PG_PORT) $(TESTDB) >& /dev/null
	@echo -ne "updating ... "
	@cat src/tools/shift_date.sql | psql -U $(PG_USER) -h $(PG_HOST) -p $(PG_PORT) $(TESTDB) >& /dev/null
	@echo -ne "connecting ... "
	@if ( $(PERL_PATH) -MDBI -e '$$d=DBI->connect("dbi:Pg:dbname=$(TESTDB)",$(PG_USER),""); ($$id) = $$d->selectrow_array(q(SELECT label FROM activity WHERE id = 0)); print "$$id\n"' | grep root ) >& /dev/null; then touch test_pg.dep && echo "OK"; else rm -f test_pg.dep && echo "Failed." && false; fi


install:
	@echo "Installing code:"

	@echo "  config/STAT.pm"
	@echo "package STAT;" > config/STAT.pm
	@echo "\$$STAT::Session = undef;" >> config/STAT.pm
	@echo "\$$STAT::institution = '$(INSTITUTION)';" >> config/STAT.pm
	@echo "\$$STAT::domain = '$(DOMAIN)';" >> config/STAT.pm
	@echo "\$$STAT::machine = '$(MACHINE)';" >> config/STAT.pm
	@echo "\$$STAT::root_ca = '$(ROOT_CA)';" >> config/STAT.pm
	@echo "\$$STAT::contact = qq($(CONTACT));" >> config/STAT.pm
	@echo "\$$STAT::alert_bcc = '$(ALERT_BCC)';" >> config/STAT.pm
	@echo "\$$STAT::application = '$(APPLICATION)';" >> config/STAT.pm
	@echo "\$$STAT::bin = '$(PWD)/bin';" >> config/STAT.pm
	@echo "\$$STAT::tree_archive = '$(PWD)/src/data/tree_archive';" >> config/STAT.pm
	@echo "\$$STAT::pg_host = '$(PG_HOST)';" >> config/STAT.pm
	@echo "\$$STAT::pg_port = $(PG_PORT);" >> config/STAT.pm
	@echo "\$$STAT::pg_user = '$(PG_USER)';" >> config/STAT.pm
	@echo "\$$STAT::stat_db = '$(DATABASE)';" >> config/STAT.pm
	@echo "\$$STAT::mail_relay = '$(MAIL_RELAY)';" >> config/STAT.pm
	@echo "\$$STAT::ldap_host = '$(LDAP_HOST)';" >> config/STAT.pm
	@if [ -n "$(LDAP_PORT)" ]; then echo "\$$STAT::ldap_port = $(LDAP_PORT);" >> config/STAT.pm; fi
	@echo "\$$STAT::ldap_base = '$(LDAP_BASE)';" >> config/STAT.pm
	@if [ -n "$(LDAP_SSL)" ]; then echo "\$$STAT::ldap_ssl = 'yes';" >> config/STAT.pm; else echo "\$$STAT::ldap_ssl = undef;" >> config/STAT.pm; fi
	@echo "" >> config/STAT.pm
	@echo "@STAT::directory = (" >> config/STAT.pm
	@echo "  {" >> config/STAT.pm
	@echo "    dirtype => 'LDAP'," >> config/STAT.pm
	@echo "    host => '$(LDAP_HOST)'," >> config/STAT.pm
	@echo "    domain => '$(DOMAIN)'," >> config/STAT.pm
	@if [ -n "$(LDAP_PORT)" ]; then echo "    port => $(LDAP_PORT)," >> config/STAT.pm; fi
	@echo "    base => '$(LDAP_BASE)'," >> config/STAT.pm
	@if [ -n "$(LDAP_SSL)" ]; then echo "    ssl => 'yes'," >> config/STAT.pm; fi
	@echo "    department_attr => 'ucDepartment', " >> config/STAT.pm
	@echo "  }," >> config/STAT.pm
	@echo "  {" >> config/STAT.pm
	@echo "    dirtype => 'passwd'," >> config/STAT.pm
	@echo "    file => 'config/passwd'," >> config/STAT.pm
	@echo "    domain => '$(MACHINE)'," >> config/STAT.pm
	@echo "  }," >> config/STAT.pm
	@echo ");" >> config/STAT.pm
	@echo "" >> config/STAT.pm
	@echo "\$$STAT::path_to_convert = '`which convert`';" >> config/STAT.pm
	@echo "\$$STAT::path_to_fig2dev = '`which fig2dev`';" >> config/STAT.pm
	@echo "\$$STAT::path_to_gnuplot43 = '/opt/bin/gnuplot';" >> config/STAT.pm
	@echo "\$$STAT::path_to_gnuplot40 = '/opt-vintage/bin/gnuplot';" >> config/STAT.pm
	@echo "\$$STAT::gnuplot_version = '`gnuplot -V`';" >> config/STAT.pm
	@echo "1;" >> config/STAT.pm

	@echo "  .htaccess"
	@echo "s%STAT_URL%$(STAT_URL)%g" > htaccess.sed
	@echo "s%HTTP_PORT%$(HTTP_PORT)%g" >> htaccess.sed
	@echo "s%MACHINE%$(MACHINE)%g" >> htaccess.sed
	@echo "s%THIS_DIR%$(DOCROOT)/$(THIS_DIR)%g" >> htaccess.sed
	@if [ "$(HTTP_VERS)" = "https" ]; then cat config/template/httpd-ssl.conf | sed -f htaccess.sed > .htaccess; else cat config/template/httpd.conf | sed -f htaccess.sed > .htaccess; fi
	@rm htaccess.sed
	@chmod $(HTML_MODE) .htaccess

	@echo "  mason_handler.cgi"
	@echo "s%PERL_PATH%$(PERL_PATH)%" > mason_handler.sed
	@echo "s%DOCROOT%$(DOCROOT)/%g" >> mason_handler.sed
	@echo "s%THIS_DIR%$(DOCROOT)/$(THIS_DIR)%g" >> mason_handler.sed
	@echo "s%STAT_URL%$(STAT_URL)/%g" >> mason_handler.sed
	@echo "s%STAT_DIR%$(PWD)%g" >> mason_handler.sed
	@echo "s% *\# (!).*%%g" >> mason_handler.sed
	@cat config/template/mason_handler-root.cgi | sed -f mason_handler.sed > mason_handler.cgi
	@rm mason_handler.sed
	@chmod $(CGI_MODE) mason_handler.cgi

	@echo "  syshandler"
	@cp src/interface/syshandler .

	@echo "  autohandler"
	@cp src/interface/autohandler .

	@echo "  stat.css"
	@cp src/interface/stat.css .

	@echo "  csshover.htc"
	@cp src/interface/csshover.htc .

	@echo "  html files"
	@rm -f *.html
	@cp src/interface/*.html .

	@echo "  components"
	@rm -rf lib
	@cp -r src/interface/lib .

	@echo "  report.cgi"
	@cp src/interface/report.cgi .

	@echo "  favicon.ico"
	@mv lib/icons/favicon.ico $(DOCROOT)

	@echo -ne "  cleaning up var/mason ... "
	@sudo rm -rf var/mason && mkdir var/mason && chmod 777 var/mason
	@echo "OK"

favicon:
	@cp src/interface/lib/icons/favicon.ico ..

clean:
	sudo rm -rf config/STAT.pm var/mason .htaccess syshandler autohandler lib *.dep *.sed *.html *.cgi *.css
	find . -name "*[~#]" -exec rm {} \;
	find . -name "\.\#*" -exec rm {} \;

tidy:
	rm *.dep
