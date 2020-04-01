package Mail::TLSRPT::App::Command::prometheus;
# ABSTRACT: Process tlsrpt reports into prometheus
# VERSION
use 5.20.0;
use Mail::TLSRPT::Pragmas;
use Mail::TLSRPT::App -command;
use Mail::TLSRPT::Report;

=head1 DESCRIPTION

App::Cmd class implementing the 'tlsrpt prometheus' command

=cut

sub abstract { 'Process tlsrpt files into prometheus' }
sub description { 'Process tlsrpt files and output as prometheus' };
sub usage_desc { "%c prometheus %o <FILE> <FILE> <FILE>" }

sub opt_spec {
  return (
    [ 'shared=s', 'Use the supplied Prometheus::Tiny::Shared store' ],
    [ 'output=s', 'Write results to filename (defaults to STDOUT)' ],
  );
}

sub validate_args($self,$opt,$args) {
 $self->usage_error ('Shared file not specified') if !$opt->{shared};
 # $self->usage_error('No files specified') if !@$args; # If no files are specified then we will output metrics from the shared file
}

sub execute($self,$opt,$args) {

  my $tlsrpt;

  eval {
      require Prometheus::Tiny::Shared;
      Prometheus::Tiny::Shared->VERSION(0.020) || die;;
  };
  $self->usage_error('Prometheus::Tiny::Shared 0.020 not found') if $@;

  my $prometheus = Prometheus::Tiny::Shared->new(filename=>$opt->shared);

  foreach my $file ( $args->@* ) {

    $self->usage_error("File $file does not exist") if ! -e $file;

    open my $fh, '<', $file or die 'Could not open input file';
    my @file_contents = <$fh>;
    close $fh;
    my $payload = join('',@file_contents);

    $tlsrpt = eval{ Mail::TLSRPT::Report->new_from_json($payload) };
    $tlsrpt //= eval{ Mail::TLSRPT::Report->new_from_json_gz($payload) };
    if ( $tlsrpt ) {
        $tlsrpt->process_prometheus($prometheus);
    }
    else {
        warn "Could not parse file $file\n";
    }

  }

  if ( $opt->output ) {
    open my $fh, '>', $opt->output or die 'Could not open output file';
    print $fh $prometheus->format;
    close $fh;
  }
  else {
    say $prometheus->format;
  }

}

1;

