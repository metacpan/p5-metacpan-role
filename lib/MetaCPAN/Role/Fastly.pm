package MetaCPAN::Role::Fastly;

# COPY BELOW HERE INTO MetaCPAN::Role::Fastly

use Moose::Role;
use Net::Fastly;
use Carp;

with 'MooseX::Fastly::Role';

=head1 NAME

MetaCPAN::Role::Fastly - Methods for fastly API intergration

=head1 SYNOPSIS

  use MetaCPAN::Role::Fastly;

=head1 DESCRIPTION

This role includes L<MooseX::Fastly::Role>.

It also adds some purge related methods, you need to call
L</perform_purge> to actually do the purges.

=head1 METHODS

=head2 $self->purge_surrogate_key('BAR');

Try to use on of the more specific methods below if possible.

=cut

=head2 $self->purge_author_key('Ether');

=cut

sub purge_author_key {
    my ( $self, $author ) = @_;

    $self->purge_surrogate_key( $self->_format_auth_key($author) );
}


=head2 $self->purge_dist_key('Moose');

=cut

sub purge_dist_key {
    my ( $self, $dist ) = @_;

    $self->purge_surrogate_key( $self->_format_dist_key($dist) );
}

=head2 $self->purge_cpan_distnameinfos(\@list_of_distnameinfo_objects);

Using this array reference of L<CPAN::DistnameInfo> objects,
the cpanid and dist name are extracted and used to build a list
of keys to purge, the purge happens from within this method.

All other purging requires `finalize` to be implimented so it
can be wrapped with a I<before> and called.

=cut

#cdn_purge_cpan_distnameinfos
sub purge_cpan_distnameinfos {
    my ( $self, $dist_list ) = @_;

    my %purge_keys;
    foreach my $dist ( @{$dist_list} ) {

        croak "Must be CPAN::DistnameInfo"
            unless $dist->isa('CPAN::DistnameInfo');

        $purge_keys{ $self->_format_auth_key( $dist->cpanid ) } = 1;    # "GBARR"
        $purge_keys{ $self->_format_dist_key( $dist->dist ) }
            = 1;    # "CPAN-DistnameInfo"

    }

    my @unique_to_purge = keys %purge_keys;

    $self->purge_surrogate_key(@unique_to_purge);

    $self->perform_purges;

}

has _surrogate_keys_to_purge => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        purge_surrogate_key          => 'push',
        has_surrogate_keys_to_purge  => 'count',
        surrogate_keys_to_purge      => 'elements',
        join_surrogate_keys_to_purge => 'join',
        reset_surrogate_keys => 'clear',
    },
);

sub perform_purges {
    my ($self) = @_;

    # Some action must have triggered a purge
    if ( $self->has_surrogate_keys_to_purge ) {

        # Something changed, means we need to purge some keys
        my @keys = $self->surrogate_keys_to_purge();

        $self->cdn_purge_now( { keys => \@keys, } );

        # Rest
        $self->reset_surrogate_keys();
    }

}

=head2 datacenters()

=cut

sub datacenters {
    my ($self) = @_;
    my $net_fastly = $self->cdn_api();
    return unless $net_fastly;

    # Uses the private interface as fastly client doesn't
    # have this end point yet
    my $datacenters = $net_fastly->client->_get('/datacenters');
    return $datacenters;
}

sub _format_dist_key {
    my ( $self, $dist ) = @_;

    $dist = uc($dist);
    $dist =~ s/:/-/g;    #

    return 'dist=' . $dist;
}

sub _format_auth_key {
    my ( $self, $author ) = @_;

    $author = uc($author);
    return 'author=' . $author;
}

1;
