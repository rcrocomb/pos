#!/usr/bin/perl -w

use strict;
use File::Temp "tempfile";

sub
do_stuff
{
	my ($handle) = @_;
	while (<INPUT>) {
		# print "Before '$_' ";
		s/THINGTOREPLACE/NEWTHINGTOPUTTHERE/;
		# print  "After '$_'\n";
		print $handle "$_";
	}
}


sub
main
{
	my (@args) = @_;
	foreach my $file (@args) {
		if (! -e $file) {
			print "Ignoring non-existant '$file'\n";
			next;
		}

		if (-d $file) {
			print "Ignoring directory '$file'\n";
			next;
		}

#		print "Processing $file... ";
		my ($handle, $temp_filename) = tempfile();
#		print "Tempfile is at $temp_filename\n";

		open INPUT, "<$file" or die "Couldn't open $file: $!";
		do_stuff($handle);
		close INPUT or die "Couldn't close $file: $!";

		my $are_diff = `diff -q $temp_filename $file`;
		if ($are_diff) {
			my $result = `mv $temp_filename $file`;
			print "$file\t Fixed\n";
		} else {
			# else do nothing because didn't change: keep from willfully
			# mucking with mtime, etc. when didn't do anything
			# print "Nothing\n";
		}
		close $handle;
	}
}

################################################################################
# Execution begins here
################################################################################

main(@ARGV);
