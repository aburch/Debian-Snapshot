package Debian::Snapshot::Package;
# ABSTRACT: information about a source package

use Any::Moose;

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

has 'srcfiles' => (
	is      => 'ro',
	isa     => 'ArrayRef[Debian::Snapshot::File]',
	lazy    => 1,
	builder => '_srcfiles_builder',
);

sub _srcfiles_builder {
	my $self    = shift;
	my $package = $self->package;
	my $version = $self->version;

	my $json = $self->_service->_get_json("/mr/package/$package/$version/srcfiles?fileinfo=1");
	my @files = map Debian::Snapshot::File->new(
		hash      => $_->{hash},
		_fileinfo => $json->{fileinfo}->{ $_->{hash} },
		_service  => $self->_service,
	), @{ $json->{result} };

	return \@files;
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
	my ($self, %p) = @_;
	my $package = $self->package;

	my $ver = $self->version;
	# filenames do not include epoch
	$ver =~ s/^[0-9]+://;

	# upstream tarball does not include Debian revision.
	# filename has either .orig or the Debian revision followed by a dot.
	$ver =~ s/-([a-zA-Z0-9.+~]*)$//;
	my $rev = $1;

	my @local_files;
	for (@{ $self->srcfiles }) {
		push @local_files, $_->download(
			defined $p{archive_name} ? (archive_name => $p{archive_name}) : (),
			directory => $p{directory},
			filename  => qr/^\Q${package}_${ver}\E(?:\.orig|-\Q$rev.\E)/,
			exists $p{overwrite} ? (overwrite => $p{overwrite}) : (),
		);
	}

	return \@local_files;
}

no Any::Moose;
1;

__END__

=attr package

Name of the source package.

=attr version

Version of the source package.

=attr srcfiles

Arrayref containing L<Debian::Snapshot::File|Debian::Snapshot::File> objects
for the source files of this package.

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

=item overwrite

Passed to L<< Debian::Snapshot::File->download|Debian::Snapshot::File/"download(%params)" >>.

=item directory

(Required.) Downloaded source files will be stored in this directory.

=back

=head1 SEE ALSO

L<Debian::Snapshot>
