use warnings;
use 5.010;
# use Path::Tiny;
use ;

my $input_folder = "../data_air-pollutant_RaW";
my $check_folder = "../data_air-pollutant_ncfTypeAscii";


my (%check,%new);
find({wanted => \&checking, no_chdir => 1}, $check_folder);
find({wanted =>  \&process, no_chdir => 1}, $input_folder);


sub checking {
	return unless -f $File::Find::name;
	my @name = split/\//;
	my $file_name = $name[-1];
	$check{$file_name} = 1;

}

sub process {
	return unless -f $File::Find::name;
	my @name = split/\/|\./;
	my $check_file_name = $name[-2].".txt";
	my $new_file_name   = $check_folder."/".$name[-2].".txt";

	if ($check{$check_file_name}){
		say "$check_file_name has ...";
	}else{
		# say $new_file_name;
		system("ncdump.exe  -b c $File::Find::name > $new_file_name");

	}
}




