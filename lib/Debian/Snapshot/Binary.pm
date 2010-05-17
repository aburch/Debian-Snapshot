package Debian::Snapshot::Binary;
# ABSTRACT: information on a binary package

use Moose;
use MooseX::Params::Validate;
use MooseX::StrictConstructor;
use namespace::autoclean;

use Debian::Snapshot::File;
use File::Spec;

has 'binary_version' => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has 'name' => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has 'package' => (
	is       => 'ro',
	isa      => 'Debian::Snapshot::Package',
	required => 1,
	handles  => [qw( _service )],
);

has '_binfiles' => (
	is       => 'ro',
	isa      => 'HashRef',
	lazy     => 1,
	builder  => '_binfiles_builder',
);

sub _binfiles_builder {
	my $self = shift;

	my $package    = $self->package->package;
	my $version    = $self->package->version;
	my $binpkg     = $self->name;
	my $binversion = $self->binary_version;

	return $self->_service->_get_json(
		"/mr/package/$package/$version/binfiles/$binpkg/$binversion?fileinfo=1"
	);
}

sub _as_string {
	my $self = shift;
	return $self->name . "_" . $self->binary_version;
}

sub download {
	my ($self, %p) = validated_hash(\@_,
		architecture => { isa => 'Str', },
		archive_name => { isa => 'Str | RegexpRef', default => 'debian', },
		directory    => { isa => 'Str', optional => 1, },
		filename     => { isa => 'Str', optional => 1, },
	);

	unless (exists $p{directory} || exists $p{filename}) {
		die "Either 'directory' or 'file' parameter is required.";
	}

	my $binfiles = $self->_binfiles;
	my @hashes   = grep $_->{architecture} eq $p{architecture}, @{ $binfiles->{result} };
	my @files    = map Debian::Snapshot::File->new(
		hash      => $_->{hash},
		_fileinfo => $binfiles->{fileinfo}->{ $_->{hash} },
		_service  => $self->_service,
	), @hashes;
	@files = grep $_->archive($p{archive_name}), @files;

	my $desc = $self->_as_string . " ($p{architecture})";
	die "Found no file for $desc" unless @files;
	die "Found more than one file for $desc" if @files > 1;

	return $files[0]->download(
		archive_name => $p{archive_name},
		defined $p{directory} ? (directory => $p{directory}) : (),
		defined $p{filename} ? (filename => $p{filename}) : (),
	);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=attr binary_version

Version of the binary package.

=attr name

Name of the binary package.

=attr package

A L<Debian::Snapshot::Package|Debian::Snapshot::Package> object for the
associated source package.

=method download(%params)

=over

=item architecture

(Required.) Name of the architecture to retrieve the .deb file for.

=item archive_name

Name of the archive to retrieve the package from.
Defaults to C<"debian">.

=item directory

=item filename

Passed to L<< Debian::Snapshot::File->download|Debian::Snapshot::File/"download(%params)" >>.

=back

=head1 SEE ALSO

L<Debian::Snapshot>
