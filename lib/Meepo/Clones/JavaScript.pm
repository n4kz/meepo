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
function ($scope) {
	var $r = '',
		$s = (typeof $scope === 'function'? $s = $scope : $s = function ($) { return $scope[$] }),
		$w = function ($) {
			if ($ || $ === 0) {
				$r += $;
			}
		};

}

sub JavaScript_1 { <<''
	return $r; 
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
			JavaScript_4 join(JavaScript_expr(), '(', ' || []).forEach(function (l, i) {'),
			JavaScript_4 '	var $_ = $s,',
			JavaScript_4 '		$_s = function ($) { return l.hasOwnProperty($)? l[$] : $_($) };',
			JavaScript_4 '	$s = $_s;',
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
			return $Meepo::Clones::JavaScript::operators{$name}
				if exists $Meepo::Clones::JavaScript::operators{$name}; 
		}

	return join $name, '$s(\'', '\')' if $name;

	local $_ = $_->{'='}{'expr'}; 
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
	JavaScript_4 join JavaScript_expr(), '$w(', '($s));';
}

sub JavaScript_var {
	JavaScript_4 join JavaScript_expr(), '$w(', ');';
}

sub JavaScript_noop {
	my $chunk = $_->{'a'};
	$chunk =~ s{'} {\\'}g;
	$chunk =~ s{[\r\n]+} {' + '\\n' + '}g;
	$chunk =~ s{(?:(?<=</s)|(?<=<s))(?=cript>)} {' + '}g;
	JavaScript_4 join $chunk, '$w(\'', '\');';
}

1;
