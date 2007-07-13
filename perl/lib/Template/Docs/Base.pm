#========================================================================
#
# Template::Docs::Base
#
# DESCRIPTION
#   Wrapper around Template::Base which provides some additional 
#   functionality that I've come to know and love (and will be 
#   appearing in TT3).
#
# AUTHOR
#   Andy Wardley   <abw@wardley.org>
#
# COPYRIGHT
#   Copyright (C) 1996-2006 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#========================================================================

package Template::Docs::Base;

use strict;
use warnings;
use base 'Template::Base';
use Template::Exception;

our $VERSION   = 0.01;
our $DEBUG     = 0;
our $MESSAGES  = {
    not_found    => '%s not found: %s',
    not_found_in => '%s not found in %s',
};
our $EXCEPTION = 'Template::Exception';


#------------------------------------------------------------------------
# pkgvar($name, $default, $all)
#
# Looks for the scalar package variable named by the first argument
# (no leading '$') in the current package, accounting for subclassing,
# returning the $default value if not found.  The third argument is 
# a flag which can be set true to return a list of all variables found 
# (and also the default, if defined, returned as the last item).  
# Otherwise the first instance found is returned.
#------------------------------------------------------------------------

sub pkgvar {
    my ($self, $name, $default, $all) = @_;
    my $class = ref $self || $self;
    my @pending = ($class);
    my ($pkg, $value, %seen, @got);

    no strict 'refs';

    while ($pkg = shift @pending) {
        $self->debug("looking for $name in $pkg\n") if $DEBUG;
        # iterate through each package in @pending looking for a
        # package variable named $name, skipping any packages we've
        # already seen and adding all base class packages (@ISA) to
        # @pending.  if all have been asked for, we push any found 
        # onto a list, otherwise we return the first we find.
        next if $seen{ $pkg }++;
        if (defined ($value = ${"$pkg\::$name"})) {
            if ($all) {
                push(@got, $value);
            }
            else {
                return $value;
            }
        }
        push(@pending, @{"$pkg\::ISA"});
    }

    # if we got here then we either wanted all variables or we 
    # wanted one, but didn't find any

    if ($all) {
        # add any default to the (possibly empty) list and return it
        push(@got, $default) if $default;
        return @got;
    }
    else {
        # otherwise return the default, if there is one
        return $default;
    }
}


#------------------------------------------------------------------------
# pkgvars($name, $default)
#
# Wrapper around pkgvar() with sets the third option true to return all
# package variables of a particular name in this and all super classes.
#------------------------------------------------------------------------

sub pkgvars {
    my ($self, $name, $default) = @_;
    return $self->pkgvar($name, $default, 1);
}


#------------------------------------------------------------------------
# pkghash($name, $item, $default)
#
# Wrapper around pkgvars() for fetching an $item from a hash reference
# defined in a package variable of the given $name.
#------------------------------------------------------------------------

sub pkghash {
    my ($self, $name, $item, $default) = @_;

    foreach my $hash ($self->pkgvars($name)) {
        next unless ref $hash eq 'HASH';
        return $hash->{ $item }
            if defined $hash->{ $item };
    }

    return $default if defined $default;
    return $self->decline("$name.$item not found in \$$name" );
}


#------------------------------------------------------------------------
# message($name, @args)
#
# Uses pkghash() to find a message format defined in the $MESSAGES hash 
# array in this package or any of the object's base classes.  It then
# passes the format through sprintf(), applying any additional arguments.
#------------------------------------------------------------------------

sub message {
    my ($self, $name, @args) = @_;

    my $format = $self->pkghash( MESSAGES => $name )
        || $self->fatal("message() called with invalid message type: $name");
    
    return sprintf($format, @args);
}


#------------------------------------------------------------------------
# error()
# error($msg1, $msg2, $msg3, ...)
#
# General purpose error reporting method.  Throws an error when called 
# with one or more error strings (multiple values are concatenated).
# Returns current error when called without args.  Can be called as 
# a class method, Template::Docs::BlahBlah->error() and as an object method,
# $hvblah->error().
#------------------------------------------------------------------------

sub error {
    my $self  = shift;
    my $class = ref $self || $self;
    no strict 'refs';

    if (@_) {
        # don't stringify objects passed as argument
        my $error = ref $_[0] ? shift : join('', map { defined($_) ? $_ : '' } @_);
        my $throw = $self->pkgvar('THROW') || $class->module_name();

        # set package variable
        ${"$class\::ERROR"} = $error;
        ${"$class\::DECLINED"} = 0;

        if (ref $self) {
            # set error and declined items if $self is an object
            $self->{ ERROR    } = $error;
            $self->{ DECLINED } = 0;
        }
        
        $self->throw($throw, $error);
    }
    elsif (ref $self) {
        # return current value of object's error
        return $self->{ ERROR };
    }
    else {
        # return current value of class error
        return ${"$class\::ERROR"};
    }
}


#------------------------------------------------------------------------
# error_msg($code, @args)
#
# Calls error() having first passed argument through message()
#------------------------------------------------------------------------

sub error_msg {
    my $self = shift;
    $self->error($self->message(@_));
}


#------------------------------------------------------------------------
# throw($error, @args)
#
# This method throws an exception object by calling die(). 
#------------------------------------------------------------------------

sub throw {
    my ($self, $type, $info, @args) = @_;
    my $etype = $self->pkgvar( EXCEPTION => $EXCEPTION );
    die $etype->new( $type, $info );
}


#------------------------------------------------------------------------
# decline($reason, $more_reasons, ...)
# 
# General purpose method used to decline a request of some kind.  Joins
# all the arguments into a single string and stores it in the internal 
# ERROR item to be accessed via the error() method.  Also sets the 
# internal DECLINED flag and then returns undef.
#------------------------------------------------------------------------

sub decline {
    my $self   = shift;
    my $class  = ref $self || $self;
    my $reason = join('', @_);
    no strict 'refs';

    # set package variables
    ${"$class\::ERROR"} = $reason;
    ${"$class\::DECLINED"} = 1;

    if (ref $self) {
        $self->{ ERROR    } = $reason;
        $self->{ DECLINED } = 1;
    }

    return undef;
}


#------------------------------------------------------------------------
# decline_msg()
# 
# Like error_msg(), this calls message() to format the arguments and
# passes the result onto decline()
#------------------------------------------------------------------------

sub decline_msg {
    my $self = shift;
    $self->decline($self->message(@_));
}


#------------------------------------------------------------------------
# declined()
#
# Returns the value of DECLINED, set by decline().
#------------------------------------------------------------------------

sub declined {
    my $self = shift;

    if (ref $self) {
        return $_[0]->{ DECLINED };
    }
    else {
        no strict 'refs';
        my $class = ref $self || $self;
        return ${"$class\::DECLINED"};
    }
}


#------------------------------------------------------------------------
# debug($msg)
#
# Debugging method which prints argument to STDERR with a prefix 
# indicating the package name of the object which raised the message.
#------------------------------------------------------------------------

sub debug {
    my $self = shift;
    my $msg  = join('', @_);
    my ($pkg, $file, $line) = caller();
    
    print STDERR "[$pkg] $msg";
}


#------------------------------------------------------------------------
# fatal($msg)
#
# Generate a fatal error message.
#------------------------------------------------------------------------

sub fatal {
    my $self  = shift;
    my $class = ref $self || $self;
    my $error = join('', @_);
    no strict 'refs';

    # set package variable
    ${"$class\::ERROR"} = $error;

    if (ref $self) {
        $self->{ ERROR } = $error;
        $self->{ DECLINED } = 0;
    }

    require Carp;
    Carp::confess("fatal error: ", @_);
}


#------------------------------------------------------------------------
# module_name()
#
# Return a lower case version of the last part of the module name.
# e.g. Hostvue::Thingy => thingy
#------------------------------------------------------------------------

sub module_name {
    my $self  = shift;
    my $class = ref $self || $self;
    if ($class =~ /::([^:]*)$/) {
        $class = $1;
    }
    return lc $class;
}


1;

__END__

=head1 NAME

Template::Docs::Base - base class module

=head1 SYNOPSIS

    package Template::Docs::Pod::HTML;
    use base 'Template::Docs::Base';

=head1 DESCRIPTION

This module implements a base class for the Template::Docs modules.
It's a wrapper around L<Template::Base> which adds some new methods and
improves upon some of the existing ones.  In fact it's very similar to 
the Template::Base that will be appearing in TT3.

=head1 AUTHOR

Andy Wardley E<lt>abw@wardley.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2005-2006 Andy Wardley.  All Rights Reserved.

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
