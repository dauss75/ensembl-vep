# Copyright [2016] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use Getopt::Long;
use FindBin qw($RealBin);
use lib $RealBin;
use lib $RealBin.'/modules';
use Bio::EnsEMBL::VEP::Runner;

my $config = {};

my $arg_count = scalar @ARGV;
my @argv_copy = @ARGV;

GetOptions(
  $config,
  'help',                    # displays help message
  
  # input options,
  'config=s',                # config file name
  'input_file|i=s',          # input file name
  'format=s',                # input file format
  'output_format=s',         # output file format
  'delimiter=s',             # delimiter between fields in input
  
  # DB options
  'species=s',               # species e.g. human, homo_sapiens
  'registry=s',              # registry file
  'host=s',                  # database host
  'port=s',                  # database port
  'user|u=s',                  # database user name
  'password=s',              # database password
  'db_version=i',            # Ensembl database version to use e.g. 62
  'assembly|a=s',            # assembly version to use
  'genomes',                 # automatically sets DB params for e!Genomes
  'refseq',                  # use otherfeatures RefSeq DB instead of Ensembl
  'merged',                  # use merged cache
  'all_refseq',              # report consequences on all transcripts in RefSeq cache, includes CCDS, EST etc
  'gencode_basic',           # limit to using just GenCode basic transcript set
  'is_multispecies=i',       # '1' for a multispecies database (e.g protists_euglenozoa1_collection_core_29_82_1)

  # runtime options
  'transcript_filter=s',     # filter transcripts
  'minimal',                 # convert input alleles to minimal representation
  'most_severe',             # only return most severe consequence
  'summary',                 # only return one line per variation with all consquence types
  'pick',                    # used defined criteria to return most severe line
  'pick_allele',             # choose one con per allele
  'per_gene',                # choose one con per gene
  'pick_allele_gene',        # choose one con per gene, allele
  'flag_pick',               # flag one con per line
  'flag_pick_allele',        # flag one con per allele
  'flag_pick_allele_gene',   # flag one con per gene, allele
  'pick_order=s',            # define the order of categories used by the --*pick* flags
  'buffer_size=i',           # number of variations to read in before analysis
  'failed=i',                # include failed variations when finding existing
  'gp',                      # read coords from GP part of INFO column in VCF (probably only relevant to 1KG)
  'chr=s',                   # analyse only these chromosomes, e.g. 1-5,10,MT
  'check_ref',               # check supplied reference allele against DB
  'check_existing',          # find existing co-located variations
  'check_svs',               # find overlapping structural variations
  'no_check_alleles',        # attribute co-located regardless of alleles
  'check_alleles',           # DEPRECATED
  'check_frequency',         # enable frequency checking
  'gmaf',                    # DEPRECATED: USE af
  'maf_1kg',                 # DEPRECATED: USE af_1kg
  'maf_esp',                 # DEPRECATED: USE af_esp
  'maf_exac',                # DEPRECATED: USE af_exac
  'af',                      # add global AF of existing var
  'af_1kg',                  # add 1KG AFs of existing vars
  'af_esp',                  # add ESP AFs of existing vars
  'af_exac',                 # add ExAC AFs of existing vars
  'old_maf',                 # report 1KG/ESP MAFs in the old way (no allele, always < 0.5)
  'pubmed',                  # add Pubmed IDs for publications that cite existing vars
  'freq_filter=s',           # exclude or include
  'freq_freq=f',             # frequency to filter on
  'freq_gt_lt=s',            # gt or lt (greater than or less than)
  'freq_pop=s',              # population to filter on
  'filter_common',           # shortcut to MAF filtering
  'allow_non_variant',       # allow non-variant VCF lines through
  'process_ref_homs',        # force processing of individuals with homozygous ref genotype
  'individual=s',            # give results by genotype for individuals
  'phased',                  # force VCF genotypes to be interpreted as phased
  'fork=i',                  # fork into N processes
  'dont_skip',               # don't skip vars that fail validation
  
  # verbosity options
  'verbose|v',               # print out a bit more info while running
  'quiet',                   # print nothing to STDOUT (unless using -o stdout)
  'no_progress',             # don't display progress bars
  
  # output options
  'everything|e',            # switch on EVERYTHING :-)
  'output_file|o=s',         # output file name
  'html',                    # DEPRECATED: generate an HTML version of output
  'stats_file|sf=s',         # stats file name
  'stats_text',              # write stats as text
  'stats_html',              # write stats as html
  'no_stats',                # don't write stats file
  'warning_file=s',          # file to write warnings to
  'force_overwrite',         # force overwrite of output file if already exists
  'terms|t=s',               # consequence terms to use e.g. NCBI, SO
  'coding_only',             # only return results for consequences in coding regions
  'canonical',               # indicates if transcript is canonical
  'tsl',                     # output transcript support level
  'appris',                  # output APPRIS transcript annotation
  'ccds',                    # output CCDS identifer
  'xref_refseq',             # output refseq mrna xref
  'uniprot',                 # output Uniprot identifiers (includes UniParc)
  'protein',                 # add e! protein ID to extra column
  'biotype',                 # add biotype of transcript to output
  'hgnc',                    # add HGNC gene ID to extra column
  'symbol',                  # add gene symbol (e.g. HGNC)
  'gene_phenotype',          # indicate if genes are phenotype-associated
  'hgvs',                    # add HGVS names to extra column
  'shift_hgvs=i',            # disable/enable 3-prime shifting of HGVS indels to comply with standard
  'sift=s',                  # SIFT predictions
  'polyphen=s',              # PolyPhen predictions
  'humdiv',                  # use humDiv instead of humVar for PolyPhen
  'condel=s',                # Condel predictions
  'variant_class',           # get SO variant type
  'regulatory',              # enable regulatory stuff
  'cell_type=s' => ($config->{cell_type} ||= []),             # filter cell types for regfeats
  'convert=s',               # DEPRECATED: convert input to another format (doesn't run VEP)
  'no_intergenic',           # don't print out INTERGENIC consequences
  'gvf',                     # DEPRECATED: produce gvf output
  'vcf',                     # produce vcf output
  'solr',                    # produce XML output for Solr
  'json',                    # produce JSON document output
  'tab',                     # produce tabulated output
  'vcf_info_field=s',        # allow user to change VCF info field name
  'keep_csq',                # don't nuke existing CSQ fields in VCF
  'keep_ann',                # synonym for keep_csq
  'no_consequences',         # don't calculate consequences
  'lrg',                     # enable LRG-based features
  'fields=s',                # define your own output fields
  'domains',                 # output overlapping protein features
  'numbers',                 # include exon and intron numbers
  'total_length',            # give total length alongside positions e.g. 14/203
  'allele_number',           # indicate allele by number to avoid confusion with VCF conversions
  'no_escape',               # don't percent-escape HGVS strings
  
  # cache stuff
  'database',                # must specify this to use DB now
  'cache',                   # use cache
  'cache_version=i',         # specify a different cache version
  'show_cache_info',         # print cache info and quit
  'dir=s',                   # dir where cache is found (defaults to $HOME/.vep/)
  'dir_cache=s',             # specific directory for cache
  'dir_plugins=s',           # specific directory for plugins
  'offline',                 # offline mode uses minimal set of modules installed in same dir, no DB connection
  'custom=s' => ($config->{custom} ||= []), # specify custom tabixed bgzipped file with annotation
  'tmpdir=s',                # tmp dir used for BigWig retrieval
  'gff=s',                   # shortcut to --custom [file],,gff
  'gtf=s',                   # shortcut to --custom [file],,gtf
  'plugin=s' => ($config->{plugin} ||= []), # specify a method in a module in the plugins directory
  'safe',                    # die if plugins don't compile or spit warnings
  'fasta|fa=s',              # file or dir containing FASTA files with reference sequence
  'sereal',                  # user Sereal instead of Storable for the cache
  'synonyms=s',              # file of chromosome synonyms
  
  # debug
  'debug',                   # print out debug info
) or die "ERROR: Failed to parse command-line flags\n";

&usage && exit(0) if (!$arg_count) || $config->{help};

$config->{database} ||= 0;

my $runner = Bio::EnsEMBL::VEP::Runner->new($config);

if($config->{show_cache_info}) {
  my $info = $runner->get_output_header_info->{version_data};
  print "$_\t$info->{$_}\n" for keys %$info;
  exit(0);
}


$runner->run();



# outputs usage message
sub usage {
    my $usage =<<END;
#----------------------------------#
# ENSEMBL VARIANT EFFECT PREDICTOR #
#----------------------------------#

version $VERSION
by Will McLaren (wm2\@ebi.ac.uk)

Help: dev\@ensembl.org , helpdesk\@ensembl.org
Twitter: \@ensembl , \@EnsemblWill

http://www.ensembl.org/info/docs/tools/vep/script/index.html

Usage:
perl vep.pl [--cache|--offline|--database] [arguments]

Basic options
=============

--help                 Display this message and quit

-i | --input_file      Input file
-o | --output_file     Output file
--force_overwrite      Force overwriting of output file
--species [species]    Species to use [default: "human"]
                       
--everything           Shortcut switch to turn on commonly used options. See web
                       documentation for details [default: off]                       
--fork [num_forks]     Use forking to improve script runtime

For full option documentation see:
http://www.ensembl.org/info/docs/tools/vep/script/vep_options.html

END

    print $usage;
}


1;