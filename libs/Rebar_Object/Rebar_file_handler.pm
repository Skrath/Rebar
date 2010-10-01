#!/usr/bin/env perl

package Rebar_Object::Rebar_file_handler;

use warnings;
use strict;
use base qw( Rebar_Object );

sub read {
    my $self = shift;
    $self->{message}->post(qq[@_], qq[Rebar_Template], 4);
    return 0 unless $self->{data}{name};
    
    if ($self->{data}{cache}{$self->{data}{name}}) {
        $self->{message}->post(qq[cache], qq[Rebar_Template], 4);
        return $self->{data}{cache}->{$self->{data}{name}};
    }
    
    open my $file, '<', $self->{data}{name} or die "Couldn't open $self->{data}{name}";
    local $/ = undef;
    my $str = <$file>;
    close $file;
    $self->{data}{cache}->{$self->{data}{name}} = $str;
    $self->{data}{contents} = $str;
    return 1;
}

1;