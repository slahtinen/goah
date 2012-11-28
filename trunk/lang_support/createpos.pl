#!/usr/bin/perl -w
use strict;
use File::Find::Rule      ();
use File::Find::Rule::VCS ();
use IO::All;
use File::Path;

unless($ARGV[0]) {die print "Language parameter needed. Please run script like ./createpos.pl fi\n";}
unless(length($ARGV[0]) == 2) {die print "Language parameter lenght must be two characters.\n";}

my $lang = $ARGV[0];
my $podir = "../locale/$lang/po";

# Check directories which are needed for languages and create if necessary
unless (-d "../locale/$lang") {mkdir "../locale/$lang" or die print "$!\n";}
unless (-d "../locale/$lang/po") {mkdir "../locale/$lang/po" or die print "$!\n";}
unless (-d "../locale/$lang/LC_MESSAGES") {mkdir "../locale/$lang/LC_MESSAGES" or die print "$!\n";}

if (-d "../tmp/langfiles_tmp") {
		rmtree('../tmp/langfiles_tmp') or die print "$!\n";
		mkdir "../tmp/langfiles_tmp" or die print "$!\n";
}
else {mkdir "../tmp/langfiles_tmp" or die print "$!\n";}

# Create filelist from template core modules
print "\n*** Processing template core modules ***\n\n";

my @corefiles = File::Find::Rule
	->ignore_vcs('Subversion')
	->maxdepth(1)
	->mindepth(1)
	->file("*.tt2")
	->in("../templates");

foreach(@corefiles) {
	print "-> $_\n";
	io("../tmp/langfiles_tmp/GoaH")->append("$_\n");	
}

# Create filelist from template modules
print "\n*** Processing template modules ***\n\n";

my $templatemods = "../templates/modules";
my @subdirs = File::Find::Rule
	->ignore_vcs('Subversion')
	->maxdepth(1)
	->mindepth(1)
	->directory
	->in($templatemods);

foreach(@subdirs) {
	# Count files
	my $io = io("$_");
	my @f = $io->all_files;
	my $num = @f;

	# Exec only if we have files
	if (!$num == 0) {
		print "$_ contains $num files, processing ...\n";
		my @files = File::Find::Rule
			->ignore_vcs('Subversion')
			->file()
			->in($_);

		foreach(@files) {
			print "-> $_\n";
			my @tempmod = split('/', $_);
			io("../tmp/langfiles_tmp/$tempmod[3]")->append("$_\n");
		}
	}
	else {print "$_ does not contain files, skipping directory ...\n";}
}

# Add files from package modules to filelist
print "\n*** Processing package modules ***\n\n";

my $packagemods = "../goah/Modules";
my @pkgfiles = File::Find::Rule
	->ignore_vcs('Subversion')
	->maxdepth(1)
	->file
	->name('*.pm')
	->in($packagemods);

foreach(@pkgfiles) {
	my @pm = split('/',$_);

	print "-> $_\n";
	$pm[3] =~ s /\.pm//;
	io("../tmp/langfiles_tmp/$pm[3]")->append("$_\n");	
}

print "\n*** Creating .po files to ../locale/$lang/po ***\n";

my @pofiles = File::Find::Rule
	->ignore_vcs('Subversion')
	->maxdepth(1)
	->file
	->in("../tmp/langfiles_tmp");

foreach(@pofiles) {
	my @modn = split('/',$_);
	system("./xgettext.pl -w -f $_ -o ../locale/$lang/po/$modn[3].po");
}

print "\n*** Done, removing temporary folders... ***\n";

rmtree('../tmp/langfiles_tmp') or die print "$!\n";

unless(-d '../tmp/langfiles_tmp') {
	print "\n*** All Done ***\n";
}