package Debian::Snapshot::Package;
# ABSTRACT: information about a source package

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use Debian::Snapshot::Binary;

has 'package' => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has 'version' => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has '_service' => (
	is       => 'ro',
	isa      => 'Debian::Snapshot',
	required => 1,
);

sub binaries {
	my $self = shift;

	my $package = $self->package;
	my $version = $self->version;
	my $json = $self->_service->_get_json("/mr/package/$package/$version/binpackages");

	my @binaries = map $self->binary($_->{name}, $_->{version}), @{ $json->{result} };
	return \@binaries;
}

sub binary {
	my ($self, $name, $binary_version) = @_;
	return Debian::Snapshot::Binary->new(
		package        => $self,
		name           => $name,
		binary_version => $binary_version,
	);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=attr package

Name of the source package.

=attr version

Version of the source package.

=method binaries

Returns an arrayref of L<Debian::Snapshot::Binary|Debian::Snapshot::Binary> binary
packages associated with this source package.

=method binary($name, $binary_version)

Returns a L<Debian::Snapshot::Binary|Debian::Snapshot::Binary> object for the
binary package C<$name> with the version C<$binary_version>.

=head1 SEE ALSO

L<Debian::Snapshot>
