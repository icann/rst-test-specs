#!perl
use Data::Dumper;
use YAML::XS;
use strict;

my $struct = YAML::XS::LoadFile($ARGV[0]);

my $cases = {};

foreach my $plan (keys %{$struct->{'Plans'}}) {
    foreach my $area (keys %{$struct->{'Plans'}->{$plan}->{'Test-Suites'}}) {
        foreach my $case (@{$struct->{'Plans'}->{$plan}->{'Test-Suites'}->{$area}}) {
            $cases->{$area}->{$case} = 1;
        }
    }
}

foreach my $area (keys %{$cases}) {
    my $i = {};

    foreach my $case (sort keys %{$cases->{$area}}) {
        $i->{$case} = {'Summary' => $struct->{'Test-Cases'}->{$case}->{'Summary'}};
    }

    YAML::XS::DumpFile("$area.yaml", $i);
}
