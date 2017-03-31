use warnings;
use 5.010;
use File::Find;
use Cwd;

my @folders = glob("../grid1kmData_ascii/*/*/*");
# my @folders = glob("../grid1kmData_ascii/daily/rhum/*");

foreach my $year (sort {$a cmp $b} @folders){
	say $year;

	find({preprocess => sub { return sort grep { m/prj/ } @_ }, wanted => \&process, no_chdir => 1}, $year);

	sub process {
		return unless -f $File::Find::name;
		my @name = split(/\/|\./,$File::Find::name);
		
		my $prj_name = $name[-2];
		my $txt_old_name = lc($prj_name);
		
		my $txt_old_file_tmp = $File::Find::name =~ s/$prj_name/$txt_old_name/gr;
		my $txt_old_file = $txt_old_file_tmp =~ s/prj/txt/gr;
		
		my $txt_new_file = $txt_old_file =~ s/$txt_old_name/$prj_name/gr;

		say $txt_new_file;

		rename $txt_old_file, $txt_new_file;
		
	}
}


