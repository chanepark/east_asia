use warnings;
use 5.010;
use File::Path qw(make_path);
use Path::Tiny;

my $ref_folder = $ARGV[0];
my $rainc = $ARGV[1];
my $rainnc = $ARGV[2];
my $rainsh = $ARGV[3];
my $split_info = $ARGV[4];


my @files = path($ref_folder)->children( qr/\.txt$/ );

foreach $rainc_fileName (sort {$a cmp $b} @files){
	
	my $rainnc_fileName = $rainc_fileName =~ s/$rainc/$rainnc/gr;
	my $rainsh_fileName = $rainc_fileName =~ s/$rainc/$rainsh/gr;
	my $prcp_fileName = $rainc_fileName =~ s/$rainc/prcp/gr;
	
	
	my @prcp_folder = split($split_info,$prcp_fileName);
	
	$folder{prcp} = $prcp_folder[0];
	
	foreach my $folder_make (values (%folder)){
		# say $folder_make;
		if (-e $folder_make){
			# print "Directory exists.\n";
		}
		else{
			make_path($folder_make) or die "Error creating directory: $folder_make";
		}
	}

	
	open $rainc_file,"<", $rainc_fileName or die;
	open $rainnc_file,"<", $rainnc_fileName or die;
	open $rainsh_file,"<", $rainsh_fileName or die;
	
	next if (-f $prcp_fileName);
	say $rainc_fileName;
	
	open $prcp_file,">", $prcp_fileName or die;
	
	say {$prcp_file} "x,y,values";
	
	my %prcp;
	while(<$rainc_file>){
		chomp;
		next if $. == 1;
		my @arr = split/,/;
		next if ($#arr <= 1);
		my $x = $arr[0];
		my $y = $arr[1];
		my $values = $arr[2];
		if ($values =~ m/e/){
			$values = 0;
		}
		$prcp{$x}{$y} = $values;

	}	
	close $rainc_file;
	while(<$rainnc_file>){
		chomp;
		next if $. == 1;
		my @arr = split/,/;
		next if ($#arr <= 1);
		my $x = $arr[0];
		my $y = $arr[1];
		my $values = $arr[2];
		if ($values =~ m/e/){
			$values = 0;
		}
		if ($prcp{$x}{$y}){
			$prcp{$x}{$y} += $values;
		}
	}		
	close $rainnc_file;
	
	while(<$rainsh_file>){
		chomp;
		next if $. == 1;
		my @arr = split/,/;
		next if ($#arr <= 1);
		my $x = $arr[0];
		my $y = $arr[1];
		my $values = $arr[2];
		if ($values =~ m/e/){
			$values = 0;
		}		
		if ($prcp{$x}{$y}){
			$prcp{$x}{$y} += $values;
		}
		
	}	
	close $rainsh_file;
	
	foreach my $x (sort {$a cmp $b} keys(%prcp)){
		foreach my $y (sort {$a cmp $b} keys(%{$prcp{$x}})){
			say {$prcp_file} join(",",$x, $y, $prcp{$x}{$y});
		}
	}
	%prcp = ();
}

