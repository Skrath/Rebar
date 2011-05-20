#!/usr/bin/env perl

package Constructor;

use warnings;
use strict;
use Apache::Session::Postgres;
use Carp;
use CGI;
use CGI::Cookie;
#use Postgres::Handler;

### REMOVE ME
use URI::Escape;

use Rebar_Message;
#use Rebar_Template;
#use Rebar_Object;
#require 'test.pm';

require 'Config.pl';

#### GLOBALS #########################################################


#### CONSTRUCTOR #####################################################

sub new($;%) {
    my $class = shift;
    my $self  = {
        @_,
        cgi => new CGI,
        #db  => new Postgres::Handler (
        #    database => $Config::database{name},
        #    username => $Config::database{username},
        #    password => $Config::database{password},
        #    settings => {
        #        TraceLevel => $Config::debug->{database_trace_level},
        #    }
        #),
        settings        => {},
        base_dir        => q(),
        abs_base_dir    => $Config::abs_base_dir,
        debug           => $Config::debug,
        message         => new Rebar_Message(%{$Config::messages}),
        object_list     => $Config::object_list,
    };
    $self->{message}->post(qq[], qq[Constructor], 4);

    # We do this assignment outside of the hash above.  Otherwise when
    # we try to create a Director while not running under Apache
    # (e.g. the test scripts) the whole thing will break since
    # SCRIPT_NAME doesn't exist.  We end up with an "odd number of
    # elements in a hash" problem.  Fucking solution right here baby.
    ($self->{base_dir}) = $ENV{SCRIPT_NAME} =~ m!^(.+)/.*?$!
        if exists $ENV{SCRIPT_NAME};

    $self->{base_dir} ||= '';

    my $self = bless $self => ( $class or ref $class );

    return $self;
}

###
# Auto-loader for objects
###
sub load_objects($) {
    my $self        = shift;
    my %object_list = %{$self->{object_list}};

    use Data::Dumper;

    no strict 'refs';

    foreach my $key (keys %object_list) {
        my $object_eval = q(new Rebar_Object) . q(::) . $object_list{$key}{object} . q[($self->{message}] . q(, config => qq[) . $key .q(]) . q[)];
        $self->{$key} = eval $object_eval;
    }
}

#### PUBLIC METHODS ##################################################

#### NOT CURRENTLY USED
sub get_current_page {
    my ($self) = shift;
    $self->{message}->post(qq[], qq[Constructor], 4);
    for (0..$#{$self->{parameters}}) {
        return $self->{parameters}->[$_+1]
            if $self->{parameters}->[$_] eq 'page'
           and exists $self->{parameters}->[$_+1];
    }
    return 0;
}

### NOT CURRENTLY USED
sub redirect($$) {
    my ($self, $url) = @_;
    $self->{message}->post(qq[], qq[Constructor], 4);

    # If the current model and action appear in the URL then we stop
    # the redirection.  This way we can try to avoid get stuck in any
    # fucked up loops.
    if ($url =~ m!^/?(\w+?)/(\w+?)!) {
        return if $self->{action} eq $1 and $self->{model}  eq $2;
        return if $self->{model}  eq $1 and $self->{action} eq $2;
    }

    $self->parse_url($url) and $self->run();
}

sub run($) {
    my $self     = shift;
    $self->{message}->post(qq[], qq[Constructor], 4);
    #my $package  =  q(Action::).qq(\u$self->{action});
    #my $function = $package.q(::do);
    #{
    #    no strict 'refs';
    #    return &{$function}(director => $self) if exists &{$function};
    #}

    $self->load_objects();

    my @template_queue;
    my $output;
    push (@template_queue, $self->{file_handler}->in(
                                name    => $self->{find_template}->in(
                                                    baseurl      => $self->{base_dir},
                                                    parameters   => $self->{url_parser}->in(url => $self->{cgi}->url_param('command') || 0),
                                        ),
                            )
    );

    while (@template_queue) {
        $self->{template_parser}->in(template => pop @template_queue);
        $output .= $self->{template_parser}->out();
        if ($self->{template_parser}->out(q[remainder])) {
            push (@template_queue, $self->{template_parser}->out(q[remainder]));
            push (@template_queue,  $self->{file_handler}->in(
                                        name => $self->{find_template}->in(parameters => $self->{template_parser}->out(q[load])),
                                    )
            );
        }
    }

    print $output;
}

### NOT CURRENTLY USED
sub start_session($) {
    my $self    = shift;
    $self->{message}->post(qq[], qq[Constructor], 4);
    my %cookies = fetch CGI::Cookie;
    my (%session, $session_id);
    my $user      = Factory::Model( 'user' );
    my $manager    = Factory::Manager( 'user', $self );

    $session_id = $cookies{SESSION_ID}->value if defined $cookies{SESSION_ID} and ( ($self->{action}) and (not $self->{action} eq 'logout') );

    tie %session, 'Apache::Session::Postgres', $session_id, {
        Handle => $self->{db}->{connection},
        Commit => 0,
    };

    $self->{session} = \%session;
    if ($self->{session}->{user}) {
        $manager->load($user, $self->{session}->{user}->{ID});
        $self->{session}->{user}->{NAME} = $user->name();
        $self->{session}->{user}->{ID} = $user->id();
        $self->{session}->{user}->{LEVEL} = $user->level();
        $self->{session}->{user}->{EMAIL} = $user->email();
    }

    $self->{session_cookie} = new CGI::Cookie(
        -name => 'SESSION_ID',
        -value => $session{_session_id},
    );
}

### NOT CURRENTLY USED
sub set_session_variables($%) {
    my ($self, %variable) = @_;
    $self->{message}->post(qq[], qq[Constructor], 4);
    my %session;

    tie %session, 'Apache::Session::Postgres', $self->{session}->{_session_id}, {
        Handle => $self->{db}->{connection},
        Commit => 1,
    };

    while (my ($key, $value) = each %variable) {
        $self->{session}->{$key} = $value;
        $session{$key} = $value;
    }
}

### NOT CURRENTLY USED
sub end_session($) {
    my $self = shift;
    $self->{message}->post(qq[], qq[Constructor], 4);

    if (tied %{$self->{session}}) {
        $self->{session_cookie}->value(undef);
        tied(%{$self->{session}})->delete;
    }
}

#### PRIVATE METHODS #################################################

### NOT CURRENTLY USED
sub load_settings($) {
    my $self = shift;
    $self->{message}->post(qq[], qq[Constructor], 4);

    $self->{db}->query(sql => 'SELECT * FROM settings');
    my $settings = $self->{db}->get_all_rows(key => 'settings_id');

    # If we simply wrote $self->{settings} = $settings then we would
    # have to write things later like:
    #
    #     $self->{settings}->{signup_email_address}->{settings_value}
    #
    # Which sucks.  Furthermore the return value of get_all_rows() will
    # have duplicated the keys, do to the way DBI behaves.  So the loop
    # below trades off some processing time to remove duplicate keys.

    for (keys %$settings) {
        $self->{settings}->{$_} = $settings->{$_}->{settings_value};
    }
}

sub parse_url($$) {
    my ($self, $url) = @_;
    $self->{message}->post(qq[], qq[Constructor], 4);
    return unless $url;

    # Every time we parse a new URL we get rid of the old data.
    # Otherwise we tend to shoot ourselves in the foot.
    $self->{parameters} = undef;

    #for my $chunk ( split m!/! => $url ) {
    #    next if not $chunk;

        # Once we have an action and a model we stop.  This way we are
        # certain to get only the first action and model in the URL.
        # It also cuts this loop short, as it's rather expensive for
        # us to do with the greps below.
        #last if $self->{action} and $self->{model};

        # Get the action and model, assuming they are in our list of
        # acceptable actions and models.
    #    if ( grep { $chunk eq $_ } @actions ) { $self->{action} = $chunk, next; }
    #    if ( grep { $chunk eq $_ } @models  ) { $self->{model}  = $chunk, next; }
    #}

    # If admin is anywhere in the title we set the flag.
    #$self->{admin} = 1 if $url =~ /admin/;

    # Everything that's not an action, model, or the admin flag gets
    # split up into an array.  First we take the URL and strip out those
    # three things.
    #my $param_list = $url;
    #for (( @{$self}{qw( action model )}, 'admin' )) {
    #    $param_list =~ s!/?$_/?!! if $_;
    #}

    # Convert dashes in the model name to underscores.  We do this because in
    # some places we use dashes in URLs.  I (Eric) don't like underscores in URLs.
    # Not sure why.  I just don't.  But our INFO table over in Model.pm is keyed
    # with model names containing underscores.  So we make the translation here.
    #
    # This must come after the for loop above where we remove the model name
    # from the URL.  Otherwise it will end up being treated as a parameter.
    #$self->{model} =~ tr/-/_/ if $self->{model};

    # Then we split it by slashes and escape every element.
    $self->{parameters} = [ map { uri_escape($_) } @{ [ split m!/! => $url ] } ];
}

######################################################################

1;

__END__

=head1 NAME

Director

=head1 DESCRIPTION

This module directs the show.  It is the main processor that dictates
what we are going to do for the application.  It determines whether we
are performing an action or merely displaying some templates.

=head1 CONSTRUCTOR

Takes no arguments.  It automatically breaks down the URL given by
CGI parameter C<command>, which should be set prior to running the
index script (e.g. via mod_rewrite).

=head1 PUBLIC METHODS

=over

=item C<get_current_page()>

Returns the number of the current page for those actions which care to
support pagination.  The page number is indicated by director
parameters, meaning it appears in the URL.  If the URL of the current
page contains C<.../page/5/...> then the function would return five
for the page number.  It is assumed that the page number comes
directly after C<page> in the URL.  The function will fail to produce
the correct value if this is true.

=item C<redirect( $url )>

Accepts a URL as the user would type it into the browser and redirects
to that place, e.g C<redirect('list/users/admin')>.

=item C<run()>

Calls the C<do()> method of the class indicated by the C<action>
member.  It calls the method with a hash of one argument, C<director>,
which points to the director itself.  Those methods can use the
members of the director to decide what to do.  The members C<action>
and C<model> are the name of the action model respectively, and
C<parameters> is an array reference representing what was left of the
original URL after the action and model were removed.  The elements of
the path will not contain slashes.  They will represent the order in
which they appeared in the URL.

=item C<start_session()>

Creates a new session and a cookie containing the session ID.  This information
is stored in the C<session> and C<session_cookie> members.

=item C<set_session_variables( %variables )>

Takes a hash of key-value pairs and adds them to the session information.

=item C<end_session()>

Destroys any existing session.

=back

=head1 PRIVATE METHODS

=over

=item C<load_settings()>

Reads all of the application settings out of the `settings' database table
and loads them into the C<settings> hash of the Director.

=item C<parse_url( I<$url> )>

Takes a url and determines the action and model in that URL, if any.
It will set the C<action> and C<model> members of the director instance.
Those two parts of the URL will be removed and what remains will be set
to the C<parameters> member as an array reference, where each element is
a parameter from the array.

=back

=cut
