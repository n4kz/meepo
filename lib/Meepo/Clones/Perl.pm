package Meepo::Clones::Perl;
package Meepo::Clones;
use strict;

sub Perl_0 { <<''
sub ($) {
	my @r;
	local our ($s) = @_;

}

sub Perl_1 { <<''
	return join '', @r;
}

}

sub Perl_2 ()  { '	' x ($_->{'#'} + 1) }
sub Perl_3 ()  { "\n" }
sub Perl_4 ($) { join $_[0], Perl_2, Perl_3 }

sub Perl_if {
	if ( $_->{'x'} ) {
		Perl_4 '}';
	} else {
		join '',
			Perl_4 join(Perl_expr(), 'if (', ') {'),
			build($_->{'+'});
	}
} # Perl_if

sub Perl_unless {
	if ( $_->{'x'} ) {
		Perl_4 '}';
	} else {
		join '',
			Perl_4 join(Perl_expr(), 'unless (', ') {'),
			build($_->{'+'});
	}
} # Perl_unless

sub Perl_loop {
	if ( $_->{'x'} ) {
		Perl_4 '}';
	} else {
		join '',
			Perl_4 join(Perl_expr(), 'foreach (@{', ' || []}) {'),
			Perl_4 'local $s = { %$s, %$_ };',
			build($_->{'+'});
	}
} # Perl_loop

sub Perl_else {
	join '',
		Perl_4 '} else {',
		build($_->{'+'});
} # Perl_else

sub Perl_elsif {
	join '',
		Perl_4 join(Perl_expr(), '} elsif (', ') {'),
		build($_->{'+'});
} # Perl_elsif

sub Perl_expr {
	my $name;
	unless ( $_[0] ) {
		$name = $_->{'='}{'name'};
	} else {
		$name = $_[0] || '';
		return $name if grep { $name eq $_ } qw{ not or and eq ne gt lt cmp };
	}

	return join $name, '$s->{\'', '\'}' if $name;

	local $_ = $_->{'='}{'expr'}; 
	my $k = 1;
	my $a = 0;

	{
		pos = $a;
		m{\G((?:[^'"]|(?<=\\)['"])*)(?:(?<!\\)(['"]).*?(?<!\\)\2)?}sgc;

		my $chunk = $1;
		my $l     = length $chunk;
		my $pos   = pos;

		$chunk =~ s{\b([a-z_]\w+)\b(?!\()} {Perl_expr($1)}gse;

		substr($_, $a, $l) = $chunk;
		$a = $pos + length($chunk) - $l;
		redo if $a < length;
	}

	return join $_, '(', ')';
} # Perl_expr

sub Perl_include {
	# dummy
}

sub Perl_var {
	Perl_4 join Perl_expr(), 'push @r, ', ' || \'\';';
}

sub Perl_noop {
	my $chunk = $_->{'a'};
	$chunk =~ s{'} {\\'}g;
	Perl_4 join $chunk, 'push @r, \'', '\';';
}

1;