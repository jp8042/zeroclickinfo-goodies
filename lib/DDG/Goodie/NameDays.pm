package DDG::Goodie::NameDays;
# ABSTRACT: Display Name Days for a given name or date

use utf8;
use strict;
use DateTime;
use DDG::Goodie;
with 'DDG::GoodieRole::Dates';

zci answer_type => "name_days_w25";
zci is_cached   => 1;

# Metadata
name "Name Days";
source "https://en.wikipedia.org/wiki/Name_days_in_Poland";
description "Name Days for a given name or date";
primary_example_queries "name day Maria", "1 June name day";
secondary_example_queries "name days today", "imieniny 9 stycznia", "imieniny Marii";
category "dates";
topics "social", "everyday";
code_url "https://github.com/duckduckgo/zeroclickinfo-goodies/blob/master/lib/DDG/Goodie/NameDays/W25/W25.pm";
attribution github => ["http://github.com/W25", "W25"];

# Triggers
triggers any => "name day", "name days", "nameday", "namedays", "imieniny", "jmeniny", "svátek";



# Load the data file
my @names = share('preprocessed_names.txt')->slurp(iomode => '<:encoding(UTF-8)', chomp => 1); # Names indexed by day
my %dates = share('preprocessed_dates.txt')->slurp(iomode => '<:encoding(UTF-8)', chomp => 1); # Days indexed by name


sub parse_other_date_formats {
    # Quick fix for the date formats not supported by parse_datestring_to_date.
    # If parse_datestring_to_date will be improved, you can remove some of the following code.
    
    # US date format ("month/day")
    if (/^([0-1]?[0-9])\s?\/\s?([0-3]?[0-9])$/) {
        # Suppress errors for invalid dates with eval
        return eval { new DateTime(year => 2000, day => $2, month => $1) };
    }
    
    # Polish date format ("day.month")
    if (/^([0-3]?[0-9])\s?\.\s?([0-1]?[0-9])$/) {
        return eval { new DateTime(year => 2000, day => $1, month => $2) };
    }
        
    # Polish month names
    s/\b(styczeń|stycznia)\b/Jan/i;
    s/\b(luty|lutego)\b/Feb/i;
    s/\b(marzec|marca)\b/Mar/i;
    s/\b(kwiecień|kwietnia)\b/Apr/i;
    s/\b(maj|maja)\b/May/i;
    s/\b(czerwiec|czerwca)\b/Jun/i;
    s/\b(lipiec|lipca)\b/Jul/i;
    s/\b(sierpień|sierpnia)\b/Aug/i;
    s/\b(wrzesień|września)\b/Sep/i;
    s/\b(październik|października)\b/Oct/i;
    s/\b(listopad|listopada)\b/Nov/i;
    s/\b(grudzień|grudnia)\b/Dec/i;
    
    # Czech month names
    s/\b(leden|ledna)\b/Jan/i;
    s/\b(únor|února)\b/Feb/i;
    s/\b(březen|března)\b/Mar/i;
    s/\b(duben|dubna)\b/Apr/i;
    s/\b(květen|května)\b/May/i;
    s/\b(červen|června)\b/Jun/i;
    s/\b(červenec|července)\b/Jul/i;
    s/\b(srpen|srpna)\b/Aug/i;
    s/\b(září)\b/Sep/i;
    s/\b(říjen|října)\b/Oct/i;
    s/\b(listopad|listopadu)\b/Nov/i;
    s/\b(prosinec|prosince)\b/Dec/i;
    
    # Parse_datestring_to_date uses the current year if the year is not specified, so
    # it will not parse "29 Feb" in a non-leap year. Fix this problem here.
    if (/^29\s?(?:th)?\s*(Feb|February)/ || /(Feb|February)\s*29\s?(?:th)?$/) {
        return new DateTime(year => 2000, day => 29, month => 2);
    }
    
    return parse_datestring_to_date($_);
}



# Handle statement
handle remainder => sub {
    my $text;
    
    if (exists $dates{lc($_)}) {
        # Search by name first
        $text = $dates{lc($_)};
    } else {
        # Then, search by date
        my $day = parse_datestring_to_date($_);

        if (!$day) {
            $day = parse_other_date_formats($_);
        }

        return unless $day;

        # Any leap year here, because the array includes February, 29
        $day->set_year(2000);

        $text = $names[$day->day_of_year() - 1];
    }
    
    # Convert to HTML
    my $html = $text;
    $html =~ s/(^|; )(.*?:)/$1<b>$2<\/b>/g;
    
    return $text, html => $html;
};

1;
