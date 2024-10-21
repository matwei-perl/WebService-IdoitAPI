package WebService::IdoitAPI::Layer3Net;

use warnings;
use strict;
use Carp;

use WebService::IdoitAPI;

# VERSION

sub create {
    my ($api, $fields) = @_;
    my ($address,$cidr_suffix) = split "/", $fields->{network};
    unless ( $cidr_suffix ) {
        $cidr_suffix = ( $address =~ /:/ ) ? "128" : "32";
    }
    my $title = $fields->{title} || "$address/$cidr_suffix";
    my $description = $fields->{description} || '';
    my $res = $api->request({
        method => 'cmdb.object.create',
        params => {
            type => 'C__OBJTYPE__LAYER3_NET',
            title => $title,
            description => $description,
            status => 2,
        },
    });
    if ( $res->{is_success} ) {
        my $id = $res->{content}->{result}->{id};
        $res = $api->request({
            method => 'cmdb.category.save',
            params => {
                object => $id,
                category => "C__CATG__GLOBAL",
                data => {
                    category => 'C__GLOBAL_CATEGORY__NETWORK',
                    cmdb_status => 'C__CMDB_STATUS__IN_OPERATION',
                    purpose => 1,
                },
            },
        });
        $res = $api->request({
            method => 'cmdb.category.save',
            params => {
                object => $id,
                category => "C__CATS__NET",
                data => {
                    address => $address,
                    cidr_suffix => int($cidr_suffix),
                },
            },
        });
        return $id;
    }
    return;
} # create()

sub list {
    my ($api) = @_;
    my $res = $api->request( {
        method => 'cmdb.objects.read',
        params => {
            categories => [ "C__CATG__GLOBAL", "C__CATS__NET" ],
            filter => {
                type => "C__OBJTYPE__LAYER3_NET",
                status => "C__RECORD_STATUS__NORMAL",
            },
        },
    });
    unless ( $res) {
        warn "list(): client error: $api->{client}->status_line";
        return;
    }
    unless ( $res->{is_success} ) {
        my ($code, $message) = $res->{content}->{error}->@{qw(code message)};
        warn "list(): server error: $code: $message";
        return;
    }
    my @nets = ();
    if ($res->{is_success}) {
        @nets = map {
            my $address = $_->{categories}->{C__CATS__NET}->[0]->{address};
            my $cidr_suffix = $_->{categories}->{C__CATS__NET}->[0]->{cidr_suffix};
            my $network = "$address/$cidr_suffix";
            {   id => $_->{id},
                address => $address,
                cidr_suffix => $cidr_suffix,
                description => $_->{categories}->{C__CATG__GLOBAL}->[0]->{description},
                gateway => $_->{categories}->{C__CATS__NET}->[0]->{gateway}->{ref_title} || '',
                gateway_id => $_->{categories}->{C__CATS__NET}->[0]->{gateway}->{id} || '',
                network => $network,
            }
        } @{$res->{content}->{result}};
    }
    return \@nets;
} # list()

1; # Magic true value required at end of module
__END__

=head1 NAME

WebService::IdoitAPI::Layer3Net - handle layer 3 networks


=head1 SYNOPSIS

  use WebService::IdoitAPI::Layer3Net;

  my $api = WebService::IdoitAPI->new( $config );

  my $fields = {
    network = "$addr_with_or_without_suffix",
    title = $title,
    description = $description,
  };
  my $id = WebService::IdoitAPI::Layer3Net::create( $api, $fields );

  my $nets = WebService::IdoitAPI::Layer3Net::list( $api );

  for my $net ( @$nets ) {
    # do something with $net
  }

=head1 DESCRIPTION

=head1 INTERFACE 

=head2 Functions

=head3 create( $api, $fields )

  my $api = WebService::IdoitAPI->new( $config );
  my $fields = {
    network = "$addr_with_or_without_suffix",
    title = $title,
    description = $description,
  };
  my $id = WebService::IdoitAPI::Layer3Net::create( $api, $fields );

This function creates a network object within i-doit
according to the given field values.

If C<< $fields->{network} >> is given without slash (C<< / >>) and suffix,
the network is created as host network
and a suffix of C<32> or C<128> is added.

If C<< $fields->{title} >> is missing or empty,
the title is set to C<< $fields->{network} >>.

If C<< $fields->{description} >> is missing or empty,
it is set to the empty string.

=head3 list( $api )

  my $api = WebService::IdoitAPI->new( $config );
  my $nets = WebService::IdoitAPI::Layer3Net::list( $api );
  for my $net ( @$nets ) {
     # do something
  }

This function returns an array containing all networks known by i-doit.
Every item in this array has the following structure:

  {
    id => $id,
    address => $address,
    cidr_suffix => $suffix,
    gateway => $gateway_addr,
    gateway_id => $gw_id,
    network => $network,
  }

C<$id> can be used to retrieve details from i-doit
about the network in question.
C<$address> is the network address,
and C<$suffix> is the CIDR suffix of the network.
C<$gateway> is the address of the gateway or the empty string,
C<$gateway_id> is the id of the object acting as gateway or the empty string.
C<$network> is the network in CIDR notation,
that is C<$address> followed by "/" followed by C<$cidr_suffix>.

=head1 DIAGNOSTICS

=over

=item C<< %s(): client error: %s" >>

There was a problem while trying to access i-doit
from the function given at the start of the line.
Look at the status line after C<< client error: >> for details.

=item C<< %s(): server error: %i: %s >>

The i-doit server returned an error message after a request was made
from the function given at the start of the line.
Look in the i-doit documentation
for the error code and the message after C<< server error: >> for details.

=back

=head1 CONFIGURATION AND ENVIRONMENT

WebService::IdoitAPI::Layer3Net itself requires
no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-new@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Mathias Weidner  C<< <mamawe@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 123, Mathias Weidner C<< <mamawe@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
