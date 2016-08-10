#!/usr/local/bin/perl


print "Content-Type: text/html\n\n";
# Note there is a newline between 
# this header and Data

# Simple HTML code follows


system($^X, "yourscript.pl", @ARGS);


print "<html> <head>\n";
print "<title>Hello, world!</title>";
print "</head>\n";
print "<body>\n";
print "<h1>Hello, world!</h1>\n";
print "</body> </html>\n";