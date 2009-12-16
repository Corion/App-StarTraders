package App::StarTraders::Demiurge::CommodityPresets;
use strict;
use List::MoreUtils qw(zip);

=head1 NAME

App::StarTraders::Demiurge::CommodityPresets - physical properties for commodities

=head1 DESCRIPTION

This module supplies the default values for the pysical properties
of commodities in the universe. Later on, it could
load these from a database instead of hardcoding these.

=cut

sub create_commodities {
    my ($self,%options) = @_;
    
    my $st = $options{ spacetime };
    
    my @names = qw(name weight volume);
    my @db = map {[ do {
                        /^\s*(\S.+?)\s+(\d+)\s+(\d+)\s*$/
                            or die "Invalid DB entry: [$_]";
                        my @values = ($1,$2,$3);
                        zip @names, @values
                    }
                  ]}
             grep {!/^\s*#/}
             split /\r?\n/, <<'DB';
    # Name              Weight          Volume
    Widgets             100             10
    Gadgets             100             20
    Ore                 100             20
    Ornamental Stones   1000            20
    Water                  1             1
    Energy                 0             1
DB

    for my $commodity (@db) {
        $st->new_commodity(@$commodity)
    }

    $st
}

1;