#!/usr/bin/perl

use strict;
use warnings;
use Saccs;

my $q=new CGI;
my $saccs=Saccs->new(cgi=>$q);

my $type=$q->param('type') || '';
my @date=localtime();
my $action=$q->param('action') || '';

my $template;

sub view();

if($action eq 'create') { #defined $q->param('create') ) {
    if(defined($q->param('name'))) {
        $template=HTML::Template->new(
            filename=>'templates/message.html',
            die_on_bad_params=>0,
        );
        $template->param(MSG=>$saccs->createaccount());
    }
    else {
        $template=HTML::Template->new(
            filename=>'templates/newacctquestions.html',
            die_on_bad_params=>0,
        );
    }
}

elsif($action eq 'adddetail') {
    $saccs->adddetail();
    view();
}

elsif($action eq 'view') { #defined $q->param('view') ) {
    view();
}


elsif($action eq 'newmonth') {
    $template=HTML::Template->new(
        filename=>'templates/message.html',
        die_on_bad_params=>0,
    );
    $template->param(MSG => $saccs->newmonth() );
}

elsif ($action eq 'flipflag') { #defined $q->param('flipflag')) {
    $saccs->flipflag();
    view();
}

elsif($action eq 'deldetails') {
    if(defined $q->param('yes')) {
        $saccs->deldetails();
        view();
    }
    else {
        $template=HTML::Template->new(
            filename => 'templates/confirm.html',
            die_on_bad_params => 0,
        );
        $template->param(MSG => 'Are you sure you want to delete marked records?');
        $template->param(IDS => join(' ',$q->param('del')));
        $template->param(PERSONIDS => join(' ',$q->param('delperson')));
        $template->param(ACTION => 'deldetails');
        $template->param(ACID => $q->param('acid'));
        $template->param(DETAILS => $q->param('details'));
        $template->param(MONTHLYID => $q->param('monthlyid'));
    }
}

elsif($action eq 'resetperson') {
    if(defined $q->param('yes')) {
        $saccs->resetperson();
        view();
    }
    else {
        $template=HTML::Template->new(
            filename => 'templates/confirm.html',
            die_on_bad_params => 0,
        );
        $template->param(MSG => 'Are you sure you want to reset the total?');
        $template->param(IDS => join(' ',$q->param('del')));
        $template->param(PERSONIDS => join(' ',$q->param('pid')));
        $template->param(ACTION => 'resetperson');
        $template->param(ACID => $q->param('acid'));
        $template->param(DETAILS => $q->param('details'));
        $template->param(MONTHLYID => $q->param('monthlyid'));
    }
}

elsif($action eq 'edit') {
    if(defined $q->param('save')) {
        $saccs->saveedit();
        view();
    }
    else {
        my $editstuff=$saccs->edit();
        $template=HTML::Template->new(
            filename => 'templates/edit.html',
            die_on_bad_params => 0,
        );
        $template->param(ID => $q->param('id'));
        $template->param(MONTHLYID => $q->param('monthlyid'));
        $template->param(ACID => $q->param('acid'));
        $template->param(AMT => $editstuff->{'amt'});
        $template->param(DESCR => $editstuff->{'descr'});
        $template->param(CLEARED => $editstuff->{'cleared'});
        $template->param(YEAR => $editstuff->{'year'});
        $date[4]=$editstuff->{'mon'}-1;
        $date[3]=$editstuff->{'date'};
    }
}

elsif($action eq 'delacct' && !defined $q->param('yes')) {
    $template=HTML::Template->new(
        filename => 'templates/confirm.html',
        die_on_bad_params => 0,
    );
    my $dat=$saccs->getacctdata($q->param('acid'));
    $template->param(MSG => 'Are you sure you want to delete '. $dat->{'name'} .
        # $dat->{'actype'}
        ' account and all its records?');
    $template->param(ACTION => 'delacct');
    $template->param(ACID => $q->param('acid'));
}

elsif($action eq 'graphs') {
    $template=HTML::Template->new(
        filename => 'templates/graphs.html',
        die_on_bad_params => 0,
    );
    my @graphdata;
    my $subaction=$q->param('subaction') || '';
    if($subaction eq 'consol') {
        #combined graph
        @graphdata=({acid=>0});
        $template->param(GRAPHCONSOL => 1);
    }
    else {
        #separate graphs
        $saccs->setaccounts;
        foreach (@{ $saccs->{'bankaccounts'} }) {
            push(@graphdata,$_);
        }
    }
    $template->param(GRAPHLINKS => \@graphdata);
}
elsif ($action eq 'community') {
    if(defined $q->param('addname')) {
        $saccs->addname();
    }
    view();
}
elsif ($action eq 'renacct') {
    if(defined $q->param('name')) {
        $saccs->renacct();
    }
    view();
}
elsif ($action eq 'chg_credit_limit') {
    $saccs->chg_credit_limit();
    view();
}
elsif ($action eq 'chg_start_date') {
    $saccs->chg_date('start');
    view();
}
elsif ($action eq 'chg_end_date') {
    $saccs->chg_date('end');
    view();
}
else {
    #actions that only require to show home page
    if($action eq 'xfer') {
        $saccs->xfer();
    }
    if($action eq 'delacct' && defined $q->param('yes')) {
        $saccs->delacct();
    }
    $template=HTML::Template->new(
        filename=>'templates/home.html',
        die_on_bad_params=>0,
    );
}


# common template params, like dates,a ccount type, etc

$template->param(CURRDATE => $date[3]);
$template->param(CURRMONTH => $date[4]+1);
$template->param(CURRYEAR => $date[5]+1900);

{
    my @temp;

    for(my $i=1;$i<=31;$i++) {
        my $j=sprintf("%02d",$i);
        my $sel=0;
        $sel=1 if $i==$date[3];
        push(@temp,{key=>$j,val=>$j,SELECTED => $sel==0?'':' selected '});
    }
    $template->param(DATELIST => \@temp);
}

{
    my @temp;
    my @mons=(
        'Jan', 'Feb',
        'Mar', 'Apr',
        'May', 'Jun',
        'Jul', 'Aug',
        'Sep', 'Oct',
        'Nov', 'Dec',
    );
    for(my $i=0;$i<=$#mons;$i++) {
        my $j=sprintf("%02d",$i+1);
        my $sel=0;
        $sel=1 if $i==$date[4]; 
        push(@temp,{key=>$j,val=>$mons[$i],SELECTED => $sel==0?'':' selected '});
    }
    $template->param(MONTHLIST => \@temp);
}

if($type eq 'bank' || $type eq 'b') {
    $template->param(BANK=>1);
}
if($type eq 'cc' || $type eq 'c') {
    $template->param(CC=>1);
}
if($type eq 'community' || $type eq 'm') {
    $template->param(COMMUNITY=>1);
}
$template->param(TYPE => $q->param('type'));


print $saccs->header;
$template->param(ACCTS => $saccs->{'accounts'});
print $template->output;
print $saccs->footer;

exit;


sub view() {
    $template=HTML::Template->new(
        filename => 'templates/view.html',
        die_on_bad_params =>0,
    );
    my ($data,$months,$details);
    ($data,$months,$details)=$saccs->view();
    my @months=();
    @months=@$months if defined $months;
    $type=$data->{'actype'};
    $template->param(ACID => $data->{'id'});
    $template->param(MONTHS => $months);
    $template->param(MONTHSR => \@months);
    $template->param(ACNAME => $data->{'name'});
    if(defined $details) {
        my $mdat=pop @$details;
        foreach(keys %$mdat) {
            $template->param($_ => $mdat->{$_});
        }
        $template->param(MONTHLYID => $q->param('monthlyid'));
        $template->param(DETAILS => $details);
    }
    else {
        $template->param(MONTHLYVIEW => 1);
    }
} # sub view

# EOF
