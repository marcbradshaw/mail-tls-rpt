package Mail::TLSRPT::App::Command::process;
# ABSTRACT: Process a single tlsrpt file
# VERSION
use 5.20.0;
use Mail::TLSRPT::Pragmas;
use Mail::TLSRPT::App -command;
use Mail::TLSRPT::Report;

sub abstract { 'Process a single tlsrpt file' }
sub description { 'Process a single tlsrpt file and output as csv' };

sub opt_spec {
  return (
    [ 'file=s', 'tlsrpt report file to process' ],
    [ 'format=s', 'Output format (csv)' ],
    [ 'output=s', 'Write results to filename (defaults to STDOUT)' ],
  );
}

sub validate_args($self,$opt,$args) {
  # no args allowed but options!
  $self->usage_error('Must supply a filename') if ( !$opt->file );
  $self->usage_error('Supplied filename does not exist') if ( ! -e $opt->file );
  $self->usage_error('Must supply a format') if ( !$opt->format );

  $self->usage_error('Unknown format') if (!( $opt->format eq 'csv' ));

  $self->usage_error('No args allowed') if @$args;
}

sub execute($self,$opt,$args) {

  my $tlsrpt;

  open my $fh, '<', $opt->file or die 'Could not open input file';
  my @file_contents = <$fh>;
  close $fh;
  my $payload = join('',@file_contents);

  $tlsrpt = eval{ Mail::TLSRPT::Report->new_from_json($payload) };
  $tlsrpt //= eval{ Mail::TLSRPT::Report->new_from_json_gz($payload) };
  $self->usage_error('Could not parse file') if !$tlsrpt;

  my $output;
  $output = $tlsrpt->as_csv if $opt->format eq 'csv';

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


