package Template::Docs::Plugin::Badger;

use strict;
use warnings;
use Template::Plugin;
use base 'Template::Plugin';

our @badger_quotes = (
    "Hello, I'm a talking badger.",
    "My name is <i>Meles Meles</i>, but you can call me \"Badger\".",
    "You can't go %s.  Would you like to come foraging for nuts and berries in the forest with me instead?",
    "I'm sorry Dave, I can't do that.",
    "I'd love to help you go %s but I can't.  I'm just a badger.",
    "You can't go %s.  It exists in a different dimension and I left the keys at home.",
    "Yeah right, I bet you've love to go %s, but you can't.",
    "No, you can't go %s.  You're silly to even think that you could.",
    "Since when did going %s become so important?",
    "Help!  I'm stuck on this web page and I can't get off.  Please don't go %s, help me!",
    "You may think I look cute and cuddly, but I've got a fiery temper.",
    "Are you looking at my nuts?  I spent ages foraging for them.  Hands off!",
    "If you are going %s, be sure to wear some flowers in your hair...",
    "Have you seen my skateboard?  I left it around here somewhere...",
    "Go %s?  Are you mad?",
);
our $last = 0;

sub new {
    my ($class, $context) = @_;
    bless { }, $class;
}

sub quote {
    my ($self, $where) = @_;
    my $format = $badger_quotes[$last];
    $where = 'to the next page'
        if $where eq 'next';
    $last++;
    $last %= @badger_quotes;
    return sprintf($format, $where);
}

1;

    