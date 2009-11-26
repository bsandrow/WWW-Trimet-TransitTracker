package WWW::Trimet::TransitTracker;

use warnings;
use strict;

use Carp;
use LWP::UserAgent;
use HTML::Entities;

$|++;

=head1 NAME

WWW::Trimet::TransitTracker - Webscraper for the TriMet TransitTracker page.

=cut
=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

A light-weight way to grab the next arrival times from
L<TriMet.org|http://www.trimet.org>'s TransitTracker page.

Example usage:

    #!/usr/bin/perl

    use strict;
    use warnings;

    use WWW::Trimet::TransitTracker;

    my $tt = WWW::Trimet::TransitTracker->new;

    $tt->stop_id($ARGV[0]);
    $tt->parse();

    map { + print "$_->[0] @ $_->[1]\n"; } @{$tt->arrivals()};

=cut
=head1 MEMBERS

Member functions.

=cut

=head2 new

Creates a new TransitTracker.

Optional Arguments:

=over 12

=item C<stopid>

The Stop ID # that you want arrival times for.

=item C<route>

The Route Number of the particular Route that you're interested in. (i.e. If
you only care about arrivals of Bus #4 at this particular stop).

=item C<ua>

Provide your own LWP::UserAgent instance to use for all communication with
trimet.org (e.g. define your own UserAgent string for your app or something).

=back

=cut
sub new {
    my $class = shift;
    my $args  = {@_};
    my $self  = {};

    # process incoming args
    $self->{stopid} = $args->{stopid} if exists $args->{stopid};
    $self->{route}  = $args->{route}  if exists $args->{route};
    $self->{ua}     = $args->{ua}     if exists $args->{ua};

    # setup a LWP::UserAgent if we don't have one
    unless($self->{ua}) {
        $self->{ua} = LWP::UserAgent->new();
        $self->{ua}->timeout(10);
        $self->{ua}->env_proxy;
        $self->{ua}->agent("WWW::Trimet::TransitTracker/$VERSION");
    }

    return bless($self,$class);
}

=head2 route_number

Getter/setter for the 'route' variable. Optional for parsing.

Returns the Route Number with no arguments. Sets the new Route Number B<and>
returns it if a route number is passed in. If the argument passed in as
non-numeric, croaks an error message.

=cut
sub route_number {
    my $self = shift;
    my $rn   = shift;
    return $self->{route} unless $rn;
    croak "Route Number has to be a number" unless $rn =~ /^[0-9]+$/;
    return $self->{route} = $rn;
}

=head2 stop_id

Getter/setter for the Trimet Stop ID #. This is a required value to parsing a
page, though it may be provided through the constructor as an argument.

Returns the current Stop ID # with no arguments. Sets and returns the provided
Stop ID # as the first argument. Croaks an error message when the new Stop ID #
passed in is non-numeric.

=cut
sub stop_id {
    my $self   = shift;
    my $sid = shift;
    return $self->{stopid} unless $sid;
    croak "Stop ID # has to be a number" unless $sid =~ m/^[0-9]+$/;
    $self->{stopid} = $sid;
    return 1;
}

=head2 arrivals

Returns an ARRAYREF of ARRAYREFS. Each contained ARRAYREF contains a pair of
values. The first value is the label describing which route is arriving (i.e.
Bus Line #4, MAX Red Line, etc). The second is the time that the route is
scheduled to arrive (i.e. 8:45pm).

This value will be undef when before the first parse call is made.
=cut
sub arrivals {
    my $self = shift;
    return $self->{arrivals} ? [ @{$self->{arrivals}} ]
                             : undef;
}

=head2 parse

Cause the TransitTracker page for the current values of 'route' and 'stopid' to
be retrieved and parsed. Values are stored in arrivals which can be accessed
through the arrivals member.

=cut
sub parse {
    my $self = shift;
    return undef unless $self->__parse_sanity_check();
    my $response = $self->{ua}->get($self->__build_url);
    return undef unless $response->is_success;
    my $content  = $response->content;

    # Extract the two arrival times from the page
    $content =~ m[<table[^>]*>\s*<!--Begin arrivals section-->(.*?)</table>]s;
    my $arrivals = [];
    map { + $_ =~ m{<td[^>]*>\s*<p>\s*<b>\s*    # start of route label
                    (.*?)                       # the route label text
                    </b>\s*</p>\s*</td>\s*      # end of route label
                    <td[^>]*>\s*<b>\s*          # start of time
                    <div[^>]*>\s*<div[^>]*>\s*
                    \* (.*?)\s*                 # time text
                    </div>\s*</div>\s*          # end of time
                    </b>\s*</td>
                }xs;
            push @$arrivals, [decode_entities($1),decode_entities($2)]; } ($1 =~ m[<tr[^>]*>(.*?)</tr>]sg);

    $self->{arrivals}  = $arrivals;
    $self->{countdown} = $1 if $content =~ m[refresh\s*</a>\s*within\s*(\d+)\s*seconds]m;
}


=head1 PRIVATE MEMBERS

Private member functions. No need to really worry about these, but they are
here for make the documentation complete.

=cut

=head2 __build_url

An abstraction for producing the TransitTracker URL from the stored values.
Returns the URL as a string. There are no known error conditions (so long as
the sanity check is run first).

=cut
sub __build_url {
    my $self = shift;
    my $url  = "http://trimet.org/arrivals/tracker.html?locationID=$self->{stopid}";
       $url .= "&routeNumber=$self->{route}" if $self->{route};
    return $url;
}

=head2 __parse_sanity_check

Performs the pre-parse sanity check. Returns undef if any non-sane conditions
are found.

=cut
sub __parse_sanity_check {
    my $self = shift;
    return undef if exists $self->{route} && not $self->{route}  =~ /^[0-9]+$/;
    return undef if not exists $self->{stopid};
    return undef if not $self->{stopid} =~ /^[0-9]+$/;
    return 1;
}

=head1 AUTHOR

Brandon Sandrowicz, C<< <brandon@sandrowicz.org> >>

=cut
=head1 BUGS

This is kinda something unsupported that I whipped up for myself, that I
thought others might have an interest in. You can email me about bugs or use
the Github interface for reporting, but don't I<expect> me to fix all your
problems with this software.

=cut
=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Trimet::TransitTracker

You can also look for information at:

=over 4

=item * Github Repository

L<http://www.github.com/bsandrow/WWW-Trimet-TransitTracker>

=back
=cut
=head1 COPYRIGHT & LICENSE

Copyright 2009 Brandon Sandrowicz, all rights reserved.

This program is released under the following license: MIT


=cut

1; # End of WWW::Trimet::TransitTracker
