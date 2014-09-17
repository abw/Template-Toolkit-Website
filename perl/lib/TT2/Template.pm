# subclass of Template module which pre-defines configuration values,
# variables, etc.

package TT2::Template;
use strict;
use warnings;
use base 'Template';
use YAML 'LoadFile';
use Path::Class;

our $VERSION = 0.01;

sub new {
    my $class  = shift;
    my $config = @_ && ref $_[0] eq 'HASH' ? shift : { @_ };
    $config->{ FILTERS } = {
        ttcode => \&ttcode,
    };
    my $tt = $class->SUPER::new($config);
    return $tt;
}

sub ttcode {
    my $text = shift;
    for ($text) {
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        s{(\[%.*?%\])}{<span class="tt">$1</span>}gs;
        s{^(%%.*)$}{<span class="tt">$1</span>}gm;
    }
    return "<pre class=\"tt\">\n$text\n</pre>\n";
}

1;
