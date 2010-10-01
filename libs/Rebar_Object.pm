#!/usr/bin/env perl

package Rebar_Object;

use warnings;
use strict;

require 'Config.pl';

sub new($;@) {
    my $class = shift;
    $_[0]->isa('Rebar_Message') or return 0;
    my $self = bless {
                        message    => shift,
                        data       => {
                                        @_
                                    },                
                      } => ( $class or ref $class );
    $self->{message}->post(qq[], qq[Rebar_Object], 4);
    
    $self->load_config() if $self->{data}{config};
    $self->setup();
    #$self->create_getters_and_setters(__PACKAGE__, INFO->{$self->{model}}{class_members});

    return $self;
}

sub load_config() {
    my $self = shift;
    return 0 unless $self->{data}{config};
    $self->{message}->post(qq[], qq[Rebar_Object], 4);
    
    no strict 'refs';
    my $config_var = q(Config) . q(::) . $self->{data}{config};
    $self->{data} = {
        %{$self->{data}},
        %{$$config_var},
    };
    
    return 1;
}

sub setup() {
    my $self = shift;
    $self->{message}->post(qq[], qq[Rebar_Object], 4);
    
    return 1;
}

sub in() {
    my $self = shift;
    $self->{message}->post(qq[], qq[Rebar_Object], 4);
    $self->{data} = {
                %{$self->{data}},
                @_
    };

    my $method = $self->{data}{action} || qq[process];
    if ($self->can($method)) {
        $self->$method;
    } else { $self->process();}
    
    return $self->out();
}

sub process() {
    my $self = shift;
    $self->{message}->post(qq[], qq[Rebar_Object], 4);
    
    return 1;
}

sub out() {
    my $self = shift;
    my $return = shift || $self->{data}{return};
    $self->{message}->post(qq[$return], qq[Rebar_Object], 4);
    $self->{data}{return} ||= shift;
    
    if ($return) {
        return $self->{data}{$return};
    } else {
        return $self->{data};
    }
}

1;