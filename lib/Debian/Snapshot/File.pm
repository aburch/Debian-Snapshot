package Debian::Snapshot::File;
# ABSTRACT: information about a file

use Moose;
use MooseX::Params::Validate;
use MooseX::StrictConstructor;
use namespace::autoclean;

use File::Spec;
use IO::File;

has 'hash' => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has '_fileinfo' => (
	is      => 'ro',
	isa     => 'ArrayRef[HashRef]',
	lazy    => 1,
	builder => '_fileinfo_builder',
);

has '_service' => (
	is       => 'ro',
	isa      => 'Debian::Snapshot',
	required => 1,
);

sub archive {
	my ($self, $archive_name) = @_;
	my @archives = map $_->{archive_name}, @{ $self->_fileinfo };
	return 0 != grep $_ eq $archive_name, @archives;
}

sub download {
	my ($self, %p) = validated_hash(\@_,
		archive_name => { isa => 'Str', default => 'debian', },
		directory    => { isa => 'Str', optional => 1, },
		filename     => { isa => 'Str', optional => 1, },
	);
	my $hash = $self->hash;

	unless (defined $p{directory} || defined $p{filename}) {
		die "One of 'directory', 'file' parameters must be given.";
	}

	my $filename = $p{filename} // $self->filename($p{archive_name});
	if (defined $p{directory}) {
		$filename = File::Spec->catfile($p{directory}, $filename);
	}

	$self->_service->_get("/file/$hash", ':content_file' => $filename);

	return $filename;
}

sub filename {
	my ($self, $archive_name) = @_;
	my $hash     = $self->hash;
	my @fileinfo = grep $_->{archive_name} eq $archive_name, @{ $self->_fileinfo };
	my @names    = map $_->{name}, @fileinfo;

	die "No filename found for file '$hash' in archive '$archive_name'" unless @names;
	return @names if wantarray;
	die "More than one filename and calling function does not want a list." unless @names == 1;

	my $filename = $names[0];

	die "Filename contains a slash." if $filename =~ m{/};
	die "Filename does not start with an alphanumeric character." unless $filename =~ m{^[a-zA-Z0-9]};

	return $filename;
}
	
sub _fileinfo_builder {
	my $self = shift;
	my $hash = $self->hash;
	$self->_service->_get_json("/mr/file/$hash/info")->{result};
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=attr hash

The hash of this file.

=method archive($archive_name)

Check if this file belongs to the archive C<$archive_name>.

=method download(%params)

Download the file from the snapshot service.

=over

=item archive_name

Name of the archive used when looking for the filename.
Defaults to C<"debian">.

=item directory

The name of the directory where the file should be stored.

=item filename

The filename to use.  If this option is not specified the method C<filename>
will be used to retrieve the filename.

=back

At least one of C<directory> and C<filename> must be given.

=method filename($archive_name)

Return the filename(s) of this file in the archive C<$archive_name>.  Will die
if there is no known filename or several filenames were want and the method is
called in scalar context.

=head1 SEE ALSO

L<Debian::Snapshot>
