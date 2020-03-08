package Mail::TLSRPT::App::Command::csv;
# ABSTRACT: Process tlsrpt reports into csv
# VERSION
use 5.20.0;
use Mail::TLSRPT::Pragmas;
use Mail::TLSRPT::App -command;
use Mail::TLSRPT::Report;

=head1 DESCRIPTION

App::Cmd class implementing the 'tlsrpt csv' command

=cut

sub abstract { 'Process tlsrpt files into csv' }
sub description { 'Process tlsrpt files and output as csv' };
sub usage_desc { "%c csv %o FILE <FILE> <FILE>" }

sub opt_spec {
  return (
    [ 'output=s', 'Write results to filename (defaults to STDOUT)' ],
  );
}

sub validate_args($self,$opt,$args) {
  $self->usage_error('No files specified') if !@$args;
}

sub execute($self,$opt,$args) {

  my $tlsrpt;

  my @all_output;
  my $add_header = 1;

  foreach my $file ( $args->@* ) {

    $self->usage_error("File $file does not exist") if ! -e $file;

    open my $fh, '<', $file or die 'Could not open input file';
    my @file_contents = <$fh>;
    close $fh;
    my $payload = join('',@file_contents);

    $tlsrpt = eval{ Mail::TLSRPT::Report->new_from_json($payload) };
    $tlsrpt //= eval{ Mail::TLSRPT::Report->new_from_json_gz($payload) };
    $self->usage_error('Could not parse file') if !$tlsrpt;

    push @all_output, $tlsrpt->as_csv({add_header=>$add_header});
    $add_header = 0;

  }

  my $output= join("\n",@all_output);

  if ( $opt->output ) {
    open my $fh, '>', $opt->output or die 'Could not open output file';
    print $fh $output;
    close $fh;
  }
  else {
    say $output;
  }

}

1;


