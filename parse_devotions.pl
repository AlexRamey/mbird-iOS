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
                    $months[9] => 31, $months[10] => 30, $months[11] => 31);
## outputs
my @dates = ();
my @verses = ();
my @verseTexts = ();
my @texts = ();
my @authors = ();

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
foreach my $monthIdx (0 .. $#months) {
    my $day = 1;
    while ($day <= $days_per_month{$months[$monthIdx]}) {
        push @dates, sprintf("2016-%02d-%02d", $monthIdx+1, $day);
        $day += 1;
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
## Everything before it is verseText and after it is devotion text. We then
## have to grab the author from the end of the devotion text.
my $devotion;
for $devotion (@devotions) {
    my $verseRegEx = '(.*)\((.+?)\)\s*\n';
    if ($devotion =~ m/$verseRegEx/) {
        push @verseTexts, $1;       # $1 refers to the text matched by the first (.+) group (back-ref)
        push @verses, $2;           # $2 refers to the text matched by the second (.+) group (back-ref)
        my $text = $';              # $' is the special postmatch variable
        $text =~ s/^\s+|\s+$//g;    # trim whitespace
        my $authorRegEx = '\n[^A-Za-z]*(.+?)$';
        if ($text =~ m/$authorRegEx/) {
            $text =~ s/$authorRegEx//g;
            push @texts, $text; 
            push @authors, $1;
        } else {
            die "author regex failed to match"
        }

    } else {
        die "verse regex failed to match";
    }
}

## Step 3: Output JSON
print "[";
foreach my $i (0 .. $#dates) {
    # Sanitize outputs by trimming whitespace and 
    # escaping double quotes, newlines, and tabs
    $dates[$i] =~ s/"/\\"/g;
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
    print "\t\t\"text\": \"$texts[$i]\",\n";
    print "\t\t\"author\": \"$authors[$i]\"\n";
    print ("\t}" . (($i eq "$#dates") ? "" : ","));
}
print "\n]\n";
