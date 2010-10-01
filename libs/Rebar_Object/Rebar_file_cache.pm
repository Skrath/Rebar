#!/usr/bin/env perl

package Rebar_Object::Rebar_file_cache;

use warnings;
use strict;
use base qw( Rebar_Object );

sub setup() {
    my $self = shift;
    $self->{message}->post(qq[], qq[Rebar_Object], 4);
 
    $self->{data}{return} = qq[output];   
    return 1;
}

sub process() {
    my $self = shift;
    $self->{message}->post(qq[], qq[Rebar_Object], 4);
    return 0 unless $self->{data}{name};
    
    if ($self->{data}{content}) {
        $self->{data}{cache}{$self->{data}{name}} = $self->{data}{content};
    }
    
    if ($self->{data}{cache}{$self->{data}{name}}) {
        $self->{data}{output} = $self->{data}{cache}{$self->{data}{name}};
    }
    
    $self->{data}{content} = $self->{data}{name} = undef;
    
    return 1;
}

1;