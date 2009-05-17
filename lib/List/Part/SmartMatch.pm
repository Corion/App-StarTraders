package List::Part::SmartMatch;
use strict;
use 5.010;
use Sub::Exporter -setup => {
    exports => [qw[ part parta ]],
};

=head1 NAME

List::Part - routine for partitioning lists

=head1 SYNOPSIS

  use List::Part qw(part);

=cut

=head2 C<< part criteria, items >>

Parts a list according to the criteria given. Returns
a list of pairs combining each criterion
with an arrayref containing the found items.

Each item will be in at most one of the lists returned.

If no rule applies to an item, it will be discarded.
If you want the results to include a "rejects" array,
add an empty regex (qr//) to the end of the arrayref.

If no item matches a criterion, the criterion
does not exist in the result set.

For each criterion and item, smartmatchrules apply
for matching.

The items will retain their
relative order in the sublists.

=cut

sub part($@) {
    my $criteria = shift;
    my %result;
    for (@_) {
        CRIT: for my $c (@$criteria) {
            if ( $_ ~~ $c ) {
                push @{ $result{ $c } ||= [] }, $_;
                last CRIT
            }
        }
    }
    %result
}

=head2 C<< sortp criteria, items >>

Scans a list and returns all things
matching the criteria 
prioritized after the criteria.
The criteria are applied using smartmatch rules.

    my $target = 'bar';
    print for parta [
        qr/^\Q$target/, # prioritize matches at the beginning
        qr/\Q$target/   # over substring matches
    ], (qw[foo crossbar bartender ]);
    # prints
    # bartender crossbar

=cut

sub sortp($@) {
    my $criteria = shift;
    my %seen = part $criteria, @_;
    return map { @{ $seen{ $_ }} } grep {exists $seen{$_}} @$criteria;
}

1;

__END__

=head1 AUTHOR

...