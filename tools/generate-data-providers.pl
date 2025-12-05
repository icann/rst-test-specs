#!/usr/bin/env perl
#
# this script generates a YAML fragment by parsing the XLSX files in the
# provided directory
#
# Usage: generate-data-providers.pl SRC > DST
#
use File::Basename qw(basename);
use File::Glob qw(:bsd_glob);
use HTML::Entities;
use Spreadsheet::XLSX;
use YAML::XS;
use constant FIRST_ROW => 6;
use strict;

my $extn = '.xlsx';

my $providers = {};

foreach my $file (grep { basename($_) !~ /^~/ } bsd_glob(sprintf('%s/*%s', $ARGV[0], $extn))) {
    my $id = basename($file, $extn);
    $providers->{$id} = parse_xlsx($file, $id);
}

my $yaml = YAML::XS::Dump($providers);
$yaml =~ s/^\-+\n//g;

print $yaml;

exit(0);

#
# parse an XLSX file and return a hashref suitable for inclusion in the fragment
#
sub parse_xlsx {
    my ($file, $id) = @_;

    my $sheet = Spreadsheet::XLSX->new($file)->{Worksheet}->[0];

    my $pos = FIRST_ROW;

    my @names = read_row($sheet, $pos);
    my @descs = read_row($sheet, ++$pos);
    my @types = read_row($sheet, ++$pos);

    my @rows;

    my $rc = 0;
    while ($pos < $sheet->{MaxRow}) {
        my @row = read_row($sheet, ++$pos);

        for (my $i = 0 ; $i < scalar(@row) ; $i++) {
            #
            # if the cell is empty, then use the value from the previous row
            #
            $row[$i] = $rows[$rc-1]->[$i] if (!defined($row[$i]) && $rc > 0);
        }

        push(@rows, \@row);

        $rc++;
    }

    for (my $i = 0 ; $i < $rc ; $i++) {
        unshift(@{$rows[$i]}, sprintf('%s-row-%s', $id, $i));
    }

    my @columns = ({
        Name        => 'RowID',
        Description => 'Unique ID for this row',
        Type        => 'string',
    });

    for (my $i = 0 ; $i < scalar(@names) ; $i++) {
        push(@columns, {
            Name        => $names[$i],
            Description => $descs[$i],
            Type        => $types[$i],
        });
    }

    return {
        Description => decode_entities($sheet->{Cells}->[1+$sheet->{MinRow}]->[$sheet->{MinCol}]->{Val}),
        Columns     => \@columns,
        Rows        => \@rows,
    };
}

#
# read a row of cells from the sheet
#
sub read_row {
    my ($sheet, $row) = @_;
    my @cells;

    for (my $i = $sheet->{MinCol} ; $i <= $sheet->{MaxCol} ; $i++) {
        my $cell = $sheet->{Cells}->[$row]->[$i];

        if (defined($cell->{Type}) && 'Text' ne $cell->{Type}) {
            die(sprintf("Invalid type '%s' at row %u, column %u", $row, $i));
        }

        push(@cells, $cell->{Val} ? decode_entities($cell->{Val}): undef);
    };

    return @cells;
}
