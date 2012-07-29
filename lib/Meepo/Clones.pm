package Meepo::Clones;
use strict 'vars', 'subs';
use vars '$clone';

sub build ($) {
	join '', map {
		(
			join '_', $clone, $_->{'_'}
		)->();
	} @{ $_[0] };
} # build

sub spawn ($$) {
	local $clone = $_[1];

	# Lazy load 
	eval "require Meepo::Clones::$clone" or return undef;

	return
		join build $_[0],
			map {
				$_->();
			} map {
				join '_', $clone, $_
			} qw{ 0 1 }
} # spawn

1;
