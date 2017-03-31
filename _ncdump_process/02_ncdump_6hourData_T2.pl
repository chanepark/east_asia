use warnings;
use 5.010;
# use Path::Tiny;
use File::Find;

my $target_variable = "T2";
my $timeScale = "wrfout";

my $input_folder = "I://data_climate_WRF_Raw";
my $check_folder = "O://data_climate_WRF_ncfTypeAscii";


my (%check,%new);
find({wanted => \&checking, no_chdir => 1}, $check_folder);
find({wanted =>  \&process, no_chdir => 1}, $input_folder);


sub checking {
    return unless -f $File::Find::name;
	my @name = split/\//;
	my $file_name = $name[-1];
	if ($file_name =~ /$target_variable/){
		$check{$file_name} = 1;
	}
}

sub process {
    return unless -f $File::Find::name;
	my @name = split/\//;
	my $check_file_name = $name[-1]."_".$target_variable.".txt";
	my $new_file_name   = $check_folder."/".$check_file_name;
	
	if ($File::Find::name =~ $timeScale){
		if ($check{$check_file_name}){
			# Do nothing
		}else{
			say $new_file_name;
			system("ncdump.exe  -v $target_variable -b c $File::Find::name > $new_file_name");
		}
	}
}


