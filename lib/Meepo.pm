package Meepo;
use strict;
use File::Basename;
use Meepo::Tags;
use Meepo::Clones;
use vars qw{ $prefix $space $context $preview $VERSION };

$VERSION = '0.01';

$preview = 30;
$prefix = 'tmpl_';
$space = qr{[\s\t\n\r]};
$context = {
	inc => [],
	sub => {
		include  => \&include,
	},
	hooks => 1,
	builder => 'Perl'
};

sub scream ($;$) {
	my ($what, $at) = @_;

	if ( $at ) {
		my $start = $at - $preview;
		$start = 0 if $start < 0;
		my $part = substr $_, $start, $preview * 2; 
		substr $part, $at - $start, 0, '<< HERE >>';
		$what = join $\ || ' ', $what, $part;
	}

	$@ ||= $what;
	return undef;
}

sub hook ($) {
	local $_ = $_[0];
	my $hook = $context->{'sub'}{$_->{'_'}};

	return $hook->() if
		ref $hook and ref $hook eq 'CODE';

	return $_;
} # hook

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

			return scream join($node->{'_'}, 'Open tag not found for ', ''), $node->{'>'} + 1
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
	my (@queue, $attrs);
	my @tags = keys %Meepo::Tags::tags;

	WORK: foreach (@_) {
		my $start = pos || 0;
		if ( m{\G(.*?)<(/)?$prefix([\w:-]+)(?(2)>)}iosgc ) {
			push @queue, hook {
				'_' => 'noop',
				'<' => $start,
				'>' => $start + length $1,
				'a' => $1,
				'#' => 0,
			} if $1;
		} else {
			my $chunk = substr $_, $start;
			push @queue, hook {
				'_' => 'noop',
				'<' => $start,
				'>' => $start + length $chunk,
				'a' => $chunk,
				'#' => 0,
			};
			last WORK;
		}

		my $name = lc $3;
		my $closed = $2;
		my $tag = $Meepo::Tags::tags{$name};

		$attrs = {};

		return scream "Unknown tag '$name'", pos
			unless $tag;

		return scream "Tag '$name' can not be closed", $start
			if $closed and not $tag->{'pair'};

		if ( not $closed and grep { $tag->{$_} } qw{ name attrs }) {
			my ($parsed, @list) = {};

			$parsed->{lc $1} = $3 while m{\G$space*([\w:_-]+)(?:=(['"])(.*?)(?<!\\)\2)?}osgc;

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
			if not $closed and not m{\G$space*/?>}osgc;

		push @queue, hook {
			'_' => $name,
			'x' => $closed? 1 : 0,
			'=' => $attrs,
			'%' => $tag,
			'<' => $start,
			'#' => 0,
			'>' => pos() - 1,
		};

		redo WORK if pos() < length() - 1;
	} # WORK

	$@ ||= prepare \@queue unless $context->{'raw'};
	$@ and return undef;

	return \@queue;
} # parse

sub load ($) {
	my ($source) = @_;
	foreach (reverse @{ $context->{'inc'} }) {
		foreach (join '/', $_, $$source) {
			-f $_ and do {
				my $fh;
				local $/;
				open $fh, $_;
				$$source = <$fh>;
				close $fh;
				return $_;
			};
		}
	}

	$@ ||= "File '". $$source ."' was not found";
	return undef;
} # load

sub include () {
	my $source = $_->{'='}{'name'};
	local $context->{'raw'} = 1;

	if ( exists $_->{'='}{'inline'} and $source ) {
		# Inline includes 
		if ( my $path = dirname(load(\$source)) ) {
			local $context->{'inc'} = [$path, @{  $context->{'inc'} }]
				unless grep { $path eq $_ } @{ $context->{'inc'} };

			return @{ parse $source };
		}
	} else {
		# Run-time includes are handled by clones themselves
	}

	return $_;
} # include

sub poof ($;$) {
	my ($source) = @_;
	local $Meepo::context = {
		%$Meepo::context,
		%{ $_[1] || {} },
	};

	undef $@;

	{
		return undef
			if $@ or not $source or ref $source;

		# Try to get $source from context if source looks like package
		if ( $source eq __PACKAGE__ ) {
			$source = delete $Meepo::context->{'source'};
			redo;
		}

		# Try to load file if $source looks like filepath
		if ( $source =~ m{(?:\A\.?\.?/|\.tmpl\Z)}i ) {
			my $path = dirname(load(\$source));
			if ( $path ) {
				local $context->{'inc'} = [$path, @{  $context->{'inc'} }]
					unless grep { $path eq $_ } @{ $context->{'inc'} };
			} else {
				redo;
			}
		}
	}

	no  warnings 'redefine';
	local *hook = sub { $_[0] } unless $context->{'hooks'};
	use warnings 'redefine';

	my $result = parse $source;
	$@ and return undef;

	return Meepo::Clones::spawn $result, $Meepo::context->{'builder'};
} # poof

1;
