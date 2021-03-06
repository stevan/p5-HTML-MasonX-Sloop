#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny ();

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTML::MasonX::Critic');
}

my $MASON_FILE = '040-perl-critic-object-code.t';
my $COMP_ROOT  = Path::Tiny->tempdir;

$COMP_ROOT->child( $MASON_FILE )->spew(q[
<%args>
$greeting => undef
</%args>
<%once>
use Scalar::Util ();
</%once>
<%init>
my $test;
$greeting ||= 'World';
</%init>
<h1>Hello <% $greeting %></h1>
<%cleanup>
$greeting = undef;
</%cleanup>
]);

subtest '... simple perl-cricit query test' => sub {

    my $critic = HTML::MasonX::Critic->new(
        comp_root => $COMP_ROOT,
        config    => {
            perl_critic_policy => 'Variables::ProhibitUnusedVariables'
        }
    );
    isa_ok($critic, 'HTML::MasonX::Critic');

    my @violations = $critic->critique( $MASON_FILE );
    is(scalar @violations, 1, '... got one violation');

    my ($v) = @violations;
    is($v->policy, 'Perl::Critic::Policy::Variables::ProhibitUnusedVariables', '... got the expected policy name');
    is($v->logical_line_number, 9, '... got the expected line number');
    is($v->column_number, 1, '... got the expected column number');
    is($v->source, 'my $test;', '... got the expected source');
};

done_testing;

