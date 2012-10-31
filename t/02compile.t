use strict;
use warnings;
use Test::More;
use Template::Meepo;

my $path = 't/compile';

chdir $path or die $!;

my @tests = glob '0*.tmpl';

plan tests => 6 * @tests;

foreach my $builder (qw{ Perl JavaScript }) {
	foreach my $template (@tests) {
		my $ref = Template::Meepo::poof $template, { builder => $builder, inc => ['.'] };
		ok $ref, "Compiled template $template to $builder code";
		is ref $ref, 'SCALAR', 'Got template reference';
		is $@, undef, 'No error set';
	}
}
