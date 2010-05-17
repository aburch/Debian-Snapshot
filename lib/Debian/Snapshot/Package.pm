package Debian::Snapshot::Package;
# ABSTRACT: information about a source package

use Moose;
use MooseX::Params::Validate;
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

has '_srcfiles' => (
	is      => 'ro',
	isa     => 'HashRef',
	lazy    => 1,
	builder => '_srcfiles_builder',
);

sub _srcfiles_builder {
	my $self    = shift;
	my $package = $self->package;
	my $version = $self->version;

	$self->_service->_get_json("/mr/package/$package/$version/srcfiles?fileinfo=1");
}

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

sub download {
	my ($self, %p) = validated_hash(\@_,
		archive_name => { isa => 'Str | RegexpRef', optional => 1, },
		directory    => { isa => 'Str', },
	);
	my $package = $self->package;

	my @files = map Debian::Snapshot::File->new(
		hash      => $_->{hash},
		_fileinfo => $self->_srcfiles->{fileinfo}->{ $_->{hash} },
		_service  => $self->_service,
	), @{ $self->_srcfiles->{result} };

	my @local_files;
	for (@files) {
		push @local_files, $_->download(
			defined $p{archive_name} ? (archive_name => $p{archive_name}) : (),
			directory => $p{directory},
			filename  => qr/^\Q$package\E_/,
		);
	}

	return \@local_files;
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

=method download(%params)

Download the source package.

=over

=item archive_name

Passed to L<< Debian::Snapshot::File->download|Debian::Snapshot::File/"download(%params)" >>.

=item directory

(Required.) Downloaded source files will be stored in this directory.

=back

=head1 SEE ALSO

L<Debian::Snapshot>
