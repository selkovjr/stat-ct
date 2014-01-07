all: stat-meta.html stat-meta.png stat-meta.sql

stat-meta.html: stat-schema.dot
	echo "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">" > stat-schema.html
	echo "<head><title>Graphical database schema</title></head>" >> stat-schema.html
	echo "<body><div>" >> stat-schema.html
	echo "<img src=\"stat-meta.png\" usemap=\"test\#test\" alt=\"graphical database schema\">" >> stat-schema.html
	./fix_labels stat-schema.dot | dot -Tcmapx | perl -npe 's/ \/>/>/' >> stat-schema.html
	echo "</div></body>" >> stat-schema.html

stat-meta.png: stat-schema.dot 
	./fix_labels stat-schema.dot | dot -Tpng > stat-meta.png

stat-schema.dot: stat-meta.sgml parse_sgml
	nsgmls stat-meta.sgml | ./parse_sgml stat

stat-meta.sql: stat-meta.sgml

clean:
	rm -f stat-meta.png stat-meta.html stat-schema.html stat-schema.dot stat-schema.sql *~ *# .#*
