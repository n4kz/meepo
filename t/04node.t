use strict;
use warnings;
use Test::More;
use Template::Meepo;
use JSON;

sub slurp ($) {
	my $data;

	{
		local $/;
		open my $file, '<', $_[0] or die $!;
		$data = readline $file;
		close $file;
	}

	chomp $data;

	return $data;
} # slurp

my $function = join '', readline DATA;
my $path = 't/run';

close DATA;

chdir $path or die $!;

my @tests = glob '0*.html';

plan skip_all => 'Variable $ENV{\'MEEPO_TEST_NODE\'} is not set'
	unless $ENV{'MEEPO_TEST_NODE'};

plan tests => 4 * @tests;

foreach my $output (@tests) {
	my $template = $output;
	my $data = $output;
	my ($code, $result);

	$template =~ s{html$} {tmpl};
	$template =~ s{^} {../compile/};
	$data =~ s{html$} {json};

	if (-f $data) {
		$data = from_json slurp $data;
	} else {
		$data = {};
	}

	$Template::Meepo::Clones::JavaScript::loop = 1
		if $template =~ m{020};

	$code = Template::Meepo::poof $template, { builder => 'JavaScript', inc => ['.'] };
	is $@, undef, "Template $template compiled";
	is ref $code, 'SCALAR';

	$code = sprintf $function, $$code, to_json $data, { pretty => 1 };

	my ($number) = ($template =~ m{(\d+)});

	my $script = join '.', $number, 'js';

	open my $fh, '>', $script or die $!;
	print $fh $code;
	close $fh;

	chomp($result = `node $script`);

	unlink $script;

	ok !$?, 'No error set';
	is $result, slurp $output, "Output matches expected for $template";

	$Template::Meepo::Clones::JavaScript::loop = 0
		if $Template::Meepo::Clones::JavaScript::loop;
}

__DATA__
console.log(%s(%s));
