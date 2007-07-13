package Template::Docs::Plugin::Metadata;

use strict;
use warnings;
use Template::Plugin;
use base 'Template::Plugin';
use YAML 'LoadFile';
use Path::Class;
our $VERSION = 0.01;
our $METADATA;

sub new {
    my ($class, $context) = @_;
    return $METADATA ||= $class->metadata($context);
}

sub metadata {
    my ($class, $context) = @_;
    my $root  = $context->stash->get('rootdir') || die 'No root directory specified';
    my $meta  = dir($root)->subdir('metadata');
    my $docs  = $meta->subdir('docs');

    # first load the regular pages and sections
    my $pages = LoadFile($meta->file('pages.yaml'));
    my $sects = LoadFile($meta->file('sections.yaml'));
    
    # now the pages and sections in the docs
    my $dpages = LoadFile($docs->file('pages.yaml'));
    my $dsects = LoadFile($docs->file('sections.yaml'));

    # now compose them together and define template vars
    return {
        pages    => { %$pages, %$dpages },
        sections => { %$sects, %$dsects },
        modules  => LoadFile($docs->file('modules.yaml')),
    }
}

1;

    