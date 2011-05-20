#!/usr/bin/env perl

package Config;

use Rebar_Object::Rebar_url_parser;
use Rebar_Object::Rebar_find_file;
use Rebar_Object::Rebar_file_handler;
use Rebar_Object::Rebar_template_parser;

######################################################################

# Set these to point to your copy of the database.
our %database = qw(
                      name rare
                      username eric
                      password eric
                      openx_prefix ox_
              );

# Had to move this in here so that Blosxom could utilize this
our $abs_base_dir   = q();
($abs_base_dir) = ($ENV{SCRIPT_FILENAME} =~ m!^(.+)/.*?$!)
        if exists $ENV{SCRIPT_FILENAME};

######################################################################

our $object_list = {
    'url_parser' => {
        object  => qq[Rebar_url_parser],
        return  => qq[parsed],
    },
    'find_template' =>  {
        object      => q(Rebar_find_file),
        location    => q(templates),
        error       => q(error),
        default     => q(index),
        extensions  => [q(html), q(htm), q(tpl)],
        return      => q(file),
    },
    'file_handler' => {
        object  => q(Rebar_file_handler),
        action  => qq[read],
        return  => qq[contents],
    },
    'template_parser' => {
        object      => q(Rebar_template_parser),
        token_left  => q(<<),
        token_right => q(>>),
        patterns    => {},
        return      => q(parsed),
    },
};

our $url_parser = {
    return  => qq[parsed],
};

our $file_handler = {
    action  => qq[read],
    return  => qq[contents],
};

our $find_template = {
                    location    => q(templates),
                    error       => q(error),
                    default     => q(index),
                    extensions  => [q(html), q(htm), q(tpl)],
                    return      => q(file),
};

our $template_parser = {
                    token_left	=> q(<<),
                    token_right => q(>>),
                    patterns    => {},
                    return      => q(parsed),
};

our $messages = {
                    level   => 4,   # the debug level for message posting(message_level), the higher the level,
                                    # the more verbose and numerous the messages.
                                    # Level 1 is for messages designed for users, such as form errors.
                                    # Level 2 is for messages designed for admins/developers regarding site errors
                                    # Level 3 is for general information about what the system is doing
                                    # Level 4 is for viewing *ALL* standard function calls
};

our $debug = {
                show_director               => 0,   # dumps the $director object
                show_director_messages      => 1,   # dumps all messages posted to the director
                show_director_mem           => 1,   # shows how much memory the $director object is using
                show_template_attributes    => 0,   # dumps template attributes, these are the variables that
                                                    # templates have access to
                show_template_mem           => 0,   # shows how much memory the $template object is using
                database_trace_level        => 0,   # Acceptable values are zero (no tracing) through fifteen (maximum tracing)
    };



1;
