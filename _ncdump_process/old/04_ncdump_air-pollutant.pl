use warnings;
use 5.010;

use Path::Tiny;

my @files = path("../nc")->children( qr/\.nc$/ );
open my $log_fh ,">", "ncdump_log.txt"
    or die "cannot open log file: $!";

foreach my $file (sort {$a cmp $b} @files) {
	say "processing $file ...";
	
	my @name = split(/\/|\./,$file);
	my $file_out = $name[-2];
	
	# 0 means success other value mean fail
	my $ret = system("ncdump.exe -b c $file > ../txt/${file_out}.txt");
	# -v $target_variable -b c $File::Find::name > $new_file_name
	# my $ret = system("ncdump.exe", "-o", "../txt/${file_out}.txt", $file);
	unless ( $ret == 0 ) {
		# fail
		print $log_fh "ncdump failed($ret): $file\n";
		next;
	}
}