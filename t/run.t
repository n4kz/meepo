use strict;
use warnings;
use Test::More;
use Template::Meepo;
use JSON;

sub slurp ($) {
	my $data;

	{
		local $/;
		open my $file, '<', $_[0] or die $@;
		$data = readline $file;
		close $file;
	}

	chomp $data;

	return $data;
} # slurp

my $path = 't/run';

chdir $path or die $!;

my @tests = glob '0*.html';

plan tests => 6 * @tests;

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

	$code = Template::Meepo::poof $template, { builder => 'Perl', inc => ['.'] };
	is $@, undef, "Template $template compiled";
	is ref $code, 'SCALAR';

	$code = eval $$code;

	ok !$@, 'No error set';
	is ref $code, 'CODE', 'Function compiled';

	$result = $code->($data);

	is ref $result, 'SCALAR', "Got output as expected for $template";
	is $$result, slurp $output, "Output matches expected for $template";
}
