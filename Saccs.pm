package Saccs;
use Text::CSV;

# Satya's accounts program a.k.a. Saccs of Gold.

our $VERSION=0.8;

use strict;
use warnings;
use DBI;
use HTML::Template;
use CGI;
use CGI::Carp qw(fatalsToBrowser);

use saccsconf qw($dbd $dbh $dbuser $dbpass $html_root);

sub prettifymonth($); # prints pretty: yyyy-mm (or Mon yyyy)
sub cleared2perl($); # unambiguously returns 0 or 1.

sub new() {
    my $class = shift;
    my %args = @_;
    my $self = bless { %args }, ref($class) || $class;
    
    my $dbh=DBI->connect($dbh,$dbuser,$dbpass,$dbd) || Saccs::error($DBI::errstr);
    $self->{'header'}=0;
    $self->{'dbh'}=$dbh;
    return $self;
} # sub new

sub header() {
    my $self=shift;

    print "Content-type: text/html\n\n";
    $self->{'header'}=1;
    $self->setaccounts();

    my $template=HTML::Template->new(
        filename=>'templates/header.html',
        die_on_bad_params => 0,
    );
    $template->param(ACCTS => $self->{'accounts'});
    $template->param(HTML_ROOT=>$html_root);
    return $template->output;
    
} # sub header

sub setaccounts() {
    my $self=shift;
    my $dbh=$self->{'dbh'};
    my @accounts;
    my @bankaccounts;
    my $sth=$dbh->prepare('SELECT * FROM `accounts` ORDER BY `actype`,`name`');
    $sth->execute || $self->error($DBI::errstr);
    while(my $row=$sth->fetchrow_hashref()) {
        push(@accounts,$row);
        push(@bankaccounts,$row) if $row->{'actype'} eq 'b';
    }
    $self->{'accounts'}=\@accounts;
    $self->{'bankaccounts'}=\@bankaccounts;
} # setaccounts

sub footer() {
    my $self=shift;
    my $template=HTML::Template->new(filename=>'templates/footer.html');
    $template->param(SACCSVERSION => $VERSION);
    if($self->{'dbh'}) {
        $self->{'dbh'}->disconnect;
    }
    return $template->output;
} # sub footer

sub error() {
    my $self=shift;
    my @args=shift;
    unless(ref($self)) {
        print "Content-type: text/plain\n\n";
        print $self;
    }
    else {
        if($self->{'header'}==0) {
            print "Content-type: text/plain\n\n";
        }
    }
    print @args;
    exit;
} # sub error

sub createaccount() {
    my $self=shift;
    my %args=@_;
    my $dbh=$self->{'dbh'};
    my $cgi=$self->{'cgi'};
    my $type=$cgi->param('type') || '';

    my $sql;
    my $sth;
    
    my $row;
    my $id;
   
    if($type eq 'bank') {
        $sth=$dbh->prepare('INSERT INTO `accounts` (`name`, `actype`) VALUES(?,?)');
        $sth->execute($cgi->param('name'),'b') || $self->error($DBI::errstr);
        $sth=$dbh->prepare('select LAST_INSERT_ID()');
        $sth->execute || $self->error($DBI::errstr);
        $row=$sth->fetchrow_arrayref;
        $id=$row->[0];
        $sth=$dbh->prepare('INSERT INTO `monthly` (`account`,`startdate`,`enddate`,`startamt`,`endamt`) VALUES(?,?,?,?,?)');
        my $month=$cgi->param('month');
        my $year=$cgi->param('year');
        if($year<100) {
            $year='19'.$year;
        }
        my $startdate=$year.'-'.$month.'-01';
        $month++;
        if($month>12) {
            $year++;$month='01';
        }
        my $enddate=sprintf("%04d-%02d-01",$year,$month);
        $sth->execute($id,$startdate,$enddate,$cgi->param('startamt'),$cgi->param('startamt')) || $self->error($DBI::errstr);
        return 'Account created';
    }

    if($type eq 'cc') {
        $sth=$dbh->prepare('INSERT INTO `accounts` (`name`, `actype`,`climit`) VALUES(?,?,?)');
        $sth->execute($cgi->param('name'),'c',$cgi->param('startamt'))
        || $self->error($DBI::errstr);
        return 'Account created';
    }
    
    if($type eq 'community') {
        $sth=$dbh->prepare('INSERT INTO `accounts` (`name`, `actype`,`climit`) VALUES(?,?,0)');
        $sth->execute($cgi->param('name'),'m') || $self->error($DBI::errstr);
        return 'Account created';
    }

} # sub createaccount


sub view() {
    my $self=shift;
    my %args=@_;
    my $q=$self->{'cgi'};
    my $dbh=$self->{'dbh'};
    my $data;
    my $details;
    my @months;

    my $id=$q->param('acid');
    return unless defined $id;

    my $sth=$dbh->prepare('SELECT * FROM `accounts` WHERE `id`=?');
    $sth->execute($id) || $self->error($DBI::errstr);
    my $row=$sth->fetchrow_hashref;
    $data=$row;
    my $actype=$row->{'actype'};
    $sth->finish;


    if($actype eq 'b') {
        # for bank, return the list from monthly
        my $prev;
        $sth=$dbh->prepare('SELECT * FROM `monthly` WHERE `account`=? ORDER BY `startdate`,`enddate`');
        $sth->execute($id) || $self->error($DBI::errstr);
        while($row=$sth->fetchrow_hashref()) {
            if(defined $prev && $prev != $row->{'startamt'}) {
                $row->{'mismatch'}=1;
            }
            $row->{'startdate'}=prettifymonth($row->{'startdate'});
            $row->{'enddate'}=prettifymonth($row->{'enddate'});
            $prev=$row->{'endamt'};
            $row->{'startamt'}=sprintf("%0.2f",$row->{'startamt'});
            $row->{'endamt'}=sprintf("%0.2f",$row->{'endamt'});
            push(@months,$row);
        }
        $sth->finish;
        @months=reverse @months;
        # and the details
        if(defined $q->param('details') ) {
            $details=$self->showdetail();
        }
    }
    
    if($actype eq 'c') {
        # for credit card just return the details
        my ($bal,$clearedbal,$climit);
        $climit=$row->{'climit'};
        $sth=$dbh->prepare('SELECT * FROM `details` WHERE `account`=? ORDER BY `ondate` DESC,`descr`');
        $sth->execute($id);
        while($row=$sth->fetchrow_hashref()) {
            $bal+=$row->{'amt'};
            $row->{'cleared'}=cleared2perl($row->{'cleared'});
            if($row->{'cleared'} == 1) {
                $clearedbal+=$row->{'amt'};
            }
            $row->{'amt'}=&format_amount($row->{'amt'});
            #$row->{'amt'}=sprintf("%0.2f",$row->{'amt'});
            push(@$details,$row);
        }
        $sth->finish;
        push(@$details,{
                climit => sprintf("%0.2f",$climit),
                bal => sprintf("%0.2f",$bal),
                clearedbal => sprintf("%0.2f",$clearedbal),
                avail => sprintf("%0.2f",$climit-$bal),
                clearedavail => sprintf("%0.2f",$climit-$clearedbal),
            });
        @months=();
    }

    if($actype eq 'm') {
        #community account, return the rows grouped by name -- return the names in the months array
        my $sthnames = $dbh->prepare('SELECT * FROM `people` WHERE `account`=? ORDER BY `name`');
        my $sthentries = $dbh->prepare('SELECT `community`.*,`people`.`name` as `nname` FROM `community` LEFT JOIN `people` ON `community`.`name`=`people`.`id` WHERE `community`.`account`=? ORDER BY `ondate`,`descr`');
        my %col=();
        $sthnames->execute($id);
        my $i = 0;
        my @nbsp = ();
        my @totals = ();
        while(my $r = $sthnames->fetchrow_hashref()) {
            $col{$r->{'id'}} = $i;
            push(@nbsp,{AMT => '&nbsp;'});
            push(@totals,{TOTAL => 0});
            $r->{'personid'} = $r->{'id'};
            delete $r->{'id'};
            $r->{'acid'} = $id;
            push(@months,$r);
            $i++;
        }
        $sthnames->finish;
        $sthentries->execute($id);
        while(my $r = $sthentries->fetchrow_hashref()) {
            my $hash = {};
            my $row = [@nbsp];
            $row->[ ($col{ $r->{'name'} }) ] = {AMT=>&format_amount($r->{'amt'})};
            $totals[ ($col{ $r->{'name'} }) ]->{TOTAL} += $r->{'amt'};
            $hash->{'amts'} = $row;
            $hash->{'id'} = $r->{'id'};
            $hash->{'account'} = $r->{'account'};
            $hash->{'ondate'} = $r->{'ondate'};
            $hash->{'descr'} = $r->{'descr'};
            push(@$details,$hash);
        }
        for(my $i=0;$i<=$#totals;$i++) {
            $totals[$i]->{'TOTAL'} = &format_amount($totals[$i]->{'TOTAL'});
        }
        push(@$details,{
                TOTALS => \@totals,
            });
        
    } # if actype eq m -- community

    
    return $data,\@months,$details;
} # sub view


sub showdetail() {
    # for bank type account, this shows the month detail
    my $self=shift;
    my $q=$self->{'cgi'};
    my $dbh=$self->{'dbh'};
    my @details=();
    my $row;

    my $id=$q->param('acid');
    my $monthlyid=$q->param('monthlyid');
    return undef unless defined $monthlyid;
    my $sql;
    my $sth;

    $sql='SELECT * FROM `monthly` WHERE `id`=?';
    $sth=$dbh->prepare($sql);
    $sth->execute($monthlyid) || $self->error($DBI::errstr);
    my $monthly=$sth->fetchrow_hashref();
    $sth->finish;

    my $startdate=$monthly->{'startdate'};
    my $enddate=$monthly->{'enddate'};
    my $startamt=$monthly->{'startamt'};
    my $clearedbal=$startamt;
    my $bal=$startamt;

    $sql='SELECT * FROM `details` WHERE `account`=? AND `ondate`>=? AND `ondate`<=? ORDER BY `ondate`, `descr`';

    $sth=$dbh->prepare($sql);
    $sth->execute($id,$startdate,$enddate) || $self->error($DBI::errstr);
    while($row=$sth->fetchrow_hashref() ) {
        $bal-=$row->{'amt'};
        $row->{'cleared'}=cleared2perl($row->{'cleared'});
        if($row->{'cleared'} == 1) {
            $clearedbal-=$row->{'amt'};
        }
        $row->{'amt'}=sprintf("%0.2f",$row->{'amt'});
        $row->{'monthlyid'}=$monthlyid;
        push(@details,$row);
    }
    $sth->finish;

    push @details,{
        enddate=>$enddate,
        startdate=>$startdate,
        startamt=>sprintf("%0.2f",$startamt),
        bal=>sprintf("%0.2f",$bal),
        cleared=>sprintf("%0.2f",$clearedbal),
        difference=>sprintf("%0.2f",$clearedbal-$bal),
        outflow=>sprintf("%0.2f",$startamt-$bal),
    };

    $sql='UPDATE `monthly` SET `endamt`=? WHERE `id`=?';
    $sth=$dbh->prepare($sql);
    $sth->execute($bal,$monthlyid);

    return \@details;
} # sub showdetail


sub newmonth() {
    my $self=shift;
    my $q=$self->{'cgi'};
    my $dbh=$self->{'dbh'};

    my @endday=(99,31,28,31,30,31,30,31,31,30,31,30,31);

    my $id=$q->param('id');
    unless(defined $id) {
        return "No id given";
    }
    my $month=$q->param('month') || 0;
    if($month<1 || $month >12) {
        return "Bad month";
    }
    my $year=$q->param('year') || 0;
    $year=~s/[^0-9]//g;
    my $startamt=$q->param('startamt');
    my $startdate=sprintf("%04d-%02d-01",$year,$month);
#    $month++;
#    if($month>12) {
#        $year++;$month=1;
#    }
    my $enddate=sprintf("%04d-%02d-%02d",$year,$month,$endday[$month]);

    my $sth;

    #my $select='select * from monthly where startdate=? and enddate=?';
    #$sth=$dbh->prepare($sql);
    #$sth->execute($startdate,$enddate) || $self->error($DBI::errstr);
    #$sth->finish
    #if($sth->rows>0) {
    #    return "Month already exists";
    #}

    my $insert='INSERT INTO `monthly` (`account`,`startdate`,`enddate`,`startamt`,`endamt`)';
    $insert.=' VALUES(?,?,?,?,?)';
    $sth=$dbh->prepare($insert);
    $sth->execute($id,$startdate,$enddate,$startamt,$startamt) || $self->error($DBI::errstr);
    $sth->finish;

    $sth = $dbh->prepare('SELECT last_insert_id()');
    $sth->execute;
    my $newid = ($sth->fetchrow_array())[0];
    
    return "New month opened <a href='index.pl?action=view&acid=$id&details=1&monthlyid=$newid'>Go</a>";
} # newmonth


sub adddetail() {
    my $self=shift;
    my $q=$self->{'cgi'};
    my $dbh=$self->{'dbh'};
    my ($sql,$sth);

    my $year=$q->param('year') || 1900;
    my $month=$q->param('month') || '01';
    my $date=$q->param('date') || '01';
    my $descr=$q->param('descr');
    my $amt=$q->param('amt') || 0;

    my $id=$q->param('acid');

    return unless defined $id;
    
    my $actype = $self->gettype();
    my $ondate=sprintf("%04d-%02d-%02d",$year,$month,$date);
    my @params=($id,$ondate,$descr,$amt);

    if($actype eq 'm') {
        $sql='INSERT INTO `community` (`account`,`ondate`,`descr`,`amt`,`name`)';
        $sql.=' VALUES (?,?,?,?,?)';
        push(@params,$q->param('person'));
    }
    else {
        $sql='INSERT INTO `details` (`account`,`ondate`,`descr`,`amt`,`cleared`)';
        $sql.=' VALUES (?,?,?,?,\'n\')';
    }

    $sth=$dbh->prepare($sql);
    $sth->execute(@params) || $self->error($DBI::errstr);
    $sth->finish;
    return;
    
} # sub adddetail


sub flipflag {
    my $self=shift;
    my $dbh=$self->{'dbh'};
    my $id=$self->{'cgi'}->param('id');
    return 'No id' unless defined $id;

    my $sth;

    $sth=$dbh->prepare('SELECT `cleared` FROM `details` WHERE `id`=?');
    $sth->execute($id) || $self->error($DBI::errstr);
    my $cleared=$sth->fetchrow_arrayref;
    $cleared=$cleared->[0];
    $sth->finish;
    
    $cleared=(cleared2perl($cleared) eq '1') ? 'n':'y';

    $sth=$dbh->prepare('UPDATE `details` SET `cleared`=? WHERE `id`=?');
    $sth->execute($cleared,$id) || $self->error($DBI::errstr);
    return "Flag flipped";
} # sub flipflag


sub deldetails() {
    my $self=shift;
    my $q=$self->{'cgi'};
    my $dbh=$self->{'dbh'};
    my ($sql,$sth);

    my @ids=split(/\s/,$q->param('ids'));
    my @personids=split(/\s/,$q->param('personids'));
    
    my $actype = $self->gettype();
    my $sql2='';
    my $sthdelperson;
    my $sthdelpersonrows;

    if($actype eq 'm') {
        $sql = 'DELETE FROM `community` WHERE `id`=?';
        $sthdelpersonrows = $dbh->prepare('DELETE FROM `community` WHERE `name`=?');
        $sthdelperson = $dbh->prepare('DELETE FROM `people` WHERE `id`=?');
    }
    else {
        $sql = 'DELETE FROM `details` WHERE `id`=?';
    }
    $sth=$dbh->prepare($sql);
    foreach(@ids) {
        $sth->execute($_) || $self->error($DBI::errstr);
    }
    $sth->finish;
    if($actype eq 'm') {
        foreach (@personids) {
            $sthdelpersonrows->execute($_) || $self->error($DBI::errstr);
            $sthdelperson->execute($_) || $self->error($DBI::errstr);
        }
        $sthdelpersonrows->finish;
        $sthdelperson->finish;
    }
    
    return;
} # sub deldetails

sub edit() {
    my $self=shift;
    my $q=$self->{'cgi'};
    my $dbh=$self->{'dbh'};
    my ($sql,$sth,$row,$ret);
    my $id=$q->param('id');
    return unless defined $q->param('id');

    my $actype = $self->gettype();

    if($actype eq 'm') {
        $sth=$dbh->prepare('SELECT * FROM `community` WHERE `id`=?');
    }
    else {
        $sth=$dbh->prepare('SELECT * FROM `details` WHERE `id`=?');
    }
    $sth->execute($id);
    while($row=$sth->fetchrow_hashref) {
        my $ondate=$row->{'ondate'};
        $row->{'year'}=substr($ondate,0,4);# 0123456789
        $row->{'mon'}=substr($ondate,5,2); # 0123-56-89
        $row->{'date'}=substr($ondate,8,2);
        $row->{'cleared'} = cleared2perl($row->{'cleared'});
        $ret=$row;
    }
    $sth->finish;
    return $ret;
    
} # edit

sub saveedit() {
    my $self=shift;
    my $q=$self->{'cgi'};
    my $dbh=$self->{'dbh'};
    my ($sql,$sth,$row,$ret);
    my $id=$q->param('id');
    return unless defined $q->param('id');
    
    my $actype = $self->gettype();

    my $ondate=sprintf("%04d-%02d-%02d",$q->param('year'),$q->param('month'),$q->param('date'));

    my @params=(
        $ondate,
        $q->param('descr'),
        $q->param('amt'),
    );
    if($actype eq 'm') {
        $sql='UPDATE `community` SET `ondate`=?,`descr`=?,`amt`=? WHERE `id`=?';
    }
    else {
        $sql='UPDATE `details` SET `ondate`=?,`descr`=?,`amt`=?,`cleared`=? WHERE `id`=?';
        push(@params,$q->param('cleared'));
    }
    push(@params,$q->param('id'));
    $sth=$dbh->prepare($sql);
    $sth->execute(@params) || $self->error($DBI::errstr);
    $sth->finish;

} # saveedit


sub xfer() {
    my $self=shift;
    my $q=$self->{'cgi'};
    my $dbh=$self->{'dbh'};

    my $sth;

    my $fromid=$q->param('from');
    my $toid=$q->param('to');

    my @date=localtime;

    my $date=sprintf("%04d-%02d-%02d",$date[5]+1900,$date[4]+1,$date[3]);

    $sth=$dbh->prepare('INSERT INTO `details` (`account`,`ondate`,`descr`,`amt`) VALUES(?,?,?,?)');
    $sth->execute($fromid,$date,$q->param('descrfrom'),$q->param('amt')) || $self->error($DBI::errstr);
    $sth->execute($toid,$date,$q->param('descrto'),-1*$q->param('amt')) || $self->error($DBI::errstr);
    $sth->finish;

} # xfer


sub delacct() {
    my $self=shift;
    my $q=$self->{'cgi'};
    my $dbh=$self->{'dbh'};

    my $sth;

    my $id=$q->param('acid');

    $sth=$dbh->prepare('DELETE FROM `accounts` WHERE `id`=?');
    $sth->execute($id) || $self->error($DBI::errstr);
    $sth->finish;
    $sth=$dbh->prepare('DELETE FROM `details` WHERE `account`=?');
    $sth->execute($id) || $self->error($DBI::errstr);
    $sth->finish;
    $sth=$dbh->prepare('DELETE FROM `monthly` WHERE `account`=?');
    $sth->execute($id) || $self->error($DBI::errstr);
    $sth->finish;
    
} # delacct


sub resetperson() {
    #resets a person's total to zero in the given community account
    my $self = shift;
    my $q = $self->{'cgi'};
    my $pid = $q->param('personids') || return;
    my $acid = $q->param('acid') || return;
    my $sth = $self->{'dbh'}->prepare('DELETE FROM `community` WHERE `account`=? AND `name`=?');
    $sth->execute($acid, $pid);
} # resetperson

sub getgraphdata() {
    my $self=shift;
    my %args=@_;
    my $acid=$args{'acid'};
    my $items=$args{'items'};
    my $dbh=$self->{'dbh'};
    my $sth;
    my @data;
    my (@x,@y);

    $self->setaccounts;

    $sth=$dbh->prepare("SELECT * FROM `monthly` WHERE `account`=? ORDER BY `startdate` DESC LIMIT $items"); # select latest first, reverse later
    my @ends;
    
    if($acid && $acid > 0) { # single line graph
        my @vals;
        $sth->execute($acid);
        while(my $r=$sth->fetchrow_hashref) {
            push(@x,$r->{'startdate'});
            push(@vals,$r->{'startamt'});
            push(@ends,[$r->{'enddate'},$r->{'endamt'}]);
        }
        unshift(@x,$ends[0]->[0]);
        unshift(@vals,$ends[0]->[1]);
        $y[0]=[reverse @vals];
    }
    else { # multi-line graph
        my $i=1;
        foreach my $ac (@{$self->{'bankaccounts'}}) {
            my @vals;
            $sth->execute($ac->{'id'});
            @ends=();
            while(my $r=$sth->fetchrow_hashref) {
                push(@ends,[$r->{'enddate'},$r->{'endamt'}]);
                push(@x,$r->{'startdate'});
                push(@vals,$r->{'startamt'});
            }
            unshift(@x,$ends[0]->[0]);
            unshift(@vals,$ends[0]->[1]);
            $y[$i++]=[reverse @vals];
        }
        my %dates; # remove any duplicate dates
        foreach(@x) {
            next if exists $dates{$_};
            $dates{$_}=1;
        }
        @x=reverse sort keys %dates;
        # pad all data arrays with undefs
        foreach my $arr (@y) {
            my $d=$#x - $#$arr;
            if($d>0) {
                for($i=0;$i<$d;$i++) { unshift(@$arr,undef) }
            }
        } # padding
        #get the monthly totals
        for($i=0;$i<=$#x;$i++) { # for each date (column)
            $y[0]->[$i]=0;
            for(my $j=1;$j<= $#y ;$j++) { # for each data series (row)
                $y[0]->[$i]+=($y[$j]->[$i] || 0);
            }
        } # monthly totals
    } # else
    $sth->finish;

    @y = ($y[0]) if $acid==-1;
    
    @x=reverse @x;
    @data=(\@x,@y);
    return \@data;
} # getgraphdata

sub renacct() {
    my $self=shift;
    my $q = $self->{'cgi'};
    my $acid = $q->param('acid') || return;
    my $name = $q->param('name') || return;
    $name =~ s/[^-_a-zA-Z0-9]//g;
    my $sth = $self->{'dbh'}->prepare('UPDATE `accounts` SET `name`=? WHERE `id`=?');
    $sth->execute($name, $acid);
    
} # renacct

sub chg_credit_limit() {
    my $self=shift;
    my $q = $self->{'cgi'};
    my $acid = $q->param('acid') || return;
    my $climit = $q->param('new_limit') || return;
    my $sth = $self->{'dbh'}->prepare('UPDATE `accounts` SET `climit`=? WHERE `id`=?');
    $sth->execute($climit, $acid);
    
} # chg_credit_limit

sub chg_date() {
    my $self=shift;
    my $datetype=shift;
    my $q = $self->{'cgi'};
    my $acid = $q->param('acid') || return;
    my $monthlyid = $q->param('monthlyid') || return;
    my $date = $q->param('date') || return;
    my $sql="UPDATE `monthly` SET `${datetype}date`=? WHERE id=?";
    #die $sql;
    my $sth = $self->{'dbh'}->prepare($sql);
    $sth->execute($date, $monthlyid);
} # chg_date

sub getacctdata() {
    # given id, return a hash of stuff from the accounts table
    my $self=shift;
    my $id=shift;
    my $sth=$self->{'dbh'}->prepare('SELECT * FROM `accounts` WHERE `id`=?');
    $sth->execute($id) || $self->error($DBI::errstr);
    my $row=$sth->fetchrow_hashref();
    $sth->finish;
    return $row;
} # getacctdata

sub download() {
    my $self = shift;
    my $id = shift;
    my $month_id = shift;
    my $sth;

    print "Content-type: text/plain\n\n";

    if($month_id) {
        $sth=$self->{'dbh'}->prepare('SELECT * FROM `details` 
            LEFT JOIN monthly ON startdate <= ondate 
                AND enddate >= ondate
                AND monthly.account = details.account
            WHERE monthly.id=? 
            ORDER BY `ondate` ASC,`descr`');
        $sth->execute($month_id);
    } else {
        $sth=$self->{'dbh'}->prepare('SELECT * FROM `details` WHERE `account`=? ORDER BY `ondate` ASC,`descr`');
        $sth->execute($id);
    }

    my $csv = Text::CSV->new or print "Cannot use CSV: ".Text::CSV->error_diag();
    
    my $first = 1;
    my @keys;
    while(my $row = $sth->fetchrow_hashref()) {
        if(1==$first) {
            @keys = ('ondate', 'cleared', 'amt', 'descr');
            $first = 0;
            $csv->combine(@keys);
            print $csv->string;
            print "\r\n";
        }

        $csv->combine(
            map { $row->{$_} } @keys
        );
        print $csv->string;
        print "\r\n";
    }

} # download

sub addname() {
    # add name to people table for community account
    my $self = shift;
    my $q = $self->{'cgi'};
    my $dbh = $self->{'dbh'};
    my $id = $q->param('acid');

    my $sth = $dbh->prepare('INSERT INTO `people` (`account`, `name`) VALUES (?,?)');
    $sth->execute($id,$q->param('name'));
    $sth->finish;
    
} # sub addname


sub prettifymonth($) {
    my @date=split(/-/,shift);
    my @m=('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
    #return $m[$date[1]] .' '. $date[0];
    return $date[0].'-'.$date[1];
} # prettifymonth


sub cleared2perl($) {
    my $x=shift;
    return 0 unless defined $x;
    if($x && (lc($x) eq 'y' || $x eq '1')) {
        return 1;
    }
    return 0;
} # cleared2perl

sub format_amount() {
    return  sprintf("%0.2f",shift);
}

sub gettype() {
    # return the account type, b, c, m
    my $self=shift;
    my $q=$self->{'cgi'};
    my $dbh=$self->{'dbh'};
    my $sth=$dbh->prepare('SELECT * FROM `accounts` WHERE `id`=?');
    $sth->execute($q->param('acid')) || $self->error($DBI::errstr);
    my $row=$sth->fetchrow_hashref;
    my $actype=$row->{'actype'};
    $sth->finish;
    return $actype;
} # gettype

1;
