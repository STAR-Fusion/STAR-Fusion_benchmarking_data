#!/usr/bin/env perl

use strict;
use warnings;
use Carp;


my %converter = (CHIMERASCAN => 'ChimeraScan',
                 CHIMPIPE => 'ChimPipe',
                 DEFUSE => 'deFuse',
                 ERICSCRIPT => 'EricScript',
                 FUSIONHUNTER => 'FusionHunter',
                 FUSION_CATCHER_V0994e => 'FusionCatcher',
                 INFUSION_CF3 => 'InFusion',
                 JAFFA_ASSEMBLY => 'JAFFA-Assembly',
                 JAFFA_DIRECT => 'JAFFA-Direct',
                 JAFFA_HYBRID => 'JAFFA-Hybrid',
                 MAPSPLICE => 'MapSplice',
                 NFUSE => 'nFuse',
                 PRADA => 'PRADA',
                 SOAP_FUSE => 'SOAP-fuse',
                 STAR_FUSION_GRCh37v19_FL3_v51b3df4 => 'STAR-Fusion',
                 TOPHAT_FUSION => 'TopHat-Fusion',
    );


while (<STDIN>) {
    chomp;
    my $filename = $_;

    if ($filename =~ m|/samples/([^/]+)/([^/]+)/|) {
        
        my $sample_name = $1;
        my $prog = $2;
        
        my $proper_progname = $converter{$prog} or die "Error, cannot find proper prog name for $prog";
        
        print join("\t", $sample_name, $proper_progname, $filename) . "\n";
    }
    else {
        print STDERR "WARNING: couldn't decipher filename $filename as fusion result file\n";
    }
}


exit(0);


    
