#!/usr/bin/env perl

package Rebar_Object::Rebar_find_file;

use warnings;
use strict;
use URI::Escape;
use base qw( Rebar_Object );

sub setup() {
    my $self = shift;
    $self->{message}->post(qq[], qq[Rebar_Object], 4);
    
    if ($ENV{SCRIPT_FILENAME}) {
        $self->{data}{basedir} = $ENV{SCRIPT_FILENAME};
        $self->{data}{basedir} =~ s!^(.+)/.*$!$1!;
    } else {
        use Env;
        $self->{data}{basedir} = $ENV{PWD};
    }
    
    return 1;
}

sub process() {
    my $self = shift;
    $self->{message}->post(qq[], qq[Rebar_Object], 4);
    
    $self->{data}{searchdir} = $self->{data}{basedir} . '/' . $self->{data}{location};	
    #$self->{data}{templateurl} = $self->{data}{baseurl} . '/' . $self->{data}{folder};
    
    my $try_directory;
    my $verified;
    
    foreach (@{$self->{data}{parameters}}) {
        if ($verified) {
            push @{$self->{data}{extra}}, $_;
            next;
        }
        # this builds a directory structure out of the path elements
        $try_directory .= '/' . $_;
        
        next if $verified = $self->check_file($self->{data}{searchdir} . $try_directory); # check the element by itself
        next if $verified = $self->check_extensions($self->{data}{searchdir} . $try_directory); # check the element with defined extensions
    }
    
    # Store all of the path variables if no template can be found, just in case
    $self->{data}{extra} = [@{$self->{data}{parameters}}] unless $verified;
    
    if (!$self->{data}{include}) {
        # Default template page (usually index)
        $verified = $self->check_extensions($self->{data}{searchdir} . '/' . $self->{data}{default}) if !$verified and (@{$self->{data}{parameters}}==0);
        
        # Find that error page
        $verified = $self->check_extensions($self->{data}{searchdir} . '/' . $self->{data}{error}) unless $verified; 
    }
    
    #return $verified or 0;
    $self->{data}{file} = $verified if $verified;
    
    return 1;
}

sub check_extensions($) {
    my $self = shift;
    $self->{message}->post(qq[@_], qq[Rebar_Template], 4);
    my $check = shift || return 0;
    my $try;
    
    foreach (@{$self->{data}{extensions}}) {
        $try = $check . '.' . $_;
        return $try if $try = $self->check_file($check . '.' . $_);
    }
}

sub check_file($) {
    my $self = shift;
    $self->{message}->post(qq[@_], qq[Rebar_Template], 4);
    
    return $_[0] if ((-e $_[0]) && !(-d $_[0])) || 0;
}

1;