#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use Cwd;
use File::Basename;


unless ($ENV{FUSION_SIMULATOR}) {

    if (-d "$ENV{HOME}/GITHUB/CTAT_FUSIONS/FusionSimulatorToolkit") {
        $ENV{FUSION_SIMULATOR} = "~/GITHUB/CTAT_FUSIONS/FusionSimulatorToolkit";
    }
    else {
        die "Error, must set env var FUSION_SIMULATOR to point to base dir of\n"
            . "     git clone https://github.com/FusionSimulatorToolkit/FusionSimulatorToolkit ";
    }
}

unless ($ENV{FUSION_ANNOTATOR}) {

    if (-d "$ENV{HOME}/GITHUB/CTAT_FUSIONS/FusionAnnotator") {
        $ENV{FUSION_ANNOTATOR} = "~/GITHUB/CTAT_FUSIONS/FusionAnnotator";
    }
    else {
        die "Error, must set env var FUSION_ANNOTATOR to point to base dir of\n"
            . "      git clone https://github.com/FusionAnnotator/FusionAnnotator.git\n"
            . "      (after having installed it)  ";
    }
}


if (basename(cwd()) !~ /^sim_(50|101)/) {
    die "Error, must run this while in the sim_50 or sim_101 directory.";
}



my $usage = "\n\n\tusage: $0  sim.truth.dat sim.fusion_TPM_values.dat\n\n";


my $sim_truth_set = $ARGV[0] or die $usage;
my $sim_fusion_TPM_values = $ARGV[1] or die $usage;

$sim_truth_set = &create_full_path($sim_truth_set);
$sim_fusion_TPM_values = &create_full_path($sim_fusion_TPM_values);


my $benchmark_data_basedir = "$FindBin::Bin/..";
my $benchmark_toolkit_basedir = $ENV{FUSION_SIMULATOR} . "/benchmarking";
my $fusion_annotator_basedir = $ENV{FUSION_ANNOTATOR};



main: {

    ## create file listing
    my $cmd = "find ./samples -type f | $benchmark_data_basedir/util/make_file_listing_input_table.pl > fusion_result_file_listing.dat";
    &process_cmd($cmd);

    # collect predictions
    $cmd = "$benchmark_toolkit_basedir/collect_preds.pl fusion_result_file_listing.dat > preds.collected";
    &process_cmd($cmd);

    # map fusion predictions to gencode gene symbols based on identifiers or chromosomal coordinates.
    $cmd = "$benchmark_toolkit_basedir/map_gene_symbols_to_gencode.pl "
        . " preds.collected "
        . " $benchmark_data_basedir/resources/genes.coords "
        . " $benchmark_data_basedir/resources/genes.aliases "
        . " $sim_truth_set "
        . " > preds.collected.gencode_mapped ";

    &process_cmd($cmd);

    # annotate
    $cmd = "$fusion_annotator_basedir/FusionAnnotator --annotate preds.collected.gencode_mapped  -C 2 > preds.collected.gencode_mapped.wAnnot";
    &process_cmd($cmd);

    # filter HLA and mitochondrial features
    $cmd = "$benchmark_toolkit_basedir/filter_collected_preds.pl preds.collected.gencode_mapped.wAnnot > preds.collected.gencode_mapped.wAnnot.filt";
    &process_cmd($cmd);


    ##################################
    ######  Scoring of fusions #######
    
    # score strictly
    &score_and_plot("preds.collected.gencode_mapped.wAnnot.filt", $sim_truth_set, 'analyze_strict', { allow_reverse_fusion => 0, allow_paralogs => 0 } );
    
    # score allow reverse fusion
    &score_and_plot("preds.collected.gencode_mapped.wAnnot.filt", $sim_truth_set, 'analyze_allow_reverse', { allow_reverse_fusion => 1, allow_paralogs => 0 } );

    # score allow reverse and allow for paralog-equivalence
    &score_and_plot("preds.collected.gencode_mapped.wAnnot.filt", $sim_truth_set, 'analyze_allow_rev_and_paralogs', { allow_reverse_fusion => 1, allow_paralogs => 1 } );
    
    
    exit(0);
    
    
}


####
sub score_and_plot {
    my ($input_file, $truth_set, $analysis_token, $analysis_settings_href) = @_;
    
    my $base_workdir = cwd();

    my $workdir = "__" . "$analysis_token";
    
    mkdir ($workdir) or die "Error, cannot mkdir $workdir";
    chdir ($workdir) or die "Error, cannot cd to $workdir";
    
    my $target_input_file = "$input_file.$analysis_token";
    &process_cmd("ln -s ../$input_file $target_input_file");

    # score
    my $cmd = "$benchmark_toolkit_basedir/fusion_preds_to_TP_FP_FN.pl --truth_fusions $truth_set --fusion_preds $target_input_file";
    
    if ($analysis_settings_href->{allow_reverse_fusion}) {
        $cmd .= " --allow_reverse_fusion ";
    }
    if ($analysis_settings_href->{allow_paralogs}) {
        $cmd .= " --allow_paralogs $benchmark_data_basedir/resources/paralog_clusters.dat ";
    }

    &process_cmd($cmd);


    chdir $base_workdir or die "Error, cannot cd back to $base_workdir";
    
    
    return;
        
}

####
sub process_cmd {
    my ($cmd) = @_;

    print STDERR "CMD: $cmd\n";
    my $ret = system($cmd);
    if ($ret) {
        die "Error, CMD: $cmd died with ret $ret";
    }

    return;
}
       
####
sub create_full_path {
    my ($path) = @_;

    unless ($path =~ /^\//) {
        $path = cwd() . "/$path";
    }

    return($path);
}

