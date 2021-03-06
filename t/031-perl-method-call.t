#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny ();

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTML::MasonX::Critic');
    use_ok('HTML::MasonX::Critic::Inspector::Query::PerlCode');
}

my $MASON_FILE_NAME = '031-perl-method-call.html';
my $COMP_ROOT       = Path::Tiny->tempdir;

$COMP_ROOT->child( $MASON_FILE_NAME )->spew(q[
<%init>
$a->comp( 'foo/bar' => 10 );
$b->property( 'baz' );
$c->this()->is->a_method_call;
</%init>
]);

subtest '... simple compiler test using perl blocks and queries' => sub {

    my $i = HTML::MasonX::Critic::Inspector->new( comp_root => $COMP_ROOT );
    isa_ok($i, 'HTML::MasonX::Critic::Inspector');

    my $state = $i->compile_path( $MASON_FILE_NAME );
    isa_ok($state, 'HTML::MasonX::Critic::Inspector::CompiledPath');

    my $comp = $state->root_component;
    isa_ok($comp, 'HTML::MasonX::Critic::Inspector::Compiled::Component');

    is($comp->name, $MASON_FILE_NAME, '... got the expected name');

    my $blocks = $comp->blocks;
    isa_ok($blocks, 'HTML::MasonX::Critic::Inspector::Compiled::Component::Blocks');

    ok(!$blocks->has_once_blocks, '... we do not have once blocks');
    ok($blocks->has_init_blocks, '... we have init blocks');
    ok(!$blocks->has_filter_blocks, '... we do not have filter blocks');
    ok(!$blocks->has_shared_blocks, '... we do not have shared blocks');
    ok(!$blocks->has_cleanup_blocks, '... we do not have cleanup blocks');

    subtest '... testing the init block' => sub {

        my ($init) = @{ $blocks->init_blocks };
        isa_ok($init, 'HTML::MasonX::Critic::Inspector::Compiled::Component::PerlCode');

        subtest '... testing the method call without a name' => sub {

            my @method_calls = HTML::MasonX::Critic::Inspector::Query::PerlCode->find_method_calls( $init );
            is(scalar(@method_calls), 5, '... got the 5 calls');

            is($method_calls[0]->name, 'comp', '... got the name we expected');
            is($method_calls[0]->line_number, 3, '... got the line_number we expected');
            is($method_calls[0]->column_number, 5, '... got the column_number we expected');
            is($method_calls[0]->find_invocant->name, '$a', '... got the expected invocant name');
            ok(!$method_calls[0]->find_invocant->is_virtual, '... got the expected virtual-ness');

            is($method_calls[1]->name, 'property', '... got the name we expected');
            is($method_calls[1]->line_number, 4, '... got the line_number we expected');
            is($method_calls[1]->column_number, 5, '... got the column_number we expected');
            is($method_calls[1]->find_invocant->name, '$b', '... got the expected invocant name');
            ok(!$method_calls[1]->find_invocant->is_virtual, '... got the expected virtual-ness');

            is($method_calls[2]->name, 'this', '... got the name we expected');
            is($method_calls[2]->line_number, 5, '... got the line_number we expected');
            is($method_calls[2]->column_number, 5, '... got the column_number we expected');
            is($method_calls[2]->find_invocant->name, '$c', '... got the expected invocant name');
            ok(!$method_calls[2]->find_invocant->is_virtual, '... got the expected virtual-ness');

            is($method_calls[3]->name, 'is', '... got the name we expected');
            is($method_calls[3]->line_number, 5, '... got the line_number we expected');
            is($method_calls[3]->column_number, 13, '... got the column_number we expected');
            is($method_calls[3]->find_invocant->name, 'this', '... got the expected invocant name');
            ok($method_calls[3]->find_invocant->is_virtual, '... got the expected virtual-ness');

            is($method_calls[4]->name, 'a_method_call', '... got the name we expected');
            is($method_calls[4]->line_number, 5, '... got the line_number we expected');
            is($method_calls[4]->column_number, 17, '... got the column_number we expected');
            is($method_calls[4]->find_invocant->name, 'is', '... got the expected invocant name');
            ok($method_calls[4]->find_invocant->is_virtual, '... got the expected virtual-ness');
        };

        subtest '... testing the method call with a name' => sub {

            my @method_calls = HTML::MasonX::Critic::Inspector::Query::PerlCode->find_method_calls(
                $init, ( method_name => 'comp' )
            );
            is(scalar(@method_calls), 1, '... got the one `comp` call');

            is($method_calls[0]->name, 'comp', '... got the name we expected');
            is($method_calls[0]->line_number, 3, '... got the line_number we expected');
            is($method_calls[0]->column_number, 5, '... got the column_number we expected');
            is($method_calls[0]->find_invocant->name, '$a', '... got the expected invocant name');
            ok(!$method_calls[0]->find_invocant->is_virtual, '... got the expected virtual-ness');
        };

        subtest '... testing the method call with a name and invocant' => sub {

            my @method_calls = HTML::MasonX::Critic::Inspector::Query::PerlCode->find_method_calls(
                $init, (
                    invocant_name => '$b',
                    method_name   => 'property',
                )
            );
            is(scalar(@method_calls), 1, '... got the one `property` call on the `$b` invocant');

            is($method_calls[0]->name, 'property', '... got the name we expected');
            is($method_calls[0]->line_number, 4, '... got the line_number we expected');
            is($method_calls[0]->column_number, 5, '... got the column_number we expected');
            is($method_calls[0]->find_invocant->name, '$b', '... got the expected invocant name');
            ok(!$method_calls[0]->find_invocant->is_virtual, '... got the expected virtual-ness');
        };
    };

};

done_testing;

