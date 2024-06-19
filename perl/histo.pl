#!/usr/bin/env perl

package p;

use strict;
use warnings;
use Getopt::Long;
use DateTime::Format::Strptime;

$p::NUMBER = "^\\s*\\d+(?:\.\\d+)?\$";

# Note: distinct from the strp-style parsing pattern in histo_of_dates, so
# they'd better match!
$p::DATETIME = "\\s*\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d{3})?.*";	# timezones, etc. on end

# TODO: can we unify the leading '\\s*' so I don't have to put it on each regex?
@p::patterns = ( $p::NUMBER, $p::DATETIME);

################################################################################
# Calculate population standard deviation of values in array 'aref' using
# the already-calculated average in 'mean'.  Obviously could calculate mean
# here, but I since I had it already, why not?
################################################################################

sub
calculate_sigma
{
	my ($mean, $aref) = @_;
	my $sum_of_distance = 0;
	if (scalar @$aref == 1) {
		return 0;
	}

	foreach my $size (@$aref) {
		my $diff = $size - $mean;
		my $square_of_difference = $diff * $diff;
		$sum_of_distance += $square_of_difference;
	}
	my $variance = $sum_of_distance / (scalar(@$aref) - 1);
	my $sigma = sqrt($variance);
	return $sigma;
}

sub
epoch_to_bucket_string {
	my ($dateunit, $value) = @_;

	my $strp = DateTime::Format::Strptime->new(
		pattern => '%s'
	);

	my $dt = $strp->parse_datetime($value);

	my $date_pattern = "";
	if ($dateunit eq "s") {
		$date_pattern = '%Y-%m-%dT%H:%M:%S';
	} elsif ($dateunit eq "m") {
		$date_pattern = '%Y-%m-%dT%H:%M';
	} elsif ($dateunit eq "h") {
		$date_pattern = '%Y-%m-%dT%H';
	} else {
		print "Whups: unhandled unit '$dateunit'\n";
	}

	# TODO: format string depends upon 'divisor', or *REALLY* on the
	my $strpout = DateTime::Format::Strptime->new(
		pattern => $date_pattern
	);

	my $thing = $strpout->format_datetime($dt);
#	print "Hello --> $value --> $thing\n";
	return $thing;
}

sub epoch_to_string
{
	my $v = shift;
	return epoch_to_bucket_string("s", $v);
}

sub
summarize_histogram
{
	my ($bucket_size, $hr, $opt) = @_;

# Wed Aug  8 14:53:58 MST 2018
# No bueno: we don't show empty bucket intervals.
	foreach my $diff (sort { $a <=> $b } keys %$hr)
	{
		# floating point bucket?
		if (int($bucket_size) != $bucket_size) {
			printf "[%5.2f] %5d\n", $diff, $$hr{$diff};
		} else {
			if (exists $$opt{'datehisto'}) {
				my $key = epoch_to_bucket_string($$opt{"dateunit"}, $diff);
				print "$key " . $$hr{$diff} . "\n";
			} else {
				print "$diff " . $$hr{$diff} . "\n";
			}
		}
	}
	print "--------------------------------------------------------------------------------\n";
}

sub
histo_of_numbers
{
	my ($bucket_size, $ar) = @_;
	my %histo = ();
	my $count = 0;
	my $sum = 0;
	my @values;

	my $max = 0;
	my $min = 1000;

	my @aref = @{ $ar };
	my $size = scalar(@aref);

	print "Size of array $size\n";

	for (my $i = 0; $i < $size; ++$i) {
		my $line = $aref[$i];
		chomp $line;
#		printf "[%2d] --> '%s'\n", $i, $line;

		my $bucket = int($line / $bucket_size) * $bucket_size;
#		print "$line --> $bucket\n";
		$histo{$bucket}++;

		++$count;
		$sum += $line;
		push @values, $line;
		if ($line < $min) {
			$min = $line;
		}
		if ($line > $max) {
			$max = $line;
		}
	}

	if ($count == 0) {
		die "Zero values in calculation: can't calculate mean: size " . $#aref;
	}

	my $mean = $sum / $count;
	my $sigma = calculate_sigma($mean, \@values);
	printf "Mean of $count values is %5.2f\n", $mean;
	printf "Standard deviation is %5.2f\n", $sigma;
	print "Min is $min\n";
	print "Max is $max\n";

	my %options = ();
	summarize_histogram($bucket_size, \%histo, \%options);
}


################################################################################
# Support bucketing date strings like
#
# 2021-09-09T19:12:09.375-07:00
# 2021-09-09T19:12:12.930-07:00
# 2021-09-09T19:12:28.885-07:00
# 2021-09-09T19:12:35.088-07:00
# 2021-09-09T19:12:41.179-07:00
#
# A real commandline.  Note that you can supply this timeunit option, but really
# only 'm' and 'h' do anything, well 'h' is the default, so 's', too, I guess.
#
#  $ cat srs_log_entries | jq  '.timestamp' | sort | sed -e s'/"//g' | histo.pl --unit h
# Bucket size --> 10
# [ 0] for pattern '^\d+$' with line 2021-09-09T19:12:09.375-07:00
# No match for ^\d+$
# [ 1] for pattern '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?.*' with line 2021-09-09T19:12:09.375-07:00
# Matched histo of dates
# Size of array: 205
# Mean of 205 values is 1631240679.63
# Standard deviation is 25195.54
# Min is   1631214729 -- 2021-09-09T19:12:09
# Max is   1631277697 -- 2021-09-10T12:41:37
# 2021-09-09T19 63
# 2021-09-09T20 43
# 2021-09-10T07 58
# 2021-09-10T11 7
# 2021-09-10T12 34
# --------------------------------------------------------------------------------
################################################################################

sub
histo_of_dates
{
	my ($ar, $bucket_size, $bucket_unit) = @_;
	my %histo = ();
	my $count = 0;
	my $sum = 0;
	my @values;

	my $max = 0;
	my $min = 2030 * 365 * 24 * 60 * 60 * 1000;

	my @aref = @{ $ar };
	my $asize = scalar @aref;
	print "Size of array: $asize\n";

	my $divisor = 1;
	if ($bucket_unit eq "s") {
		# nothing
	} elsif ($bucket_unit eq "m") {
		$divisor *= 60;
	} elsif ($bucket_unit eq "h") {
		$divisor *= 3600;
	} elsif ($bucket_unit eq "d") {
		# Ugh.  Just groupby on the 'd' field in the timestamp?  We
		# certainly can't divide by 86,400 unless we want the buckets
		# to simply be numbered!
		die("Whoops: TODO.  Implement bucketing at 'd'");
	} elsif ($bucket_unit eq "month") {
		die ("Month unsupported");
	} else {
		die("Unsupported unit '$bucket_unit'");
	}

	my $strp = DateTime::Format::Strptime->new(
		pattern => '%Y-%m-%dT%H:%M:%S',
	);

	for (my $i = 0; $i < $asize; ++$i) {
		my $line = $aref[$i];
		chomp $line;
#		printf "[%2d] --> '%s'\n", $i, $line;

		# TODO: is there a ms_since_epoch or ... ?
		# Note: no fractional seconds in ->epoch
		my $dt = $strp->parse_datetime($line);
		my $s = $dt->epoch;
#		printf "Got since epoch as " .  $s . "\n";

		my $bucket = int($s / $divisor) * $divisor;
#		print "$s belongs in bucket $bucket given size $divisor\n";
		$histo{$bucket}++;

		++$count;
		$sum += $s;
		push @values, $s;
		if ($s < $min) {
			$min = $s;
		}
		if ($s > $max) {
			$max = $s;
		}
	}

	my $mean = $sum / $count;
	my $sigma = calculate_sigma($mean, \@values);

	# TODO: turn mean back into datetime -- note fractional seconds!
	# TODO: see above: no fractional seconds right now

	printf "Mean of $count values is %5.2f\n", $mean;
	printf "Standard deviation is %5.2f\n", $sigma;
	printf "Min is %12d -- %s\n", $min, epoch_to_string($min);
	printf "Max is %12d -- %s\n", $max, epoch_to_string($max);

	my %options = ( "datehisto" => 1, 'dateunit' => $bucket_unit );
	summarize_histogram($divisor, \%histo, \%options);

}

sub main
{
	my ($bucket_size, $bucket_unit) = @_;

	my @stdin = <>;
	my $line = $stdin[0];
	chomp $line;


	# Which pattern matchs the first line?
	my $matched_pattern = 0;
	for (my $pattern_index = 0; !$matched_pattern && $pattern_index < scalar @p::patterns; ++$pattern_index) {
		my $result;
		my $pattern = $p::patterns[$pattern_index];

		printf "[%2d] for pattern '$pattern' with line --> '$line'\n", $pattern_index;

		if (!($result = $line =~ /$pattern/)) {
			print "No match for $pattern\n";
			next;
		}

#		print "Result is '$result' for '$line'\n";

		# matched: which one:
		if ($pattern eq $p::NUMBER) {
			print "Matched histo of numbers\n";
			histo_of_numbers($bucket_size,\@stdin);
			$matched_pattern = 1;
		} elsif ($pattern eq $p::DATETIME) {
			print "Matched histo of dates\n";
			histo_of_dates(\@stdin, $bucket_size, $bucket_unit);
		}
	}
}

################################################################################
# Execution starts here
################################################################################

my $bucket_size = 10;
my $bucket_unit = "h";
GetOptions(
	'bucket=f'	=> \$bucket_size,
	'unit=s'	=> \$bucket_unit);	# for *date* based histograms

print "Bucket size --> $bucket_size\n";
main($bucket_size, $bucket_unit);

