use strict;
use warnings;
use Test::More;
use Template::Meepo;

my $path = 't/compile';

chdir $path or die $!;

my @tests = glob '0*.tmpl';

plan tests => 12 * @tests;

my $stop;

TEST: {
	foreach my $builder (qw{ Perl JavaScript }) {
		foreach my $template (@tests) {
			my $ref = Template::Meepo::poof $template, { builder => $builder, inc => ['.'] };
			ok $ref, "Compiled template $template to $builder code";
			is ref $ref, 'SCALAR', 'Got template reference';
			is $@, undef, 'No error set';
		}
	}

	last if $stop;
	$Template::Meepo::Clones::Perl::loop = 1;
	$Template::Meepo::Clones::JavaScript::loop = 1;
	$stop = 1;
	redo;
} # TEST
