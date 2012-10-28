package Template::Meepo 3;
use strict;
use File::Basename;
use Template::Meepo::Tags;
use Template::Meepo::Clones;
use vars qw{ $context $preview };

$preview = 30;
$context = {
	inc => [],
	builder => 'Perl',
	chomp => 1,
};

sub scream ($;$) {
	my ($what, $at) = @_;

	if ( $at ) {
		my $source = $_? \$_ : $context->{'source'};
		my $start = $at - $preview;
		my $end = $preview;
		my $length = length($$source);

		$end = $length - $at if $length < $at + $end;
		$start = 0 if $start < 0;

		my $left = substr $$source, $start, $at - $start; 
		my $right = substr $$source, $at, $end;

		$what = join $\ || ' ', $what, join '<< HERE >>', $left, $right;
	}

	$@ ||= $what;
	return undef;
}

sub in ($$) { grep { $_ eq $_[1]->{'_'} } @{ $_[0]->{'%'}{'in'} } }

sub prepare ($) {
	my ($queue) = @_;
	my (@scope, $cursor, $node, $tag, $parent);

	for ($cursor = 0; $cursor < @$queue; $cursor++) {
		$node = $queue->[$cursor];
		$parent = $scope[-1];

		unless ( $node->{'%'} ) {
			if ( $parent ) {
				push @{ $parent->{'+'} ||= [] }, $node;
				splice @$queue, $cursor, 1;
				$cursor--;
				$node->{'#'} = @scope;
			}

			next;
		}
  
		$tag = $node->{'%'};

		# Check scope
		if ( $parent ) {
			if ( $node->{'x'} ) {
				return scream "Open tag mismatch", $node->{'>'} + 1
					if $node->{'_'} ne $parent->{'_'} and not in $parent, $node;

				pop @scope if $tag->{'pair'};
				$node->{'#'} = @scope;

				if ( @scope ) {
					push @{ $scope[-1]{'+'} ||= [] }, $node;

					splice @$queue, $cursor, 1;
					$cursor--;
				}
			} else {
				if ( $tag->{'in'} ) {
					return scream "Parent tag mismatch", $node->{'>'} + 1
						if not in $node, $parent;

					pop @scope;
					$node->{'#'} = @scope;

					if ( @scope ) {
						push @{ $scope[-1]{'+'} ||= [] }, $node;

						splice @$queue, $cursor, 1;
						$cursor--;
					}

					push @scope, $node;
				} else {
					$node->{'#'} = @scope;

					push @{ $parent->{'+'} ||= [] }, $node;
					push @scope, $node if $tag->{'pair'};

					splice @$queue, $cursor, 1;
					$cursor--;
				}
			}
		} else {
			return scream "Parent tag not found", $node->{'>'} + 1
				if $tag->{'in'};

			return scream join($node->{'_'}, "Open tag not found for '", "'"), $node->{'>'} + 1
				if $node->{'x'};

			$node->{'#'} = @scope;
			push @scope, $node if $tag->{'pair'};
		}
	}

	return scream join($_->{'_'}, "Unmatched tag '", "'"), $scope[-1]->{'>'} + 1
		foreach reverse @scope;

	return undef;
} # prepare

sub parse ($) {
	my @queue;
	local $context->{'source'} = $_[0];

	WORK: foreach (${ $_[0] }) {
		my $start = pos || 0;
		my $trail = substr $_, $start
			unless m{\G(.*?)<(/)?tmpl_([\w:-]+)(?(2)>)}isgc;

		push @queue, {
			'_' => 'noop',
			'<' => $start,
			'>' => $start + length,
			'a' => $_,
			'#' => 0,
		} foreach grep defined, $1 || $trail;

		last WORK if $trail;

		my ($name, $closed, $attrs) = (lc $3, $2, {});
		my $tag = $Template::Meepo::Tags::tags{$name};

		return scream "Unknown tag '$name'", pos
			unless $tag;

		return scream "Tag '$name' can not be closed", $start
			if $closed and not $tag->{'pair'};

		if ( not $closed and $tag->{'name'} || $tag->{'attrs'} ) {
			my ($parsed, @list) = {};

			# TODO: Allow case sensitive attrs
			# like <TMPL_VAR MyVariable>
			# case <TMPL_VAR EXPR="MyVariable"> seems to be ok
			$parsed->{lc $1} = $3 while m{\G[\s\t\n\r]*([\w:_-]+)(?:=(['"])(.*?)(?<!\\)\2)?}sgc;

			# Name 
			if ( $tag->{'name'} ) {
				$attrs->{'name'} = delete $parsed->{'name'}
					if exists $parsed->{'name'};

				unless ( $tag->{'expr'} and exists $parsed->{'expr'} ) {{
					last if exists $attrs->{'name'};

					@list = grep { not defined $parsed->{$_} } keys %$parsed;

					if ( not exists $parsed->{'name'} and @list ) {
						$attrs->{'name'} = shift @list;
						delete $parsed->{$attrs->{'name'}};

						return scream "Too many boolean attributes", pos
							if @list;
					} else {
						return scream "Name attr expected but not found", pos;
					}
				}} else {
					return scream "Unexpected attr 'name'", pos
						if exists $parsed->{'name'};
				}

				# Special case, variable $name
				$attrs->{'name'} = 'name'
					if exists $attrs->{'name'} and not $attrs->{'name'};

				return scream "Name attr is empty", pos
					unless $attrs->{'name'} or $tag->{'expr'};
			}

			# Expr
			if ( $tag->{'expr'} ) {
				$attrs->{'expr'} = delete $parsed->{'expr'};
			} else {
				return scream "Unexpected expr attr", pos
					if exists $parsed->{'expr'};
			}

			# Remaining attrs
			foreach my $attr (keys %$parsed) {
				return scream join($attr, "Unexpected attr '", "'"), pos
					unless exists $tag->{'attrs'}{$attr};

				if ( defined ($attrs->{$attr} = delete $parsed->{$attr}) ) {
					return scream join($attr, "Unexpected value for boolean attr '", "'"), pos
						 if $tag->{'attrs'}{$attr}{'boolean'};
				} else {
					return scream join($attr, "Value for attr '", "' expected, but not found"), pos
						 unless $tag->{'attrs'}{$attr}{'boolean'};
				}
			}

			foreach my $attr (keys %{ $tag->{'attrs'} }) {
				return scream join($attr, "Attribute '", "' expected but not found"), pos
					unless exists $attrs->{$attr} or $tag->{'attrs'}{$attr}{'optional'};
			}
		}

		return scream "Unexpected trail", pos
			if not $closed and not m{\G[\s\t\n\r]*/?>}sgc;

		push @queue, $name eq 'include'? include() : $_ foreach {
			'_' => $name,
			'x' => $closed? 1 : 0,
			'=' => $attrs,
			'%' => $tag,
			'<' => $start,
			'#' => 0,
			'>' => pos() - 1,
		};

		redo WORK if not $@ and pos() < length() - 1;
	} # WORK

	$@ ||= prepare \@queue unless $context->{'raw'};

	return undef if $@;
	return \@queue;
} # parse

sub load ($) {
	foreach (map { join '/', $_, ${ $_[0] } } reverse @{ $context->{'inc'} }) {
		-f $_ or next;

		{
			local $/;
			open my $fh, '<', $_;
			${ $_[0] } = readline $fh;
			close $fh;
		}

		chomp ${ $_[0] } if $context->{'chomp'};
		return $_;
	}

	$@ ||= join ${ $_[0] }, "File '", "' was not found";
	return undef;
} # load

sub include () {
	my $source = $_->{'='}{'name'};
	local $context->{'raw'} = 1;

	# Inline includes
	# Run-time includes are handled by clones themselves
	if ( $context->{'inline'} || exists $_->{'='}{'inline'} and $source ) {{
		my $path = dirname(local $context->{'file'} = load \$source);
		last if $@;

		local $context->{'inc'} = [$path, @{  $context->{'inc'} }]
			unless grep { $path eq $_ } @{ $context->{'inc'} };

		my $tree = parse \$source;
		return $tree? @$tree : ();
	}}

	return $_;
} # include

sub poof ($;$) {
	my ($source) = @_;
	local $context = {
		%$context, %{ $_[1] || {} },
	};

	undef $@;
	undef $context->{'file'};

	{
		return undef
			if $@ or not $source or ref $source;

		# Try to get $source from context if source looks like package
		if ( $source eq __PACKAGE__ ) {
			$source = delete $Template::Meepo::context->{'source'};
			redo;
		}

		# Try to load file if $source looks like filepath
		if ( $source =~ m{(?:\A\.?\.?/|\.tmpl\Z)}i ) {
			redo unless $context->{'file'} = load \$source;

			# Prepend template directory to search path
			my $path = dirname $context->{'file'};
			local $context->{'inc'} = [$path, @{  $context->{'inc'} }]
				unless grep { $path eq $_ } @{ $context->{'inc'} };
		}
	}

	my $result = parse \$source;

	# TODO: Option to return parsing tree
	return undef if $@;
	return Template::Meepo::Clones::spawn $result, $Template::Meepo::context->{'builder'};
} # poof

1;
