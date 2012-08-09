package Meepo::Clones;
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

	# Lazy load 
	eval "require Meepo::Clones::$clone" or return undef;

	while (my ($k, $v) = each %Meepo::Clones::) {
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
