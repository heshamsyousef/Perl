use List::MoreUtils qw(uniq);
use File::Slurp;
use Data::Dump;
use Cwd qw(getcwd);
use lib  qw(C:\Users\yousefh\workspace-po\play_ground);
use Person;

my ($sorting_flag,$uniqu_flag) = @ARGV;
chdir 'c:\\temp\foo';
print  getcwd();
system 'pwd';
$sorting_flag='last';
chomp(my @lines1 = read_file("one.txt")); # will chomp() each line
chomp(my @lines2 = read_file("two.txt")); # will chomp() each line
my @lines1_sorted;

# $uniqu_flag 1 or 0
if ($uniqu_flag){
	my @unique_sorted_names1 = uniq @lines1;
	print  @unique_sorted_names1 ;
	my @unique_sorted_names2 = uniq @lines2;
	#print  @unique_sorted_names2 ;
}
my $person=Person->new(\@lines1);
my $sorted_names1=$person->sort_names($sorting_flag);
my $person2=Person->new(\@lines2);
my $sorted_names2=$person2->sort_names($sorting_flag);


open(FH, '>', 'merged_file.txt') or die $!;
foreach  (@$sorted_names1){print FH "$_\n";} 
print FH "\n";
foreach  (@$sorted_names2){print FH "$_\n";} 
close  FH;


