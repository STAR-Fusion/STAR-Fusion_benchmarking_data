#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 repo_basedir\n";

my $basedir = $ARGV[0] or die $usage;

chdir $basedir or die "Error, cannot cd to $basedir";

# make the dir structure
my @dirs = ("sim", "cell_lines", "runtimes");
foreach my $dir (@dirs) {
    unless (-d $dir) {
        &process_cmd("mkdir -p figs_for_paper/$dir");
    }
}

my @targets_and_dests = ( 

    # simulated data figs
    
    ["simulated_data/allow_rev.combined.pdf", "figs_for_paper/sim/sim50_vs_101.boxplots.pdf"],
    
    ["simulated_data/sim_101/__analyze_allow_reverse/all.scored.sensitivity_vs_expr.dat.genes_vs_samples_heatmap.pdf",
     "figs_for_paper/sim_101.sens_vs_expr.heatmap.pdf"],
    
    ["simulated_data/sim_101/__analyze_allow_rev_and_paralogs/all.scored.ROC.best.dat.before_vs_after.pdf",
     "figs_for_paper/sim/sim101.before_vs_after_paraEquiv.pdf"],

    ["simulated_data/sim_50/__analyze_allow_rev_and_paralogs/all.scored.ROC.best.dat.before_vs_after.pdf",
     "figs_for_paper/sim50.before_vs_after_paraEquiv.pdf"],

    # cancer cell lines

    ["cancer_cell_lines/__min_4_agree/min_4.ignoreUnsure.results.scored.PR.AUC.barplot.pdf",
     "figs_for_paper/cell_lines/min_4.ignoreUnsure.PR_AUC_barplot.pdf"],

    ["cancer_cell_lines/__min_4_agree/min_4.ignoreUnsure.results.scored.PR.plot.pdf",
     "figs_for_paper/cell_lines/min_4.ignoreUnsure.PR_curve.pdf"],

    ["cancer_cell_lines/__min_4_agree/min_4.ignoreUnsure.results.scored.ROC.ROC_plot.pdf",
     "figs_for_paper/cell_lines/min_4.ignoreUnsure.misc_accuracy_plots.pdf"],

    ["cancer_cell_lines/all.auc.dat.pdf", "figs_for_paper/cell_lines/min_4.accuracy_scoring_collage.pdf"],


    # runtime analysis
    ["runtime_analysis/all_progs_cancer/runtimes.txt.boxplot.pdf", "figs_for_paper/runtimes/cell_line_runtimes.boxplot.pdf"],
    
    ["runtime_analysis/STAR_F_multicore/runtimes.txt.boxplot.pdf", "figs_for_paper/runtimes/StarF_multithread_runtimes.boxplot.pdf"]
    

    );


foreach my $target_and_dest (@targets_and_dests) {

    my ($from, $to) = @$target_and_dest;

    &process_cmd("cp $from $to");

}

exit(0);

####
sub process_cmd {
    my ($cmd) = @_;

    print "CMD: $cmd\n";
    my $ret = system($cmd);
    if ($ret) {
        die "Error, CMD: $cmd died with ret $ret";
    }
}

