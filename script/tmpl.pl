#!/usr/bin/perl -w 
use strict;
use Cwd;
use File::Basename;
use lib join('/../', dirname($0), 'lib');
use Meepo;
use Meepo::Clones::Perl;
use Meepo::Clones::JavaScript;

my $usage = <<"";
Usage: $0 <builder> <template>

@ARGV == 2 or print $usage and exit;

my $builder = $ARGV[0];

my $f = Meepo::poof(
	$ARGV[1] => {
		builder => $builder,
		inc => [cwd()],
	}
);

die $@ if $@; 

local $\ = "\n";
$f and print $$f;
