#!/usr/bin/perl -w
#
# separate script because it has to be fast

use strict;
use warnings;
use DBI;
use CGI;

use saccsconf qw($dbd $dbh $dbuser $dbpass $html_root);
my $q=new CGI;
my $val=$q->param('val');
return unless defined $val;

my $dbh=DBI->connect($dbh,$dbuser,$dbpass,$dbd) || Saccs::error($DBI::errstr);
print "Content-type: text/xml\n\n";

if(length($val)<3) {
    print '';
    exit;
}

my $sth=$dbh->prepare("select descr from details where descr like ? group by descr limit 10");

$sth->execute("%$val%");

my $row;
my $ret='';
while($row=$sth->fetchrow_hashref() ) {
    $ret.=' ';
    $ret.='<a href="javascript:;" class="descdropdown" onclick="javascript:populate(this)">';
    $ret.=$row->{'descr'} . '</a>';
    $ret.= '<br/>';
}
$sth->finish;

print $ret;

$dbh->disconnect;

