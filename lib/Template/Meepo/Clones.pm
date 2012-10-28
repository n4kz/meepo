package Template::Meepo::Clones;
use Template::Meepo::Clones::Perl;
use Template::Meepo::Clones::JavaScript;
use strict 'vars', 'subs';
use vars '$clone', '%cbs';

sub build ($) {
	map {
		$cbs{$_->{'_'}}->();
	} @{ $_[0] };
} # build

sub spawn ($$) {
	my $prefix = 1 + length $_[1];
	local $clone = $_[1];
	local %cbs;

	while (my ($k, $v) = each %Template::Meepo::Clones::) {
		next if index $k, $clone;
		next if $v eq '::';
		$cbs{substr $k, $prefix} = $v;
	}

	return \join '',
		$cbs{'0'}->(),
		build $_[0],
		$cbs{'1'}->();
} # spawn

1;
