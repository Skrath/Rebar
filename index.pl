#!/usr/bin/env perl

######################################################################
#
# Rebar
#
# A template-based framework
#
######################################################################

use warnings;
use strict;
use lib qw( ./libs );
use CGI::Carp qw(fatalsToBrowser);
use Constructor;
use Devel::Size;

my $constructor = new Constructor;
print $constructor->{cgi}->header( -cookie => $constructor->{session_cookie} );
$constructor->run();
#
## Director debug output
print "<hr>";
if ($constructor->{debug}->{show_director_mem}) {
	print "<b>Director Memory Usage</b>: ",Devel::Size::total_size($constructor),"<br>";
}

if ($constructor->{debug}->{show_template_mem}) {
	print "<b>Template Memory Usage</b>: ",Devel::Size::total_size($constructor->{template}),"<br>";
}

if ($constructor->{debug}->{show_template_attributes}) {
	print "<b>Template Attributes:</b>";
	use Data::Dumper; print "<pre>",Dumper($constructor->{template}->{attributes}),"</pre>";
}

if ($constructor->{debug}->{show_director}) {
	print "<b>Director Object:</b>";
	use Data::Dumper; print "<pre>",Dumper($constructor),"</pre>";
}

if ($constructor->{debug}->{show_director_messages} && $constructor->{message}->get) {
	print "<b>Director Messages:</b>";
	use Data::Dumper; print "<pre>",Dumper($constructor->{message}->get),"</pre>";
	print scalar @{$constructor->{message}->get} . " Total messages";
}