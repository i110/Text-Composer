package Text::Composer;
use 5.008001;
use strict;
use warnings;
use Carp;

use parent qw(Exporter);
our @EXPORT_OK = qw(compose_text);

our $VERSION = "0.01";

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        recursive => 1,
        start_symbol => '{{',
        end_symbol => '}}',
        %args,
        _patterns => +{},
    }, $class;
    $self->_update_patterns('start_symbol');
    $self->_update_patterns('end_symbol');
    return $self;
}

sub recursive {
    my $self = shift;
    if (@_) {
        $self->{recursive} = shift;
    }
    return $self->{recursive};
}

sub start_symbol {
    my $self = shift;
    $self->_symbol('start_symbol', @_);
}

sub end_symbol {
    my $self = shift;
    $self->_symbol('end_symbol', @_);
}

sub _symbol {
    my $self = shift;
    my $field = shift;
    if (@_) {
        $self->{$field} = shift;
        $self->_update_patterns($field);
    }
    return $self->{$field};
}

sub _update_patterns {
    my ($self, $field) = @_;

    my $symbol = $self->{$field};
    my $search_pattern = qr{(?<!\\)\Q$symbol\E};
    (my $escaped_symbol = $symbol) =~ s/(.)/'\\' . $1/ge;
    my $unescape_pattern = qr{\Q$escaped_symbol\E};

    $self->{_patterns}->{$field} = +{
        search => $search_pattern,
        unescape => $unescape_pattern,
    };
}

sub compose {
    my ($self, $template, $params) = @_;

    my $start_search_pattern = $self->{_patterns}->{start_symbol}->{search};
    my $end_search_pattern   = $self->{_patterns}->{end_symbol}->{search};
    my $result = $template;
    $result =~ s!
        $start_search_pattern
        (.+?)
        $end_search_pattern
    !
        my $key = $1;
        $key =~ s/\A\s*(.*?)\s*\z/$1/g;
        my $param = $params->{$key} || '';

        while (ref($param)) {
            croak 'parameter must be a scalar or coderef' unless ref($param) eq 'CODE';
            $param = $param->($self, $key) || '';
        }

        if ($self->recursive) {
            $param = $self->compose($param, $params);
        }
        $param;
    !gsex;

    my $start_unescape_pattern = $self->{_patterns}->{start_symbol}->{unescape};
    my $end_unescape_pattern   = $self->{_patterns}->{end_symbol}->{unescape};
    $result =~ s/$start_unescape_pattern/$self->start_symbol/gse;
    $result =~ s/$end_unescape_pattern/$self->end_symbol/gse;

    return $result;
}

sub compose_text {
    my ($template, $params, $opts) = @_;
    __PACKAGE__->new(%$opts)->compose($template, $params);
}

1;
__END__

=encoding utf-8

=head1 NAME

Text::Composer - Handy Text Builder with Parameters and Logics

=head1 SYNOPSIS

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

=head1 METHODS

=over

=item B<new ( %args )>

=over

=item * C<$recursive>

Expand parameters recursively. Default is true.

=item * C<$start_symbol>

=item * C<$end_symbol>

Delimiters for parameters. Defaults are '{{' and '}}', respectively.

=back

=item B<compose ( $template, \%params )>

Compose rext using a template and parameters.

=over

=item * C<$template>

Parameterized text. Required.

=item * C<\%params>

Parameters which will be rendered in the template.
Hash's values must be a scalar or coderef, otherwise it will throw an exception.
Coderef takes two arguments, Text::Composer instance itself and the accessing key.

=back

=back

=head1 LICENSE

Copyright (C) Ichito Nagata.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ichito Nagata E<lt>i.nagata110@gmail.comE<gt>

=cut

