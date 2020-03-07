package Mail::TLSRPT::Pragmas;
# ABSTRACT: Setup system wide pragmas
# VERSION
use 5.20.0;
use strict;
use warnings;
require feature;
use Import::Into;

use Carp;
use English;
use JSON;
use Types::Standard;
use Type::Utils;

use open ':std', ':encoding(UTF-8)';

=head1 DESCRIPTION

Setup system wide pragmas

=head1 SYNOPSIS

Included in all other modules to setup common pragmas and imports

=method I<import()>

Import standard pragmas and imports into current namespace

=cut

sub import {
  strict->import;
  warnings->import;
  feature->import($_) for ( qw{ postderef signatures } );
  warnings->unimport($_) for ( qw{ experimental::postderef experimental::signatures } );

  Carp->import::into(scalar caller);
  Types::Standard->import::into(scalar caller, qw{ Str Int HashRef ArrayRef Enum } );
  Type::Utils->import::into(scalar caller, qw{ class_type } );
  English->import::into(scalar caller);
  JSON->import::into(scalar caller);
}

1;

