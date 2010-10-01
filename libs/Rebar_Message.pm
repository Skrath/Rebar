#!/usr/bin/env perl

package Rebar_Message;

use warnings;
use strict;


# the debug level for message posting(message_level), the higher the level,
# the more verbose and numerous the messages.
# Level 1 is for messages designed for users, such as form errors.
# Level 2 is for messages designed for admins/developers regarding site errors
# Level 3 is for general information about what the system is doing
# Level 4 is for viewing *ALL* standard function calls
######################################################################

# NEW
#
# 
sub new {
    my $class = shift;
    my $self  = {
    	messages    => undef,
        level       => 1,
        months      => [qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)],
        weekDays    => [qw(Sun Mon Tue Wed Thu Fri Sat Sun)],
        @_
    };
    $self = bless $self => ( $class or ref $class );
    return $self;
}

sub post($$$) {
    my ($self, $text, $category, $level) = @_;
    $level ||= 1;
    return 0 if $self->{level} < $level;
    my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
    my $year = 1900 + $yearOffset;
    my $time = "$hour:$minute:$second, $self->{weekDays}[$dayOfWeek] $self->{months}[$month] $dayOfMonth, $year";
    push @{$self->{messages}}, {
                                time => $time,
                                text => $text,
                                category => $category,
                                level => $level,
                                filename => (caller())[1],
                                line        => (caller())[2],
                                subroutine  => (caller(1))[3],
                                } if $self->{level} >= $level;
}

sub get($) {
    my ($self, $category, $level) = @_;
    my $messages;
    
    for my $key (@{$self->{messages}}) {
        push @{$messages}, $key->{time} . ': [' . $key->{filename} . '(line: ' .$key->{line} . ')] ' . $key->{subroutine} . ' - "' . $key->{text} . '"' if ( !$category or ($key->{category} eq $category) ) and ( !$level or ($key->{level} == $level) );
    }

    return $messages;
}

1;