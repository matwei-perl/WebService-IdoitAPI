#!/usr/bin/env perl
#
use strict;
use warnings;
use 5.010;

use Getopt::Long;
use Pod::Usage;
use WebService::IdoitAPI::Object;

use version; # VERSION

sub get_answer {
    my ($config,$api,$query) = @_;

    my $answer = $api->request($query);

    return $answer;
} # get_answer()

sub get_query {
    my ($config) = @_;
    my ($json,$jsontext,$query);

    if (exists $config->{opt}->{file}
        and my $fname = $config->{opt}->{file}) {
        local $/ = undef;
        if ($fname eq '-') {
            $jsontext = <STDIN>;
        }
        else {
            open(my $fh,'<',$fname)
                or die "Can't open JSON query file '$fname': $!";
            $jsontext = <$fh>;
            close($fh);
        }
    }
    else {
        $jsontext = $ARGV[0];
    }
    $json = JSON->new();
    $query = $json->decode($jsontext);
    return $query;
} # get_query();

sub initialize {
    my $config = {};
    my $opt = {};
    GetOptions($opt, qw(
        config|c=s
        file|f=s
        pretty!
        help|h|? man version|V
    ));
    pod2usage(-exitstatus => 0, -input => \*DATA)       if $opt->{help};
    pod2usage(-exitstatus => 0, -input => \*DATA,
              -verbose => 2)                            if $opt->{man};
    pod2usage(-exitstatus => 0, -input => \*DATA,
              -verbose => 99, -sections => 'VERSION')   if $opt->{version};

    $config = WebService::IdoitAPI::read_config($opt->{config});

    $config->{opt} = $opt;

    return $config;
} # initialize()

sub print_json {
    my ($config,$data) = @_;

    my $json = JSON->new();

    if ( $config->{opt}->{pretty} ) {
        print $json->canonical->pretty->encode($data);
    }
    else {
        print $json->encode($data);
    }
} # print_json()

sub main {
    my ($api,$config,$data,$query);

    $config = initialize();
    $api = WebService::IdoitAPI->new($config);
    $query = get_query($config);
    $data = get_answer($config,$api,$query);
    if ($data->{is_success}) {
        print_json($config,$data->{content});
    }
    else {
        die "i-doit did not return success\n";
    }
} # main()

main() if not caller();

1;

__END__

=head1 NAME

idoit-query - query i-doit directly with JSON

=head1 SYNOPSIS

  idoit-query [options] [ json_query ]

  Options:
    --config path    - take i-doit credentials from file given in path
    --file queryfile - take query from file named queryfile
    --help / -?      - print a short help text and exit
    --man            - print the full man page and exit
    --version / -V   - print the version of the program and exit

=head1 CONFIGURATION FILE

This file should contain lines with a key and a value
separated by equal sign (I<=>) or colon (I<:>).
The key and the value may be enclosed
in single (I<'>) or double (I<">) quotation marks.
Leading and trailing white space is removed
as well as a comma (I<,>) at the the end of the line.

The program needs the following keys in the file:

=over 4

=item key

The API key for i-doit.

=item url

The URL of the i-doit instance.

=item username

The username for the login (optional).

=item password

The password for the login (optional).

=back

=head1 AUTHOR

Mathias Weidner C<< mamawe@cpan.org >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2024, Mathias Weidner C<< mamawe@cpan.org >>.
All rights reserved.

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

