use warnings;
use 5.010;
use File::Find;
use Cwd;
use File::Find;

$input_folder = "../grid1kmData_img";

my (%check);
find({wanted =>  \&process, no_chdir => 1}, $input_folder);

sub process {
	return unless -f $File::Find::name;
	my $new_file = s/pointData/1kmGrid/r;
	
	rename $File::Find::name, $new_file;
}


