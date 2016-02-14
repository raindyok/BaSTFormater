#!/usr/bin/perl
use warnings;
use strict;
@ARGV == 4 || die "Usage:
------------------------------------------------------
BaSTFormater.pl single|batch <traits> <trees> <output>
------------------------------------------------------
   BaSTFormater is a ulility to convert the posterior 
distributio of trees (PST) to BaTS-formatted nexus file, 
compatible with Windows, Mac OS X and Linux platform.
   To run BaSTFormater, you will need ActivePerl. 
   By Deng Cao & Raindy
   2013-11-25
------------------------------------------------------
";
my $mode = shift;
my $tbls = shift;
my $ins  = shift;
my $outs = shift;

my ( @tbl, @in, @out );
if ( $mode =~ /batch/i ) {
    if ( -d $tbls && -d $ins ) {

        #read in *tbl
        opendir TBLDIR, $tbls or die "Cannot open $tbls:$!\n";
        my @tbl_t = readdir TBLDIR;
        close TBLDIR;

        # read in *.trees
        opendir INDIR, $ins or die "Cannot open $ins:$!\n";
        my @in_t = readdir INDIR;
        close INDIR;

        @tbl_t = sort @tbl_t;
        @in_t  = sort @in_t;

        # judge if the file number of two folders is equal.
        if ( @tbl_t != @in_t ) {
            print STDERR "files in [$tbls] do not equal to [$ins]\n";
            exit 1;
        }

        # judge wether they are pairs, and get corresponding outfile names.
        for ( my $i = 0 ; $i <= $#tbl_t ; $i++ ) {
            my ( $tbl, $in ) = ( $tbl_t[$i], $in_t[$i] );
            next if $tbl =~ /^\.+$/;
            push @tbl, "$tbls\\$tbl";
            push @in,  "$ins\\$in";
            my ($a) = $tbl =~ /(\S+)\.tbl$/;
            my ($b) = $in  =~ /(\S+)\.trees$/;
            $a = "$a";
            $b = "$b";

            if ( $a ne $b ) {
                print STDERR "file [$tbl] and [$in] have different prefix!\n";
                exit 1;
            }
            push @out, "$outs\\$a.trees";
        }

        unless ( -d $outs ) {
            mkdir $outs or die "Cannot create dir [$outs]:$!\n";
        }
    }
    else {
	    print STDERR "You're using batch mode, all the parameters should be directories.\n";
	    exit 1;
    }
}
elsif ( $mode =~ /single/i ) {
    if ( -f $tbls && -f $ins ) {
        push @tbl, $tbls;
        push @in,  $ins;
        push @out, $outs;
    }
    else {
	    print STDERR "You're using single mode, all the parameters should be files.\n";
	    exit 1;
    }

}
else {
    print STDERR "Unkown mode...\n";
    exit 1;
}

for ( my $i = 0 ; $i <= $#tbl ; $i++ ) {
    my ( $tbl, $in, $out ) = ( $tbl[$i], $in[$i], $out[$i] );
    $tbl =~ s/\\/\//g;
    $in  =~ s/\\/\//g;
    $out =~ s/\\/\//g;
    my $cor = {};
    open TBL, $tbl || die "Cannot open [$tbl]: $!\n";
    while (<TBL>) {
        chomp;
        next if /^#/ || /^\s*$/;
        s/^\s*|\s*$//g;
        my ( $NO, $taxa, $trait ) = split /\s+/, $_, 3;
        $cor->{$taxa} = "$NO $trait";
    }
    close TBL;

    my @headers  = ();
    my $to_print = 1;
    open IN,  $in     || die "Cannot open [$in]: $!\n";
    open OUT, ">$out" || die "Cannot open [$out]: $!\n";

    while (<IN>) {
        if (/^\s*(\d+)\s+([^\s,]+).*$/) {
            push @headers, "$cor->{$2}";
        }
        if (/^tree STATE_/) {
            if ($to_print) {
                print OUT "#NEXUS\n\nbegin states;\n", join( "\n", @headers ), "\nEnd;\n\nbegin trees;\n";
                $to_print = 0;
            }
#            s/\[(&rate=.*?)\]//g; s/\[(&lnP=.*?)\] //g; 
            s/\[(.*?)\]//g; s/ = /= [&R]/g; # debug at 20131220
            print OUT $_;
        }
    }
    close IN;
    print OUT "End;\n";
    close OUT;
}
