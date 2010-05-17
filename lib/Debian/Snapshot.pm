package Debian::Snapshot;
# ABSTRACT: interface to snapshot.debian.org

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use Debian::Snapshot::Package;
use JSON ();
use LWP::UserAgent;

has 'user_agent' => (
	is      => 'rw',
	isa     => 'LWP::UserAgent',
	lazy    => 1,
	builder => '_build_user_agent',
);

has 'url' => (
	is      => 'rw',
	isa     => 'Str',
	default => 'http://snapshot.debian.org',
);

sub _build_user_agent {
	my $ua = LWP::UserAgent->new;
	$ua->agent("Debian-Snapshot/$Debian::Snapshot::VERSION ");
	$ua->env_proxy;
	return $ua;
}

sub _get {
	my $self = shift;
	my $url  = shift;
	$url = $self->url . $url;

	my $response = $self->user_agent->get($url, @_);

	die $response->status_line unless $response->is_success;
	return $response->decoded_content;
}

sub _get_json {
	my $self = shift;
	my $json = $self->_get(@_);
	return JSON::decode_json($json);
}

sub binaries {
	my ($self, $name, $version) = @_;

	my $json = $self->_get_json("/mr/binary/$name/");

	my @binaries = map $self->package($_->{source}, $_->{version})
	                        ->binary($_->{name}, $_->{binary_version}),
	                   @{ $json->{result} };

	@binaries = grep $_->binary_version eq $version, @binaries if defined $version;

	return \@binaries;
}

sub file {
	my ($self, $hash) = @_;
	Debian::Snapshot::File->new(
		hash     => $hash,
		_service => $self,
	);
}

sub package {
	my ($self, $package, $version) = @_;
	return Debian::Snapshot::Package->new(
		_service => $self,
		package => $package,
		version => $version,
	);
}

sub packages {
	my ($self) = @_;

	my $json = $self->_get_json("/mr/package/");
	my @package = map $_->{package}, @{ $json->{result} };

	return \@package;
}

sub package_versions {
	my ($self, $package) = @_;

	my $json = $self->_get_json("/mr/package/$package/");
	my @versions = map $_->{version}, @{ $json->{result} };
	return \@versions;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 SYNOPSIS

This module provides an interface to the snapshot.debian.org service.

=attr url

URL used to contact the snapshot service.
Defaults to C<http://snapshot.debian.org>.

=attr user_agent

The L<LWP::UserAgent|LWP::UserAgent> object used to query the server.

=method binaries($name, $version?)

Returns an arrayref of L<Debian::Snapshot::Binary|Debian::Snapshot::Binary>
object for the binary package named C<$name>.

If the optional parameter C<$version> is present, only return binaries whose
binary version matches C<$version>.

=method file($hash)

Returns a L<Debian::Snapshot::File|Debian::Snapshot::File> object for the file
with the given C<$hash>.

=method package($package, $version)

Returns a L<Debian::Snapshot::Package|Debian::Snapshot::Package> object for the
source package C<$package> version C<$version>.

=method packages

Returns an arrayref of source package names.

=method package_versions($package)

Returns an arrayref of versions for source package C<$package>.

=head1 SEE ALSO

L<http://snapshot.debian.org/>
