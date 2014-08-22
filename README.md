# NAME

Text::Composer - Handy Text Builder with Parameters and Logics

# SYNOPSIS

    use Text::Composer;
    my $composer = Text::Composer->new(
        start_symbol => '{{',
        end_symbol => '}}',
        recursive => 1,
    );

    say $composer->compose('My name is {{ name }}', +{ name => 'i110' });
    # 'My name is i110'

    say $composer->compose('My name is {{ name }}', +{
        name => '{{prefix}} i110',
        prefix => 'Mr.',
    });
    # 'My name is Mr. i110'

    say $composer->compose('\{\{ escaped \}\} key will not be expanded', +{
        escaped => 'gununu',
    });
    # '{{ escaped }} key will not be expanded'

    say $composer->compose('{{ with_complicated_logic }}', +{
        with_complicated_logic => sub {
            my ($self, $key) = @_;
            "This text was composed $key by {{ twitter_id }}";
        },
        twitter_id => sub {
            '@{{ user_name }}';
        },
        user_name => 'i110',
    });
    # 'This text was composed with_complicated_logic by @i110'
    
    use Text::Composer qw(compose_text);
    compose_text('{{without_oo_interface}}', +{ without_oo_interface => 'hakadoru' });
    # 'hakadoru'

# METHODS

- __new ( %args )__
    - `$recursive`

        Expand parameters recursively. Default is true.

    - `$start_symbol`
    - `$end_symbol`

        Delimiters for parameters. Defaults are '{{' and '}}', respectively.
- __compose ( $template, \\%params )__

    Compose rext using a template and parameters.

    - `$template`

        Parameterized text. Required.

    - `\%params`

        Parameters which will be rendered in the template.
        Hash's values must be a scalar or coderef, otherwise it will throw an exception.
        Coderef takes two arguments, Text::Composer instance itself and the accessing key.

# LICENSE

Copyright (C) Ichito Nagata.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Ichito Nagata <i.nagata110@gmail.com>
