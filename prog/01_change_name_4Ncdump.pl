use warnings;
use 5.010;
use File::Find;
use Cwd;

my @folders = glob("../data_climate_WRF_ncfTypeAscii/*");

foreach $year (@folders){
	# say $year;
	my (%F,@F);
	find({wanted => \&process, no_chdir => 1}, $year);
	close $F{$_} for keys %F;
	
	sub process {
		return unless -f $File::Find::name;
		my $old_name = $File::Find::name;

		if ($old_name =~ /validation.d01/){
			my $new_name = $File::Find::name;
			$new_name =~ s/on\./on_/g;
			$new_name =~ s/d01\./d01_/g;
			# say $new_name;
			rename $old_name, $new_name;
		}
		
	}
}


