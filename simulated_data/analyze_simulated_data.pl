#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use Cwd;
use File::Basename;
use lib ("$FindBin::Bin/../PerlLib");
use Pipeliner;
use Process_cmd;

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

$sim_truth_set = &ensure_full_path($sim_truth_set);
$sim_fusion_TPM_values = &ensure_full_path($sim_fusion_TPM_values);


my $benchmark_data_basedir = "$FindBin::Bin/..";
my $benchmark_toolkit_basedir = $ENV{FUSION_SIMULATOR} . "/benchmarking";
my $fusion_annotator_basedir = $ENV{FUSION_ANNOTATOR};



main: {

    my $pipeliner = new Pipeliner(-verbose => 2, -log => 'pipe.log');
    my $checkpoint_dir = cwd() . "/_checkpoints";
    unless (-d $checkpoint_dir) {
        mkdir $checkpoint_dir or die "Error, cannot mkdir $checkpoint_dir";
    }
    $pipeliner->set_checkpoint_dir($checkpoint_dir);
    
    ## create file listing
    my $cmd = "find ./samples -type f | $benchmark_data_basedir/util/make_file_listing_input_table.pl > fusion_result_file_listing.dat";
    $pipeliner->add_commands(new Command($cmd, "fusion_file_listing.ok"));

    # collect predictions
    $cmd = "$benchmark_toolkit_basedir/collect_preds.pl fusion_result_file_listing.dat > preds.collected";
    $pipeliner->add_commands(new Command($cmd, "collect_preds.ok"));

    # map fusion predictions to gencode gene symbols based on identifiers or chromosomal coordinates.
    $cmd = "$benchmark_toolkit_basedir/map_gene_symbols_to_gencode.pl "
        . " preds.collected "
        . " $benchmark_data_basedir/resources/genes.coords "
        . " $benchmark_data_basedir/resources/genes.aliases "
        . " $sim_truth_set "
        . " > preds.collected.gencode_mapped ";

    $pipeliner->add_commands(new Command($cmd, "gencode_mapped.ok"));

    # annotate
    $cmd = "$fusion_annotator_basedir/FusionAnnotator --annotate preds.collected.gencode_mapped  -C 2 > preds.collected.gencode_mapped.wAnnot";
    $pipeliner->add_commands(new Command($cmd, "annotate_fusions.ok"));

    # filter HLA and mitochondrial features
    $cmd = "$benchmark_toolkit_basedir/filter_collected_preds.pl preds.collected.gencode_mapped.wAnnot > preds.collected.gencode_mapped.wAnnot.filt";
    $pipeliner->add_commands(new Command($cmd, "filter_fusion_annot.ok"));
    
    $pipeliner->run();
    
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
    
    $input_file = &ensure_full_path($input_file);
        
    my $base_workdir = cwd();

    my $workdir = "__" . "$analysis_token";

    unless (-d $workdir) {
        mkdir ($workdir) or die "Error, cannot mkdir $workdir";
    }
    chdir ($workdir) or die "Error, cannot cd to $workdir";
    
    
    my %sample_to_truth = &parse_truth_set($truth_set);
    my %sample_to_fusion_preds = &parse_fusion_preds("../$input_file");

    
    foreach my $sample_type (keys %sample_to_truth) {
        my $sample_checkpoint = "$sample_type.ok";
        if (! -e $sample_checkpoint) {
            &examine_sample($sample_type, $sample_to_truth{$sample_type}, $sample_to_fusion_preds{$sample_type}, $analysis_settings_href);
            &process_cmd("touch $sample_checkpoint");
        }
    }
    
    chdir $base_workdir or die "Error, cannot cd back to $base_workdir";
    
    ## generate summary accuracy box plots


    return;
}
    
####
sub examine_sample {
    my ($sample_type, $sample_truth_href, $sample_to_fusion_preds_text, $analysis_settings_href) = @_;

    my $basedir = cwd();

    my $sample_dir = "$sample_type";
    unless (-d $sample_dir) {
        mkdir($sample_dir) or die "Error, cannot mkdir $sample_dir";
    }
    chdir $sample_dir or die "Error, cannot cd to $sample_dir";

    my $sample_TP_fusions_file = "TP.fusions.list";
    my $fusion_preds_file = "fusion_preds.txt";

    my $prep_inputs_checkpoint = "_prep.ok";
    
    if (! -e $prep_inputs_checkpoint) {
        {
            my @TP_fusions = keys %{$sample_truth_href};
            
            open (my $ofh, ">$sample_TP_fusions_file") or die "Error, cannot write to $sample_TP_fusions_file";
            print $ofh join("\n", @TP_fusions) . "\n";
            close $ofh;
        }
                
        {
            open (my $ofh, ">$fusion_preds_file") or die "Error, cannot write to $fusion_preds_file";
            print $ofh $sample_to_fusion_preds_text;
            close $ofh;
        }
    
        &process_cmd("touch $prep_inputs_checkpoint");
    }


    ## run analysis pipeline
    my $pipeliner = new Pipeliner(-verbose => 2, -cmds_log => 'pipe.log');
    my $checkpoint_dir = cwd() . "/_checkpoints";
    unless (-d $checkpoint_dir) {
        mkdir $checkpoint_dir or die "Error, cannot mkdir $checkpoint_dir";
    }
    $pipeliner->set_checkpoint_dir($checkpoint_dir);
    
    ##################
    # score TP, FP, FN
    
    my $cmd = "$benchmark_toolkit_basedir/fusion_preds_to_TP_FP_FN.pl --truth_fusions $sample_TP_fusions_file --fusion_preds $fusion_preds_file";
    
    if ($analysis_settings_href->{allow_reverse_fusion}) {
        $cmd .= " --allow_reverse_fusion ";
    }
    if ($analysis_settings_href->{allow_paralogs}) {
        $cmd .= " --allow_paralogs $benchmark_data_basedir/resources/paralog_clusters.dat ";
    }

    $cmd .= " > $fusion_preds_file.scored";

    $pipeliner->add_commands(new Command($cmd, "tp_fp_fn.ok"));

    ##############
    # generate ROC
    
    $cmd = "$benchmark_toolkit_basedir/all_TP_FP_FN_to_ROC.pl $fusion_preds_file.scored > $fusion_preds_file.scored.ROC"; 
    $pipeliner->add_commands(new Command($cmd, "roc.ok"));
    
    # plot ROC
    $cmd = "$benchmark_toolkit_basedir/plotters/plot_ROC.Rscript $fusion_preds_file.scored.ROC";
    $pipeliner->add_commands(new Command($cmd, "plot_roc.ok"));

    ###################################
    # convert to Precision-Recall curve

    $cmd = "$benchmark_toolkit_basedir/calc_PR.py --in_ROC $fusion_preds_file.scored.ROC --out_PR $fusion_preds_file.scored.PR | sort -k2,2gr > $fusion_preds_file.scored.PR.AUC";
    $pipeliner->add_commands(new Command($cmd, "pr.ok"));

    # plot PR  curve
    $cmd = "$benchmark_toolkit_basedir/plotters/plotPRcurves.R $fusion_preds_file.scored.PR";
    $pipeliner->add_commands(new Command($cmd, "plot_pr.ok"));
    
    # plot AUC barplot
    $cmd = "$benchmark_toolkit_basedir/plotters/AUC_barplot.Rscript $fusion_preds_file.scored.PR.AUC";
    $pipeliner->add_commands(new Command($cmd, "plot_pr_auc_barplot.ok"));

    $pipeliner->run();

    
    chdir $basedir or die "Error, cannot cd back to $basedir";
        
    return;
        
}

