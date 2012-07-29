package Meepo::Tags;
use strict;
use vars '%tags';

%tags = (
    var => {
        expr   => 1,
        name   => 1,
    },

    include => {
        expr   => 1,
        name   => 1,
        attrs  => {
            inline => {
                optional => 1,
                boolean  => 1,
            },
        },
    },

    if => {
        expr   => 1,
        name   => 1,
        pair => 1,
    },

    unless => {
        expr   => 1,
        name   => 1,
        pair   => 1,
    },

    else => {
        in     => [qw{ if unless elsif }],
    },

    elsif => {
        expr   => 1,
        name   => 1,
        in     => [qw{ if unless elsif }],
    },

    loop => {
        pair   => 1,
        scope  => 1,
        name   => 1,
    },
);

1;
