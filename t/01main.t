use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
	use_ok 'Template::Meepo::Clones::Perl';
	use_ok 'Template::Meepo::Clones::JavaScript';
	use_ok 'Template::Meepo';
}

subtest Context => sub {
	is ref $Template::Meepo::context, 'HASH',
		'Context variable';

	is ref $Template::Meepo::context->{'inc'}, 'ARRAY',
		'Include path';

	ok scalar @{ $Template::Meepo::context->{'inc'} } == 0,
		'Empty path';

	is $Template::Meepo::context->{'builder'}, 'Perl',
		'Default builder';

	ok $Template::Meepo::context->{'chomp'},
		'Chomp is set';

	ok keys %$Template::Meepo::context == 3,
		'Context keys count';
};

subtest 'Load' => sub {
	subtest 'Single argument' => sub {
		subtest 'Local context' => sub {
			local $Template::Meepo::context->{'inc'} = ['t/compile'];
			is ref Template::Meepo::poof('001.tmpl'), 'SCALAR',
				'Inc set';

			ok !$@,
				'No errors';
		};

		subtest 'Default context' => sub {
			is Template::Meepo::poof('001.tmpl'), undef,
				'Inc not set';

			ok $@,
				'Error set';

			like $@, qr{File '001.tmpl' was not found},
				'Error text';
		};

		is ref Template::Meepo::poof('inlineTemplate'), 'SCALAR',
			'Inline template';

		ok !$@,
			'No errors';
	};

	subtest 'Two arguments' => sub {
		is ref Template::Meepo::poof('001.tmpl', { inc => ['t/compile'] }), 'SCALAR',
			'Inc set';

		ok !$@,
			'No errors';

		subtest 'Local context' => sub {
			local $Template::Meepo::context->{'inc'} = ['../'];
			is ref Template::Meepo::poof('001.tmpl', { inc => ['t/compile'] }), 'SCALAR',
				'Inc set';

			ok !$@,
				'No errors';
		};

		is Template::Meepo::poof('001.tmpl', {}), undef,
			'Inc not set';

		ok $@,
			'Error set';

		like $@, qr{File '001.tmpl' was not found},
			'Error text';

		is ref Template::Meepo::poof('inlineTemplate', {}), 'SCALAR',
			'Inline template';

		ok !$@,
			'No errors';
	};

	subtest 'Object notation' => sub {
		is ref Template::Meepo->poof({
			source => '001.tmpl',
			inc => ['t/compile'],
		}), 'SCALAR',
			'Inc set';

		ok !$@,
			'No errors';

		subtest 'Local context' => sub {
			local $Template::Meepo::context->{'inc'} = ['t/notexists'];
			is ref Template::Meepo->poof({
				source => '001.tmpl',
				inc => ['t/compile'],
			}), 'SCALAR',
				'Inc set';

			ok !$@,
				'No errors';

			is +(Template::Meepo->poof({ source => '001.tmpl' })), undef,
				'Inc not set';

			ok $@,
				'Error set';

			like $@, qr{File '001.tmpl' was not found},
				'Error text';
		};

		is +(Template::Meepo->poof({ source => '001.tmpl' })), undef,
			'Inc not set';

		ok $@,
			'Error set';

		like $@, qr{File '001.tmpl' was not found},
			'Error text';
	};
};
