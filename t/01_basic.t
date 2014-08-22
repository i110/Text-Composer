use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use Text::Composer qw(compose_text);

subtest 'Basic' => sub {
    test_composer('{{hoge}}',  'HOGE');
    test_composer('{{hoge}} {{fuga}}',  'HOGE FUGA');
    test_composer('{{unknown_key}}', '');
	is(compose_text('{{hoge}}', +{ hoge => 'HOGE' }), 'HOGE');
};

subtest 'Escape' => sub {
    test_composer('\\{\\{hoge\\}\\}', '{{hoge}}');
    test_composer('\\{\\{hoge}}', '{{hoge}}');
    test_composer('\\{{hoge}}', '\\{{hoge}}');
};

subtest 'Trim' => sub {
    test_composer('{{  hoge  }}', 'HOGE');
    test_composer('{{ ' . "\t\t\t" . ' hoge '. "\r\n\r\n" . ' }}', 'HOGE');
};

subtest 'Code Reference Parameter' => sub {
    test_composer('{{code1}}',  'CODE1(code1)');
    test_composer('{{code2}}',  'CODE2(CODE1(code1))');
};

subtest 'Code Reference Parameters' => sub {
    test_composer('{{code1}}',  'CODE1(code1)');
    test_composer('{{code2}}',  'CODE2(CODE1(code1))');
	is(compose_text('{{code3}}', sub {
		my ($composer, $key) = @_;
		uc($key);
	}), 'CODE3');
};

subtest 'Recursively' => sub {
    test_composer('{{foo}}',  'FOO(HOGE)');
    test_composer('{{hoge}} {{fuga}} {{foo}} {{bar}}',  'HOGE FUGA FOO(HOGE) BAR(FOO(HOGE))');
    test_composer('{{foo}}',  'FOO({{hoge}})', +{ recursive => 0 });
};

subtest 'Customized Symbols' => sub {
    my $opts = +{ start_symbol => '[', end_symbol => ']' };
    test_composer('[hoge]',  'HOGE', $opts);
    test_composer('\[  hoge  \]',  '[  hoge  ]', $opts);
};

subtest 'Exceptions' => sub {
    throws_ok {
        Text::Composer->new->compose('{{hoge}}', +{ hoge => [] });
    } qr{parameter must be a scalar or coderef};
    lives_ok {
        Text::Composer->new->compose('{{fuga}}', +{ hoge => [], fuga => 'nemui' });
    };
};

done_testing;

sub test_composer {
    my ($template, $expected, $opts) = @_;
    $opts ||= +{};
    my $composer = Text::Composer->new(%$opts);
    my $params = +{
        hoge => 'HOGE',
        fuga => 'FUGA',
        foo  => 'FOO({{hoge}})',
        bar  => 'BAR({{foo}})',
        code1 => sub { 'CODE1(' . $_[1] . ')' },
        code2 => sub { 'CODE2({{ code1 }})' },
    };
    is($composer->compose($template, $params), $expected);
}
