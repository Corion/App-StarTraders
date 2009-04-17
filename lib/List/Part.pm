package List::Part;
use strict;
use 5.010;
use Sub::Exporter -setup => {
    exports => [qw[ part grep_prioritized ]],
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

If no item matches a criterion, the criterion
does not exist in the result set.

For each item, smartmatchrules apply
for matching.

If no rule applies to an item, it will be discarded.

=cut

sub part {
    use feature ':5.10';
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

=head2 C<< grep_prioritized criteria, items >>

Scans a list and returns all things
matching the criteria 
prioritized after the criteria

    my $target = 'bar';
    print for grep_prioritized [
        qr/^\Q$target/, # prioritize matches at the beginning
        qr/\Q$target/   # over substring matches
    ], (qw[foo crossbar bartender ]);
    # prints
    # bartender crossbar

The list returned will not contain duplicates.

=cut

sub grep_prioritized {
    my $criteria = shift;
    my %seen = part $criteria, @_;
    return map { @{ $seen{ $_ }} } grep {exists $seen{$_}} @$criteria;
}

1;

__END__

=head1 AUTHOR

...