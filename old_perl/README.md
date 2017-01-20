saccs
=====

Single-user personal accounting Perl web-app


Old code
--------

Poorly-maintained ancient code. I wrote it a long time ago (2001?) and barely maintain it.


Setup
-----

Create the database as listed in database.sql and make a db user and password.

Put this entire directory in a cgi-bin location and protect it with HTTP Basic Auth.

Make copies of the `*.template` files without the `.template`, and edit them to suit.


Requirements
------------

* Web server able to run Perl CGI scripts
* MySQL
* Perl's CGI and MySQL modules
* Perl's Text::CSV module

