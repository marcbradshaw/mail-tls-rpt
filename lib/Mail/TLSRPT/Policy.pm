package Mail::TLSRPT::Policy;
# ABSTRACT: TLSRPT policy object
# VERSION
use 5.20.0;
use Moo;
use Mail::TLSRPT::Pragmas;
use Mail::TLSRPT::Failure;
    has policy_type => (is => 'rw', isa => Enum[qw( tlsa sts no-policy-found )], required => 1);
    has policy_string => (is => 'rw', isa => ArrayRef, required => 1);
    has policy_domain => (is => 'rw', isa => Str, required => 1);
    has policy_mx_host => (is => 'rw', isa => Str, required => 1);
    has total_successful_session_count => (is => 'rw', isa => Int, required => 1);
    has total_failure_session_count => (is => 'rw', isa => Int, required => 1);
    has failures => (is => 'rw', isa => ArrayRef, required => 0, lazy => 1, builder => sub{return []} );

=head1 DESCRIPTION

Classes to process tlsrpt policy in a report

=head1 SYNOPSIS

my $policy = Mail::TLSRPT::Policy->new(
    policy_type => 'no-policy-found',
    policy_string => [],
    policy_domain => 'example.com',
    polixy_mx_host => 'mx.example.com',
    total_succerssful_session_count => 10,
    total_failure_session_count => 2,
    failures => $failures,
);

=constructor I<new($class)>

Create a new object

=constructor I<new_from_data($data)>

Create a new object using a data structure, this will create sub-objects as required.

=cut

sub new_from_data($class,$data) {
    my @failures;
    foreach my $failure ( $data->{'failure-details'}->@* ) {
        push @failures, Mail::TLSRPT::Failure->new_from_data($failure);
    }
    my $self = $class->new(
        policy_type => $data->{policy}->{'policy-type'},
        policy_string => $data->{policy}->{'policy-string'} // [],
        policy_domain => $data->{policy}->{'policy-domain'},
        policy_mx_host => $data->{policy}->{'mx-host'} // '',
        total_successful_session_count => $data->{summary}->{'total-successful-session-count'} // 0,
        total_failure_session_count => $data->{summary}->{'total-failure-session-count'} // 0,
        failures => \@failures,
    );
    return $self;
}

=method I<as_struct>

Return the current object and sub-objects as a data structure

=cut

sub as_struct($self) {
    my @failures = map {$_->as_struct} $self->failures->@*;
    return {
        policy => {
            'policy-type' => $self->policy_type,
            'policy-string' => $self->policy_string,
            'policy-domain' => $self->policy_domain,
            'mx-host' => $self->policy_mx_host,
        },
        summary => {
            'total-successful-session-count' => $self->total_successful_session_count,
            'total-failure-session-count' => $self->total_failure_session_count,
        },
        scalar $self->failures->@* ? ( 'failure_details' => \@failures ) : (),
    };
}

=method I<as_string>

Return a textual human readable representation of the current object and its sub-objects

=cut

sub as_string($self) {
    return join( "\n",
        'Policy:',
        ' Type: '.$self->policy_type,
        ' String: '. join('; ',$self->policy_string->@*),
        ' Domain: '.$self->policy_domain,
        ' MX-Host: '.$self->policy_mx_host,
        ' Successful-Session-Count: '.$self->total_successful_session_count,
        ' Failure-Session-Count: '.$self->total_failure_session_count,
        map { $_->as_string } $self->failures->@*,
    );
}

=method I<process_prometheus($prometheus,$report)>

Generate metrics using the given Prometheus::Tiny object

=cut

sub process_prometheus($self,$report,$prometheus) {
    $prometheus->declare('tlsrpt_sessions_total', help=>'TLSRPT tls sessions', type=>'counter' );
    $prometheus->add('tlsrpt_sessions_total',$self->total_successful_session_count,{result=>'successful', organization_name=>$report->organization_name, policy_type=>$self->policy_type, policy_domain=>$self->policy_domain, policy_mx_host=>$self->policy_mx_host});
    $prometheus->add('tlsrpt_sessions_total',$self->total_failure_session_count,{result=>'failure', organization_name=>$report->organization_name, policy_type=>$self->policy_type, policy_domain=>$self->policy_domain, policy_mx_host=>$self->policy_mx_host});
    foreach my $failure ( $self->failures->@* ) {
        $failure->process_prometheus($self,$report,$prometheus);
    }
}

sub _csv_headers($self) {
    return (
        'policy type',
        'policy string',
        'policy domain',
        'policy mx host',
        'total successful session count',
        'total failure session count',
    );
}

sub _csv_fragment($self) {
    return (
        $self->policy_type,
        join('; ',$self->policy_string->@*),
        $self->policy_domain,
        $self->policy_mx_host,
        $self->total_successful_session_count,
        $self->total_failure_session_count,
    );
}

1;

