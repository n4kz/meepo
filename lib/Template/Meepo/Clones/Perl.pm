package Template::Meepo::Clones::Perl;
use vars qw{ %reserved $loop %operators };

$loop = 0; # Expand special loop variables or not

%reserved = (
	__first__   => '!$i',
	__last__    => '($i == $l)',
	__inner__   => '($i && $i < $l)',
	__odd__     => '($i % 2)',
	__even__    => '!($i % 2)',
	__counter__ => '$i',
);

%operators = map { $_ => 1 } qw{ not or and eq ne gt lt ge le cmp };

package Template::Meepo::Clones;
use strict;

sub Perl_0 { <<''
sub {
	no warnings;
	my $scope = $_[0];
	my $s = sub { $scope->{$_[0]} };
	my ($b, $i, $l);
	my $r = '';

}

sub Perl_1 { <<''
	return \$r;
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
		(
			$Template::Meepo::Clones::Perl::loop? (
				Perl_4 '	$i++;'
			) : (),
			Perl_4 '}'
		);
	} else {
		join '',
			$Template::Meepo::Clones::Perl::loop? (
				Perl_4 join(Perl_expr(), 'my $loop = ', ' || [];'),
				Perl_4 'my ($l, $i) = ($#$loop, 0);',
				Perl_4 'foreach my $e (@$loop) {',
			) : (
				Perl_4 join(Perl_expr(), 'foreach my $e (@{', '|| []}) {'),
			),
			Perl_4 '	my $s = sub { exists $e->{$_[0]}? $e->{$_[0]} : &$s };',
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
		return $name if $Template::Meepo::Clones::Perl::operators{$name};
	}

	# Special case <TMPL_IF 0>
	return $name if $name and $name =~ m{^[01]$};

	# Reserved name
	return $Template::Meepo::Clones::Perl::reserved{$name} || join $name, '$s->(\'', '\')' if $name;

	local $_ = $_->{'='}{'expr'};
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
	my $default = $_->{'='}{'default'};

	if ( $default ) {
		# Default value for tmpl_var
		# TODO: Escape quotes wisely
		$default =~ s{'} {\\'}g;
		Perl_4 join Perl_expr(), '$r .= defined($b = (', "))? \$b : '$default';";
	} else {
		Perl_4 join Perl_expr(), '$r .= ', ';';
	}
}

sub Perl_noop {
	my $chunk = $_->{'a'};
	$chunk =~ s{'} {\\'}g;
	Perl_4 join $chunk, '$r .= \'', '\';';
}

1;
