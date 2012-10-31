#!/usr/bin/perl -w 
use strict;
use Cwd;
use File::Basename;
use Template::Meepo;
use HTML::Template::Pro;
use Benchmark;
use JSON;

die $@ if $@; 

local $\ = "\n";

my ($data, $template);

{
	local $/;

	open my $fh, '<', $ARGV[1] || 'comments.json' or die $!;
	$data = readline $fh;
	close $fh;

	open $fh, '<', $ARGV[0] || 'template.tmpl' or die $!;
	$template = readline $fh;
	close $fh;
}

$data = from_json($data);

my $pro = HTML::Template::Pro->new(
	case_sensitive => 1,
	loop_context_vars => 1,
	global_vars => 1,
	scalarref => $template,
	functions => {
		ml => \&ml,
	}
);

my $f = Template::Meepo::poof($template) or die $@;
$f = eval $$f or die $@;

my $params = {
	show_comments => 1,
	allow_commenting => 1,
	render => 1,
	tree => $data,
};

timethese($ARGV[2] || 50, {
	Meepo => sub {
		$f->($params);
	},

	'HTML::Template::Pro' => sub {
		$pro->clear_params();
		$pro->param($params);
		my $test = $pro->output();
	},
});

sub ml {''}
