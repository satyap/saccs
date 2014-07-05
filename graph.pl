#!/usr/bin/perl
# generates a graph of monthly balances

use strict;
use warnings;
use Saccs;
use GD::Graph::lines;

my $q=new CGI;
my $saccs=Saccs->new(cgi=>$q);

my $acid=$q->param('acid') || 0;
my $width=800;
my $height=300;
$height+=10 unless $acid;


#my @date=localtime;
#my $date=sprintf("%04d%02d%02d",$date[5]+1900,$date[4]+1,$date[3]);
my $data;
my $items=int($width/16);

$data=$saccs->getgraphdata(
    acid=>$acid,
    items=> $items,
);

my $title;
my @legends;

foreach(@{ $saccs->{'bankaccounts'} }) {
    $title=$_->{'name'} if $_->{'id'}==$acid;
    push(@legends,$_->{'name'});
}

$height+=(($#legends/4)*10) unless $acid;

my $graph=GD::Graph::lines->new($width,$height);
unless($acid) {
    $graph->set_legend('Total', @legends);
}

my $dat=GD::Graph::Data->new($data);
my($ymin,$ymax)=$dat->get_min_max_y_all();
my $factor=1;
my $f=$ymax;
while ($f>100) {
   $f/=10;
   $factor*=10;
   }
$ymax=(int($ymax/$factor+1))*$factor;
$ymin=(int($ymin/100))*100;

$title = $title || $q->param('title') || 'Consolidated';
$title .= ' ' . $data->[1][-1];
$graph->set(
    title=>$title,
    x_labels_vertical=>1,
    y_long_ticks=>1,
    y_plot_values => 1,
    y_max_value => $ymax,
    y_min_value => $ymin,
);

my $gd=$graph->plot($data) || carp($graph->error);

print "Content-type: image/png\n\n";
print $gd->png;

$saccs->{'dbh'}->disconnect;

# EOF
