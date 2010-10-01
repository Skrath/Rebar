#!/usr/bin/env perl

package Rebar_Object::Rebar_template_parser;

use warnings;
use strict;
use URI::Escape;
use Regexp::Common;
use base qw( Rebar_Object );
use Switch;

sub setup() {
    my $self = shift;
    $self->{message}->post(qq[], qq[Rebar_Object], 4);
 
    $self->{data}{flag} = qq[parsing];
    $self->{data}{remainder} = q();
    $self->prepare_regular_expressions();
    $self->prepare_template_dirs();
    $self->prepare_builtin_attributes();
    
    return 1;
}

sub prepare_regular_expressions($) {
    my $self = shift;
    $self->{message}->post(qq[], qq[Rebar_Template], 4);
    
    $self->{data}{patterns}->{pieces}          = qr / ( $self->{data}{token_left} [\#=@!?~].*? $self->{data}{token_right} ) /osx; # Heh, OSX
    $self->{data}{patterns}->{open_condition}  = qr / $self->{data}{token_left} \?.+ $self->{data}{token_right} /osx;
    $self->{data}{patterns}->{close_condition} = qr / $self->{data}{token_left} \? $self->{data}{token_right} /osx;
    $self->{data}{patterns}->{get_condition}   = qr / (^ $self->{data}{token_left} \?(.+?) $self->{data}{token_right} (.*) $self->{data}{token_left} \? $self->{data}{token_right} $) /osx;
    $self->{data}{patterns}->{open_loop}       = qr / $self->{data}{token_left} ~.+ $self->{data}{token_right} /osx;
    $self->{data}{patterns}->{close_loop}      = qr / $self->{data}{token_left} ~ $self->{data}{token_right} /osx;
    $self->{data}{patterns}->{get_loop}        = qr / (^ $self->{data}{token_left} ~(.+?) $self->{data}{token_right} (.*) $self->{data}{token_left} ~ $self->{data}{token_right} $) /osx;
    $self->{data}{patterns}->{get_function}    = qr / ( $self->{data}{token_left} \# (.+?) $self->{data}{token_right} ) /osx;
    $self->{data}{patterns}->{get_tag}         = qr / ( $self->{data}{token_left} ([=@!].+) $self->{data}{token_right} ) /osx;
    #$self->{patterns}->{has_extension}	 = qr / \. (html|htm|tpl) $ /oix;
}

sub prepare_template_dirs($) {
    my $self    = shift;
    $self->{message}->post(qq[], qq[Rebar_Template], 4);
    
    #my $basedir = $ENV{SCRIPT_FILENAME};
    #$basedir             =~ s!^(.+)/.*$!$1!;
    #
    #$self->{data}{basedir}     = $basedir;
    #$self->{data}{templatedir} = $basedir . '/' . $self->{data}{template_folder};	
    #$self->{data}{templateurl} = $self->{data}{baseurl} . '/' . $self->{data}{template_folder};

    # Check for action and model and default if necessary
    #$self->{default_template} = $self->{path}->[0] || 'index';
}

sub prepare_builtin_attributes($) {
    my $self = shift;
    $self->{message}->post(qq[], qq[Rebar_Template], 4);
    
    $self->{data}{attributes}{baseurl}          = $self->{data}{baseurl};
    $self->{data}{attributes}{templateurl}      = $self->{data}{templateurl};
}

# PARSE_STRING
#
# This is the business.
# Receives a string with template code and returns parsed html
sub parse_string {
    my $self = shift;
    $self->{message}->post(qq[], qq[Rebar_Template], 4);
    $self->{data}{remainder} = q();
    $self->{data}{flag} = qq[parsing];
    my @str_pieces = split /$self->{data}{patterns}{pieces}/ => $self->{data}{template};
    my $output = '';
	
    my $depth = 0;
    my $depthtype = '';
	
    my $buffer = '';
    
    while (@str_pieces && ($self->{data}{flag} eq qq[parsing])) {
        my $piece = shift @str_pieces;
        if ($depth) {
            #We're inside a control structure, so we're storing its contents in $buffer to parse it
            $buffer .= $piece;
	    
            switch (1) {
                case ($piece =~ /$self->{data}{patterns}{open_condition}/) { $depth++; next }
                case ($piece =~ /$self->{data}{patterns}{close_condition}/) { $depth--; next }
                if (!$depth) {
                    case ($depthtype eq '?') { #Condition
                        $buffer =~ /$self->{data}{patterns}{get_condition}/;
                        unshift(@str_pieces, split /$self->{data}{patterns}{pieces}/ => $self->parse_condition($1));
                    }
                    case ($depthtype eq '~') { #Loop
                        $buffer =~ /$self->{data}{patterns}{get_loop}/;
                        $output .= $self->parse_loop($1);
                    }
                }
            }
        } else {
            switch (1) {
                case ($piece =~ /$self->{data}{patterns}{get_tag}/) { $output .= $self->parse_tag( $1 ) }
                case ($piece =~ /$self->{data}{patterns}{get_function}/) { $output .= $self->parse_function( $2 ) }
                case ( ($piece =~ /$self->{data}{patterns}{open_condition}/) || ($piece =~ /$self->{data}{patterns}{open_loop}/) ) {
                    $buffer = $piece;
                    $depth++;
                    next;
                }
                case ($piece =~ /$self->{data}{patterns}{open_condition}/) { $depthtype = '?' } #Condition
                case ($piece =~ /$self->{data}{patterns}{open_loop}/) { $depthtype = '~' } #Loop
                else { $output .= $piece }
            }
        }
    }
    if ($depth) {
        # this should never happen
    }
    $self->{data}{remainder} = join("", @str_pieces);
    $self->{data}{parsed} = $output;
    return 1;
}

# PARSE_TAG
#
# argument is a string that contains a single tag and parses it
sub parse_tag {
    my $self = shift;
    $self->{message}->post(qq[@_], qq[Rebar_Template], 4);

    (my $tag = shift) =~ / $self->{data}{token_left} ([=@!])(.+) $self->{data}{token_right} /sx;
    switch ($1) {
        case '@' { return $self->_tag_import($2) }
        case '=' { return sprintf( "%s", $self->_tag_variable($2)) }
        else { return $tag }
    }
}

# _TAG_IMPORT
#
# This function _should_ be smart enough to find the file you're looking for...
# a) with or without extension
# b) case insensitively
# c) with or without subdirs provided
sub _tag_import {
    my $self = shift;
    $self->{message}->post(qq[@_], qq[Rebar_Template], 4);
    my $tag = shift;
    my @pieces = $tag =~ /(^\S+)/sx;
    my $source = shift @pieces;
    @pieces = $tag =~ /(\S+?)\s*=\s*(?:(?:['"](.*?)['"])|(?:(\S+?)$|\s))?/gsx; # haw haw, what the hell?
    
    $self->{attributes}{parent} = undef;
    while (scalar @pieces) {
        my $var = shift @pieces;
        my $one = shift @pieces;
        my $two = shift @pieces;
        $self->{attributes}{parent}{$var} = $one || $two;
    }
    #use Data::Dumper; print "<pre>",Dumper($vars),"</pre>";
    
    
    #my %extra = $2 =~ /(.+)\=(.+)/sx;
    
    #$var =~ s/^\s+|\s+$//g;
    $source = [ map { uri_escape($_) } @{ [ split m!/! => $source] } ];
    #****************************
    #$source = $self->valid_file($source, 1);
    $self->{data}{load} = $source;
    $self->{data}{flag} = qq[load];
    
    return q();
}

# _TAG_VARIABLE
#
#
sub _tag_variable {
    my $self = shift;
    $self->{message}->post(qq[@_], qq[Rebar_Template], 4);
    my $var = shift;

    $var =~ s/^\s+|\s+$//g;
	
    for ( $var ) {
        #a number
        if ( /^([-+]?)(\d+)(\.\d*)?$/ ) {
            if ( $3 ) {
                return (sprintf("%f", $var));
            } else {
                return (sprintf("%d", $var));
            }
        }
        #a hash reference
        elsif ( /^(~?)(.+?)(\[.*\])+$/ ) {
            my @vararr = ();
			
            if ($1 eq '~') {
                push(@vararr, '_loop_' . $2 );
            } else {
                push(@vararr, $2 );
            }

            my @subarr = split /\[(.+?)\]/ => $3;
            foreach my $subkey (@subarr) {

                if ($subkey !~ /^\s*$/) {
                    #push (@vararr, $self->_tag_variable($subkey));
                    push @vararr => $subkey;
                }
            }

            return ($self->get_attribute(\@vararr));
        }
        #a string literal
        elsif ( /^([\'\"])(.*?)(\1)$/ ) { #/^([\'\"])(.*?)(?:\\1)$/ ) {
            return (sprintf("%s", $2));
        }
        #a boolean value
        elsif ( /^(true|false)$/i ) {
            if ($1 ne 'true') {
                return ( q() );
            } else {
                return ( 1 );
            }
        }
        #a loop variable
        elsif ( /^~/ ) {
            $var = lc(substr($var, 1));
            $var =~ s/\s//;
            return ($self->get_attribute('_loop_' . $var));
        }
        #an attribute of the template
        else {
            $var = lc($var);
            $var =~ s/\s//;
            return ($self->get_attribute($var));
        }
    }
}

# GET_ATTRIBUTE
#
# returns a member of {attributes}.
sub get_attribute {
    my $self = shift;
    $self->{message}->post(qq[], qq[Rebar_Template], 4);
    my $attrib = shift;
    my $result;

    if ( ref $attrib eq 'ARRAY' ) {

        # Are we trying to pull data from an actual array?
        if (ref $self->{attributes}->{$attrib->[0]} eq 'ARRAY') {
            $result = $self->{attributes}->{$attrib->[0]}[$attrib->[1]];
        }
        
        # And this is for hashes, delicious hashes
        unless ($result) {
            $result = $self->{attributes};
            $result = $result->{$_} foreach @$attrib;
        }
    } else {
        $result = $self->{attributes}->{$attrib};
    }

    return $result || q();
}

# PARSE_CONDITION
#
# argument is a string like <%?condition%>controlled content<%?%>
sub parse_condition {
    my $self = shift;
    (my $tag = shift) =~ /$self->{data}{patterns}{get_condition}/;
    $self->{message}->post(qq[$2], qq[Rebar_Template], 4);
    (my $condition = $2) =~ /\s\//s;
    
    my $contents = $3;
    my $result = undef;
    
    for ( $condition ) {
        #comparing 2 vars
        if ( /^(.*?)(\!?=|<=?|>=?)(.*?)$/ ) {
            my $left_param = $self->_tag_variable($1);
            my $right_param = $self->_tag_variable($3);
            
            # If the params are zero then equality tests will fail with
            # incorrect results, e.g. <<?foo=0>> is false if foo is zero
            # without the assignments below.
            for ($left_param, $right_param) {
                $_ = q() if /$RE{num}{int}/ and $_ == 0;
            }
            
            my $operator = $2;
            
            switch ($operator) {
                case ( "="  ) { $result = 1 if ( $left_param eq $right_param ) }
                case ( "!=" ) { $result = 1 if ( $left_param ne $right_param ) }
                case ( "<"  ) { $result = 1 if ( $left_param <  $right_param ) }
                case ( "<=" ) { $result = 1 if ( $left_param <= $right_param ) }
                case ( ">"  ) { $result = 1 if ( $left_param >  $right_param ) }
                case ( ">=" ) { $result = 1 if ( $left_param >= $right_param ) }
            }
        }
        #single var
        elsif ( /^(\!?)([^<>=]*)$/ ) {
            my $negate = $1;
            my $param = $self->_tag_variable($2);
            $result = $negate ? !$param : $param;
        }
    }
    return $contents if $result;
}

sub process() {
    my $self = shift;
    $self->{message}->post(qq[], qq[Rebar_Template], 4);
    
    $self->parse_string();
    
    return 1;
}

1;