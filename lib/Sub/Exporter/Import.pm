package Sub::Exporter::Import;
use strict;
use warnings;

our %DATA;

sub new {
    my $class = shift;
    my ( $import, $config ) = @_;
    my $self = bless( $import );
    $DATA{$self} = $config;
    return $self;
}

sub config {
    my $self = shift;
    return $DATA{ $self };
}

sub DESTROY {
    my $self = shift;
    delete $DATA{$self};
}

1;
