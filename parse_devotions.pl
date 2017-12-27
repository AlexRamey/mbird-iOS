#!/usr/bin/perl

use strict;
use warnings;

## constants
my @months = ("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December");
my %days_per_month = ( $months[0] => 31, $months[1] => 29, $months[2] => 31,
                    $months[3] => 30, $months[4] => 31, $months[5] => 30, 
                    $months[6] => 31, $months[7] => 31, $months[8] => 30,
                    $months[9] => 31, $months[10] => 30, $months[11] => 31,);
## outputs
my @dates = ();
my @verses = ();
my @verseTexts = ();
my @texts = ();

## Step 1: Read input from stdin
my $devotionsText = "";
while (<>) {
$devotionsText .= $_;
}

## Step 2: Match the Input
## DATE
## VERSE_TEXT (VERSE)
## TEXT . . .
## TEXT CONTINUED . . .
## DATE
my $month;
for $month (@months) {
    my $dayCounter = 1;
    while ($dayCounter < $days_per_month{$month} + 1) {
        my $currentDate = "$month $dayCounter";
        push @dates, $currentDate;
        $dayCounter += 1;
    }
}

# could split on dates . . . 
# todo: match first line after each date
# todo: match verse at end of first line of each date
# todo: match everything between first line and next date or end of string

foreach my $i (0 .. $#dates) {
    my $firstDate = $dates[$i];
    my $secondDate = $i == $#dates ? "" : $dates[$i+1];
    my $regEx = "$firstDate";
    print($regEx);
    if ($devotionsText =~ m/$regEx/) {
        print($1);
        die "WIN!";
    } else {
        die "ERROR!";
    }
}
