package Template::Docs::Plugin::Undent;

use strict;
use warnings;
use base 'Template::Plugin';

sub new {
    my ($class, $context) = @_;
    $context->define_filter( undent => \&undent_filter_factory, 1 );
    return '';
}

sub undent_filter_factory {
    my ($context, @args) = @_;
    my $params = pop(@args) || { };
    my $tag    = $params->{ tag } || 'pre';
    my $depth  = shift(@args) || 0;

    return sub {
        my $text = shift;
        $text =~ s{ (<$tag.*?>)(.*?)(<\/$tag>) }
                  { $1 . undent($2, $depth) . $3 }sexg;
        return $text;
    }
}

sub undent {
    my $text = shift;
    my (@lines, $line, $length, $min);


    for ($text) {
        s/\t/    /g;
        s/^ *\n//;
        s/(\n *)*$//;
        @lines = split(/\n/);
    }

    # some arbitrarily large number
    $min = 100;

    foreach (@lines) {
        chomp;
        next if s/^\s+$//;
        /^(\s*)/;
        $length = length $1;
        $min = $length if $length < $min;
    }

    if ($min) {
        foreach (@lines) {
            s/^ {$min}//mg;
        }
    }

    $text = join("\n", @lines);
    return $text;
}

1;


