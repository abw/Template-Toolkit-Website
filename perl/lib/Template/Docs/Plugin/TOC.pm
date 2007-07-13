package Template::Docs::Plugin::TOC;

use strict;
use warnings;
use base 'Template::Plugin';

our $VERSION = 0.01;

sub new {
    my ($class, $context, $html) = @_;
    my $self = bless {
        html => $html,
        toc  => [ ],
    };
    my $name;

    $self->{ html } =~ s{ 
        (<h([123])\s*(.*?)>)  # start tag
        (.*?)           # content
        (</h\2>)        # end tag
    }{ 
        $self->tic($2, $3, $4);
    }gex;

    return $self;
}

sub tic {
    my ($self, $level, $attr, $text) = @_;
    my ($id, $name, $last, $kids);
    my $toc = $self->{ toc };

    if ($attr =~ /id="(.*?)"/) {
        $id = $1;
    }

#    print STDERR "TIC $level $text\n";
    if ($level == 1 || ! @$toc) {
        $name = $id || "section_" . scalar(@$toc);
        push(@$toc, {
            text => $text,
            link => $name,
            kids => [ ],
        });
    }
    elsif ($level == 2) {
        $last = $toc->[-1];
        $kids = $last->{kids};
        $name = $id || $last->{link} . '_' . scalar(@$kids);
        push(@$kids, {
            text => $text,
            link => $name,
        });
    }
    else {
        $last = $toc->[-1];
        $kids = $last->{kids} || [ ];
        $last = $kids->[-1]   ||= { };
        $kids = $last->{kids} ||= [ ];
        $name = $id || $last->{link} . '_' . scalar(@$kids);
        push(@$kids, {
            text => $text,
            link => $name,
        });
    }

    unless ($id) {
        $attr .= ' ' if length $attr;
        $attr .= "id=\"$name\"";
    }
    
    return "<h$level $attr>$text</h$level>";
}

sub old_toc {
    return $_[0]->{toc};
}

sub old_html {
    return $_[0]->{html};
}


1;

__END__

=head1 NAME

Template::Docs::Plugin::TOC - generate a table of contents from h1, h2 and h3 tags

=head1 SYNOPSIS

  [% USE ht = HTML::TOC(html) %]

  [% ht.html %]     # modified HTML

  [% ht.toc  %]     # table of contents list

=head1 DESCRIPTION

Template::Docs::Plugin::TOC is a Template Toolkit plugin for
generating tables of contents for HTML documents.  It scans the HTML
source for E<lt>h1E<gt> and E<lt>h2E<gt> tags and constructs a data
structure representing the table of contents.

=head1 AUTHOR

Andy Wardley E<lt>abw@wardley.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 20062-2007 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
