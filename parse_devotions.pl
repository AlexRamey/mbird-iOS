#!/usr/bin/perl
# Note: Be sure to replace smart, curly quotes with straight double quotes in the input file
# before passing it through this script
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
## NEXT DATE
### . . .

## Build array of all date strings
my $month;
for $month (@months) {
    my $dayCounter = 1;
    while ($dayCounter <= $days_per_month{$month}) {
        my $currentDate = "$month $dayCounter";
        push @dates, $currentDate;
        $dayCounter += 1;
    }
}

## Split the text on dates
my $regEx = join(" \\d+\\s|", @months) . " \\d+\\s";
my @devotions = split(/$regEx/, $devotionsText);
shift @devotions; # Knock off whatever preceded the first date (probably empty string)

if ($#devotions != 365) {
    die "Did not find 366 devotions! Did someone forget about February 29th!!!";
}

## For each devotion, grab the verseText, verse, and text
## Strategy, just match the verse itself, which is in parentheses at end of line 1
## Then leverage the prematch and postmatch variables to get the verseText and devotion text.
my $devotion;
for $devotion (@devotions) {
    my $verseRegEx = '\((.+)\)\s';
    if ($devotion =~ m/$verseRegEx/) {
        push @verseTexts, $`;   # $` is the special prematch variable
        push @verses, $1;       # $1 refers to the text matched by the (.+) group (back-ref)
        push @texts, $';        # $` is the special postmatch variable
    } else {
        die "verse regex failed to match";
    }
}

## Step 3: Output JSON
print "[";
foreach my $i (0 .. $#dates) {
    # Sanitize outputs by replacing double quotes with single quotes
    # and trimming trailing/leading whitespace
    $dates[$i] =~ s/"/'/g;
    $dates[$i] =~ s/^\s+|\s+$//g;
    $verses[$i] =~ s/"/\\"/g;
    $verses[$i] =~ s/^\s+|\s+$//g;
    $verseTexts[$i] =~ s/"/\\"/g;
    $verseTexts[$i] =~ s/^\s+|\s+$//g;
    $verseTexts[$i] =~ s/\n/\\n/g;
    $texts[$i] =~ s/"/\\"/g;
    $texts[$i] =~ s/^\s+|\s+$//g;
    $texts[$i] =~ s/\t/\\t/g;
    $texts[$i] =~ s/\n/\\n/g;
    print "\n\t{\n";
    print "\t\t\"date\": \"$dates[$i]\",\n";
    print "\t\t\"verse\": \"$verses[$i]\",\n";
    print "\t\t\"verseText\": \"$verseTexts[$i]\",\n";
    print "\t\t\"text\": \"$texts[$i]\"\n";
    print ("\t}" . (($i eq "$#dates") ? "" : ","));
}
print "\n]\n";