#!/usr/bin/env perl

package Rebar_Object::Rebar_url_parser;

use warnings;
use strict;
use URI::Escape;
use base qw( Rebar_Object );

sub process() {
    my $self = shift;
    $self->{message}->post(qq[], qq[Rebar_Object], 4);
    return unless $self->{data}{url};
    
    $self->{data}{parsed} = [ map { uri_escape($_) } @{ [ split m!/! => $self->{data}{url} ] } ];
    
    return 1;
}

1;