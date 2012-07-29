package Meepo::Clones::JavaScript;
use vars qw{ %operators };

%operators = (
	not   => '!',
	or    => '||',
	and   => '&&',
	eq    => '==',
	ne    => '!=',
	gt    => '>',
	lt    => '<',
	ge    => '>=',
	le    => '<=',
	cmp   => '!=',
	'<=>' => '!=',
);

package Meepo::Clones;
use strict;

sub JavaScript_0 { <<''
function ($s) {
	var $r=[];

}

sub JavaScript_1 { <<''
	return $r.join(''); 
}

}

sub JavaScript_2 ()  { '	' x ($_->{'#'} + 1) }
sub JavaScript_3 ()  { "\n" }
sub JavaScript_4 ($) { join $_[0], JavaScript_2, JavaScript_3 }

sub JavaScript_if {
	if ( $_->{'x'} ) {
		JavaScript_4 '}';
	} else {
		join '',
			JavaScript_4 join(JavaScript_expr(), 'if (', ') {'),
			build($_->{'+'});
	}
} # JavaScript_if

sub JavaScript_unless {
	if ( $_->{'x'} ) {
		JavaScript_4 '}';
	} else {
		join '',
			JavaScript_4 join(JavaScript_expr(), 'if (!', ') {'),
			build($_->{'+'});
	}
} # JavaScript_unless

sub JavaScript_loop {
	if ( $_->{'x'} ) {
		JavaScript_4 '});';
	} else {
		join '',
			JavaScript_4 join(
				JavaScript_expr(), 
				'jQuery.each(',
				' || [], function ($index, $value) {'
			),
			JavaScript_4 '	var $s = jQuery.extend({}, $s, $value);',
			build($_->{'+'});
	}
} # JavaScript_loop

sub JavaScript_else {
	join '',
		JavaScript_4 '} else {',
		build($_->{'+'});
} # JavaScript_else

sub JavaScript_elsif {
	join '',
		JavaScript_4 join(JavaScript_expr(), '} else if (', ') {'),
		build($_->{'+'});
} # JavaScript_elsif

sub JavaScript_expr {
	my $name;
		unless ( $_[0] ) {
			$name = $_->{'='}{'name'};
		} else {
			$name = $_[0] || '';
			# TODO: fix operators
			return $Meepo::Clones::JavaScript::operators{$name} if grep { $name eq $_ } qw{ not or and eq ne gt lt le ge cmp };
		}

	return join $name, '$s[\'', '\']' if $name;

	local $_ = $_->{'='}{'expr'}; 
	my $k = 1;
	my $a = 0;

	{
		pos = $a;
		m{\G((?:[^'"]|(?<=\\)['"])*)(?:(?<!\\)(['"]).*?(?<!\\)\2)?}sgc;

		my $chunk = $1;
		my $l     = length $chunk;
		my $pos   = pos;

		$chunk =~ s{\b([a-z_]\w+)\b(?!\()} {JavaScript_expr($1)}gse;

		substr($_, $a, $l) = $chunk;
		$a = $pos + length($chunk) - $l;
		redo if $a < length;
	}

	return join $_, '(', ')';
} # JavaScript_expr

sub JavaScript_include {
	# TODO: rewrite this
	JavaScript_4 join JavaScript_expr(), '$r.push(', '($s));';
}

sub JavaScript_var {
	JavaScript_4 join JavaScript_expr(), '$r.push(', ' || \'\');';
}

sub JavaScript_noop {
	my $chunk = $_->{'a'};
	$chunk =~ s{'} {\\'}g;
	$chunk =~ s{[\r\n]} {' + "\\n" + '}g;
	$chunk =~ s{(</?s)(cript>)} {$1' + '$2}g;
	JavaScript_4 join $chunk, '$r.push(\'', '\');';
}

1;
