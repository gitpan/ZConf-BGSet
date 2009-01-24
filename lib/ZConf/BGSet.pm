package ZConf::BGSet;

use warnings;
use strict;
use Image::Size::FillFullSelect;
use ZConf;
use File::Spec;

=head1 NAME

ZConf::BGSet - A perl module for background management.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

    use ZConf::BGSet;

    my $zbg = ZConf::BGSet->new();
    ...

=head1 METHODES

=head2 new

This initializes it.

One arguement is taken and that is a hash value.

=head3 hash values

=head2 autoinit

If this is set to true, it will automatically call
init the set and config. If this is set to false or
not defined, besure to check '$zbg->{init}' to see
if the config/module has been initiated or not.

=head2 set

This is the set to load initially.

=head4 zconf

If this key is defined, this hash will be passed to ZConf->new().

    my $zbg=ZConf::Runner->new();
    if($zbg->{error}){
        print "Error!\n";
    }

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	my $self={error=>undef, errorString=>undef};
	bless $self;

	#this sets the set to undef if it is not defined
	if (!defined($args{set})) {
		$self->{set}=undef;
	}else {
		$self->{set}=$args{set};
	}

	#this sets the set to undef if it is not defined
	if (!defined($args{autoinit})) {
		$self->{autoinit}=undef;
	}else {
		$self->{autoinit}=$args{set};
	}

	#this is done to keep from throwing an error when we try to pass it to ZConf->new
	if (!defined($args{zconf})) {
		$args{zconf}={};
	}

	#creates the ZConf object
	$self->{zconf}=ZConf->new(%{$args{zconf}});
	if(defined($self->{zconf}->{error})){
		warn("ZConf-BGSet new:1: Could not initiate ZConf. It failed with '"
			 .$self->{zconf}->{error}."', '".$self->{zconf}->{errorString}."'");
		$self->{error}=1;
		$self->{errorString}="Could not initiate ZConf. It failed with '"
		                      .$self->{zconf}->{error}."', '".
							  $self->{zconf}->{errorString}."'";
		return $self;
	}

	#create the config if it does not exist
	#if it does exist, make sure the set we are using exists
    $self->{init} = $self->{zconf}->configExists("zbgset");
	if($self->{zconf}->{error}){
		warn("ZConf-BGSet new:2: Could not check if the config 'zbgset' exists.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=2;
		$self->{errorString}="Could not check if the config 'zbgset' exists.".
	   		                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return $self;
	}

	#if it is not inited, check to see if it needs to do so
	if (!$self->{init} && $self->{autoinit}) {
		$self->init($self->{set});
		if ($self->{error}) {
			warn('ZConf-BGset new:4: Autoinit failed.');
		}else {
			#if init works, it is now inited and thus we set it to one
			$self->{init}=1;
		}
		#we don't set any error stuff here even if the above action failed...
		#it will have been set any ways by init methode
		return $self;
	}

	#checks it is set to use the default set
	#use defined as '0' is a legit set name and is a perl boolean for false
	if (!defined($self->{set})) {
		$self->{init}=$self->{zconf}->defaultSetExists('zbgset');
		if($self->{zconf}->{error}){
			warn("ZConf-BGSet new:2: defaultSetExists failed for 'zbgset'.".
				 " It failed with '".$self->{zconf}->{error}."', '"
				 .$self->{zconf}->{errorString}."'");
			$self->{error}=2;
			$self->{errorString}="defaultSetExists failed for 'zbgset'.".
	   		                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
			return $self;
		}
	}

	#check it if it set to use a specific set
	#use defined as '0' is a legit set name and is a perl boolean for false
	if (defined($self->{set})) {
		$self->{init}=$self->{zconf}->setExists('zbgset', $self->{set});
		if($self->{zconf}->{error}){
			warn("ZConf-BGSet new:2: defaultSetExists failed for 'zbgset'.".
				 " It failed with '".$self->{zconf}->{error}."', '"
				 .$self->{zconf}->{errorString}."'");
			$self->{error}=2;
			$self->{errorString}="defaultSetExists failed for 'zbgset'.".
	   		                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
			return $self;
		}
	}

	#the first one does this if the config has not been done yet
	#this one does it if the set has not been done yet
	#if it is not inited, check to see if it needs to do so
	if (!$self->{init} && $self->{autoinit}) {
		$self->init($self->{set});
		if ($self->{error}) {
			warn('ZConf-BGset new:4: Autoinit failed.');
		}else {
			#if init works, it is now inited and thus we set it to one
			$self->{init}=1;
		}
		#we don't set any error stuff here even if the above action failed...
		#it will have been set any ways by init methode
		return $self;
	}

	#reads it if it does not need to be initiated
	if ($self->{init}) {
		$self->{zconf}->read({set=>$self->{set}, config=>'zbgset'});
	}

	return $self;
}

=head2 addToLast

This adds an item to the history.

=head3 args hash

=head4 hostname

This specifies the hostname to use. If this is not defined,
the hostname of the machine it is currently running on
will be used.

=head4 display

This is the X display the BG was set on. If it is not set,
the enviromental variable 'DISPLAY' is used.

=head4 filltype

This is the fill type that was used.

=head4 image

This is the image the background was set to.

    $zbg->addToLast({image=>'/tmp/something.jpg', filltype=>'full'});
    if($zbg->{error}){
        print "Error!\n";
    }

=cut

sub addToLast{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	$self->errorblank;

	#gets the hostname if it is not specified
	if (!defined($args{hostname})) {
			#gets the hostname
		$args{hostname}=`hostname`;
		if(!defined($args{hostname})){
			$args{hostname}="localhost";
		}else{
			chomp($args{hostname});
		};
	}

	#make sure display is defined can be found
	if (!defined($args{display})) {
		if (!defined($ENV{DISPLAY})) {
			warn('ZConf-BGSet addToLast:8: $args{display} or $ENV{DISPLAY} not defined');
			$self->{error}=8;
			$self->{errorString}='$args{display} or $ENV{DISPLAY} not defined';
			return undef;
		}
		$args{display}=$ENV{DISPLAY};
	}

	#error if the filltype is not specified
	if (!defined($args{filltype})) {
		warn('ZConf-BGSet addToLast:5: $args{filltype} is not defined');
		$self->{error}=5;
		$self->{errorString}='$args{filltype} is not defined';
		return undef;		
	}

	#error if the image is specified
	if (!defined($args{image})) {
		warn('ZConf-BGSet addToLast:5: $args{image} is not defined');
		$self->{error}=5;
		$self->{errorString}='$args{image} is not defined';
		return undef;		
	}

	#make sure a legit filltype is specified
	if (!$self->validSetterName($args{filltype})) {
		warn('ZConf-BGSet addToLast:6: "'.$args{filltype}.'" is not a valid setter name');
		$self->{error}=6;
		$self->{errorString}='"'.$args{filltype}.'" is not a valid setter name.';
		return undef;
	}

	#errors if : is found in the hostname
	if ($args{hostname} =~ /:/) {
		warn('ZConf-BGSet addToLast:9: Hostname contains ":"');
		$self->{error}=9;
		$self->{errorString}='Hostname contains ":".';
		return undef;
	}

	#make sure it is a legit display name
	if (!$args{display} =~ /^:[[:digit:]]*\.[[:digit:]]*$/) {
		warn('ZConf-BGSet addToLast:10: Invalid display name');
		$self->{error}=10;
		$self->{errorString}='Invalid display name.';
		return undef;		
	}

	#this builds the last line that will be added
	my $lastline=$args{hostname}.$args{display}.':'.$args{filltype}.':'.$args{image};
	my $last=$lastline."\n".$self->getLastRaw;

	#breaks it apart and rebuilds it
	my @lastSplit=split(/\n/, $last);
	my $newlast='';
	my $int=0;
	while (defined($lastSplit[$int])) {
		if ($int <= $self->{zconf}->{conf}->{zbgset}->{numberoflast}) {
			$newlast=$newlast.$lastSplit[$int]."\n";
		}

		$int++;
	}	

	chomp($newlast);

	$self->{zconf}->{conf}{zbgset}{last}=$newlast;

	$self->{zconf}->writeSetFromLoadedConfig({config=>'zbgset'});

	return 1;
}


=head2 getLastRaw

Gets the last variable in it's raw form.

No arguements are taken.

It also does not have to be checked for errors as it
will never set an error.

For a description of it's formatting, please see 

    my $rawlast=$zbg->getLastRaw();
    print $rawlast;

=cut

sub getLastRaw{
	my $self=$_[0];

	#returns it if last has been removed for some bloody reason
	if (!defined($self->{zconf}->{conf}->{zbgset}->{last})) {
		return '';
	}

	#return the last
	return $self->{zconf}->{conf}->{zbgset}->{last};
}

=head2 getSetter

This fetches a setter.

The only image accepted is the name of the setter to fetch.

    my $setter=$zbg->getSetter('full');
    if($zbg->{error}){
        print "Error!\n";
    }

    #escapes the image
    my $image='/tmp/something.jpg';
    $image=~s/(["`\$\\ ])/\\$1/g;
    $image=~qq($image);

    #replaces %%%THEFILE%%% in the setter with the filename
    $setterr=~s/\%\%\%THEFILE\%\%\%/$image/g;

=cut

sub getSetter{
	my $self=$_[0];
	my $name=$_[1];

	#blanks any previous errors
	$self->errorblank;

	if (!$self->validSetterName($name)) {
		warn('ZConf-BGSet getSetter:6: "'.$name.'" is not a valid setter name');
		$self->{error}=6;
		$self->{errorString}='"'.$name.'" is not a valid setter name.';
		return undef;
	}

	if (!defined($self->{zconf}->{conf}->{zbgset}->{$name})) {
		warn('ZConf-BGSet getSetter:7: "'.$name.'" does not exist');
		$self->{error}=7;
		$self->{errorString}='"'.$name.'" does not exist.';
		return undef;
	}

	return $self->{zconf}->{conf}->{zbgset}->{$name};
}

=head2 init

This initializes it or a new set.

If the specified set already exists, it will be reset.

One arguement is required and it is the name of the set. If
it is not defined, ZConf will use the default one.

    #creates a new set named foo
    $zbg->init('foo');
    if($zbg->{error}){
        print "Error!\n";
    }

    #creates a new set with ZConf choosing it's name
    $zbg->init();
    if($zbg->{error}){
        print "Error!\n";
    }

=cut

sub init{
	my $self=$_[0];
	my $set=$_[1];

	#blanks any previous errors
	$self->errorblank;

	my $returned = $self->{zconf}->configExists("zbgset");
	if(defined($self->{zconf}->{error})){
		warn("ZConf-BGSet init:2: Could not check if the config 'zbgset' exists.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=2;
		$self->{errorString}="Could not check if the config 'zbgset' exists.".
		                     " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return undef;
	}

	#create the config if it does not exist
	if (!$returned) {
		$self->{zconf}->createConfig("zbgset");
		if ($self->{zconf}->{error}) {
			warn("ZConf-BGSet init:2: Could not create the ZConf config 'zbgset'.".
				 " It failed with '".$self->{zconf}->{error}."', '"
				 .$self->{zconf}->{errorString}."'");
			$self->{error}=2;
			$self->{errorString}="Could not create the ZConf config 'zbgset'.".
			                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
			return undef;
		}
	}

	#create the new set
	$self->{zconf}->writeSetFromHash({config=>"zbgset", set=>$set},
							 {
							  savelast=>"true",
							  filltype=>"auto",
							  numberoflast=>"15",
							  postSetRefresh=>"false",
							  postSetRefresher=>"zbgfbmb -l",
							  maxdiff=>".2",
							  filltype=>"auto",
							  full=>'hsetroot -full \'%%%THEFILE%%%\'',
							  tile=>'hsetroot -tile \'%%%THEFILE%%%\'',
							  fill=>'hsetroot -fill \'%%%THEFILE%%%\'',
							  center=>'hsetroot -center \'%%%THEFILE%%%\'',
							  path=>'default'
							  }
							 );
	#error if the write failed
	if ($self->{zconf}->{error}) {
		warn("ZConf-BGSet init:2: writeSetFromHash failed.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=2;
		$self->{errorString}="writeSetFromHash failed.".
			                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return undef;
	}

	return 1;
}

=head2 listPaths

This gets a lists of configured paths.

    my @paths=$zbg->listPaths();
    if($zbg->{error}){
        print "Error!\n";
    }

=cut

sub listPaths{
	my $self=$_[0];

	#blanks any previous errors
	$self->errorblank;

	my @paths=$self->{zconf}->regexVarGet('zbgset', '^paths/');
	if ($self->{zconf}->{error}) {
		warn("ZConf-BGSet listPaths:2: regexVarGet failed.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=2;
		$self->{errorString}="writeSetFromHash failed.".
			                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return undef;
	}

	return @paths;
}

=head2 pathExists

This verifies a path exists.

Only one arguement is taken and that is the name of the path.

    my $returned=$zbg->pathExists('foo');
    if($zbg->{error}){
        print "Error!\n";
    }else{
        if(!$returned){
            print "The path 'foo' does not exist.\n";
        }
    }

=cut

sub pathExists{
	my $self=$_[0];
	my $path=$_[1];

	#blank any previous errors
	$self->errorblank;

	#error if no path is specified
	if (!defined($path)) {
		warn('ZConf-BGSet pathExists:5: The path is undefined');
		$self->{error}=5;
		$self->{errorString}='The path is undefined.';
		return undef;
	}

	#set fullpath to the full variable name
	my $fullpath='paths/'.$path;

	#if it is not defined, return undef
	if (!defined($self->{zconf}->{conf}->{zbgset}->{$fullpath})) {
		return undef;
	}

	return 1;
}

=head2 setBG

=head3 args hash

=head4 image

The picture to set the background to.

=head4 filltype

The fill type to use. If this is not defined, the default one
will be used.

=head4 dontSave

If this is set to true, it will not be added to the last list.

    $zbg->setBG({image='/tmp/something.jpg', filltype=>'auto'});
    if($zbg->{error}){
        print "Error!\n";
    }

    #the same as the above, but not saved to the last list
    $zbg->setBG({image='/tmp/something.jpg', filltype=>'auto', dontSave='0'});
    if($zbg->{error}){
        print "Error!\n";
    }

=cut

sub setBG{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	#default to the default filltype if none is specified
	if (!defined($args{filltype})) {
		$args{filltype}=$self->{zconf}->{conf}->{zbgset}->{filltype};
	}

	#error if no image is specified
	if (!defined($args{image})) {
		warn('ZConf-BGSet setBG:5: $args{image} is not specified');
		$self->{error}=5;
		$self->{errorString}='$args{image} is not specified.';
		return undef;		
	}

	#get the absolute path
	$args{image}=File::Spec->rel2abs($args{image});

	my $origimage=$args{image};

	#error if it does not exist or is not a file
	if (! -f $args{image}) {
		warn('ZConf-BGSet setBG:13: "'.$args{image}.'" does not exist or is not a file');
		$self->{error}=13;
		$self->{errorString}='"'.$args{image}.'" does not exist or is not a file.';
		return undef;		
	}

	#get the filltype if it is set to auto
	if ($args{filltype} eq 'auto') {
		my $iffs = Image::Size::FillFullSelect->new();
		$args{filltype} = $iffs->select($args{image});
		if(!defined($args{filltype})){
			warn("ZConf-BGSet setBG:7: Auto selection for the image size failed. Image::Size".
				"does not regard the file, '".$args{image}."', as a image");
			exit 7;
		};
	}

	#gets the setter and verify it is a legit one
	my $setter=$self->getSetter($args{filltype});
	if ($self->{error}) {
		warn('ZConf-BGSet setBG: getSetter failed');
		return undef;
	}

	#escapes it
	$args{image}=~s/(["`\$\\ ])/\\$1/g;
	$args{image}=~qq($args{image});

	#replaces %%%THEFILE%%%% with the image
	$setter=~s/\%\%\%THEFILE\%\%\%/$args{image}/g;

	#run it
	system($setter);

	#gets the exit code
	my $exitcode=$? >> 8;

	if ($? eq '-1') {
		warn('ZConf-BGSet setBG:12: Failed to execute the setter, "'.$setter.'",');
		$self->{error}=12;
		$self->{errorString}='Failed to execute the setter, "'.$setter.'".';
		return undef;
	}

	if ($exitcode > 0) {
		warn('ZConf-BGSet setBG:12: The setter, "'.$setter.'", exited with a non-zero');
		$self->{error}=12;
		$self->{errorString}='The Ssetter, "'.$setter.'", exited with a non-zero.';
		return undef;
	}

	#only add it to last if we need to
	if (!$args{dontSave}) {
		$self->addToLast({image=>$origimage,filltype=>$args{filltype}});
		if ($self->{error}) {
			#we don't set any error numbers here as addToLast already did
			warn('ZConf-BGSet setBG: addToLast failed');
			return undef;
		}
	}

	return 1;
}

=head2 setLast

This sets the background image to last. It will also not re-append th
e image to the last list.

No arguements are accepted.

    $zbg->setLast();
    if($zbg->{error}){

    }

=cut

sub setLast{
	my $self=$_[0];

	my $lastraw=$self->getLastRaw;

	$lastraw=~s/\n.*//g;

	my @lastA=split(/:/, $lastraw,4);

	$self->setBG({image=>$lastA[3], filltype=>$lastA[2], dontSave=>1});
	if ($self->{error}) {
		warn('ZConf-BGSet setLast: setBG errored');
		return undef;
	}

	return 1;
}

=head2 setRand

This sets a random background.

One option is accepted and that is the path to use. If
it is note specified, 'default' will be used.

    $zbg->setRand();
    if($zbg->{error}){
        print "Error!\n";
    }

=cut

sub setRand{
	my $self=$_[0];
	my $path=$_[1];

	#set the path to 'default' if it is specified
	if (!defined($path)) {
		$path=$self->{zconf}{conf}{zbgset}{path};
	}

	#error if no path is specified
	if (!defined($self->{zconf}{conf}{zbgset}{'paths/'.$path})) {
		warn('ZConf-BGSet setRand:14: The path "'.$path.'" does not exist');
		$self->{error}=14;
		$self->{errorString}='The path "'.$path.'" does not exist';
		return undef;
	}

	#splits the path appart
	my @paths=split(/\n/, $self->{zconf}{conf}{zbgset}{'paths/'.$path});

	#gets select which to use
	my $randomPathInt=rand($#paths);
	$randomPathInt =~ s/\.[0123456789]*//;
	my $pathToUse=$paths[$randomPathInt];

	#escapes it
	$pathToUse=~s/(["`\$\\ ])/\\$1/g;
	$pathToUse=~qq($pathToUse);

	my @files=`find $pathToUse -type f`;

	my $filesInt=rand($#files);
	$filesInt =~ s/\.[0123456789]*//;

	my $image=$files[$filesInt];

	chomp($image);

	$self->setBG({image=>$image});

	return 1;
}

=head2 setterExists

This verifies a path exists.

Only one arguement is taken and that is the name of the setter.

    my $returned=$zbg->setterExists('foo');
    if($zbg->{error}){
        print "Error!\n";
    }else{
        if(!$returned){
            print "The setter 'foo' does not exist.\n";
        }
    }

=cut

sub setterExists{
	my $self=$_[0];
	my $setter=$_[1];

	#blank any previous errors
	$self->errorblank;

	#error if no path is specified
	if (!defined($setter)) {
		warn('ZConf-BGSet setterExists:5: The setter is undefined');
		$self->{error}=5;
		$self->{errorString}='The setter is undefined.';
		return undef;
	}

	if (!$self->validSetterName($setter)) {
		warn('ZConf-BGSet setterExists:6: "'.$setter.'" is not a valid setter name');
		$self->{error}=6;
		$self->{errorString}='"'.$setter.'" is not a valid setter name.';
		return undef;
	}

	#if it is not defined, return undef
	if (!defined($self->{zconf}->{conf}->{zbgset}->{$setter})) {
		return undef;
	}

	return 1;
}

=head2 setSetter

Sets the setter to be used for a specific fill type.

Two arguements are required. The first is the setter name
and the second is setter.

    $zbg->setSetter('full', 'hsetroot -full %%%THEFILE%%%');
    if($zbg->{error}){
        print "Error!\n";
    }

=cut

sub setSetter{
	my $self=$_[0];
	my $name=$_[1];
	my $setter=$_[2];

	#blanks any previous errors
	$self->errorblank;

	if (!$self->validSetterName($name)) {
		warn('ZConf-BGSet setSetter:6: "'.$name.'" is not a valid setter name');
		$self->{error}=6;
		$self->{errorString}='"'.$name.'" is not a valid setter name.';
		return undef;
	}

	#set it
	$self->{zconf}->setVat('zbgset', $name, $setter);
	if ($self->{zconf}->{error}) {
		warn("ZConf-BGSet init:2: setVar failed.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=2;
		$self->{errorString}="setVar failed.".
			                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return undef;
	}

	#save it
	$self->{zconf}->writeSetFromLoadedConfig('zbgset', $name, $setter);
	if ($self->{zconf}->{error}) {
		warn("ZConf-BGSet init:2: writeSetFromLoadedConfig failed.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=2;
		$self->{errorString}="writeSetFromLoadedConfig failed.".
			                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return undef;
	}

	return 1;
}

=head2 validSetterName

Checks if a name specified for a setter is valid or not.

There is no reason to check for an error on this as it does not
set any. It just checks that the specified name is valid. If it
is not set, it will also return false.

    if(!$zbg->validSetterName('monkey')){
        print "No valid.\n";
    }

    if(!$zbg->validSetterName('full')){
        print "No valid.\n";
    }

=cut

sub validSetterName{
	my $self=$_[0];
	my $name=$_[1];

	if (!defined($name)) {
		return undef;
	}

	if ($name =~ /^ft\//) {
		return 1;
	}

	if ($name eq 'full') {
		return 1;
	}

	if ($name eq 'fill') {
		return 1;
	}

	if ($name eq 'tile') {
		return 1;
	}

	if ($name eq 'center') {
		return 1;
	}

	#if we get here it has not been matched and thus false
	return undef;
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

=cut

#blanks the error flags
sub errorblank{
        my $self=$_[0];

        $self->{error}=undef;
        $self->{errorString}="";

        return 1;
}

=head1 FILL TYPES

=head2 full

The setter to use for setting fill the screen and keep the same aspect ratio.

=head2 fill

The setter to use for setting the image to fill the screen.

=head2 center

The setter to use to center the image.

=head2 tile

The setter to use to tile the image.

=head2 auto

This will automatically choose between fill and full. The variable 'maxdiff'
is used to determine what it should be set to.

=head2 ^ft/

Any thing matching the regex /^ft\// can also be used as a setter.

=head1 ZConf Keys

=head2 center

This contains the setter that will be used for when setting a centered image.
'%%%THEFILE%%%' is replaced at runtime with the name of the file.

	center=hsetroot -center %%%THEFILE%%%

=head2 fill

This key contains setter to be used for fill the background with a resized image.
'%%%THEFILE%%%' is replaced at runtime with the name of the file.

	fill=hsetroot -fill %%%THEFILE%%%

=head2 full

This key contains setter to be used for fill the background with a scaled image.
'%%%THEFILE%%%' is replaced at runtime with the name of the file.

	full=hsetroot -full %%%THEFILE%%%

=head2 last

This contains the last several images set. There is one entry per line. The format
is as below.

	<hostname>:<display>:<fill type>:<image>

=head2 maxdiff

This contains the maximum difference for between any two any two sides when choosing
between fill and full.

	maxdiff=.2

=head2 numberoflast

The number of last entries to save.

=head2 path

This is the path to use for when selecting a random image.

=head2 paths/<path>

This is a path. Each path have multiple paths. Each path is seperated by a new line.

=head2 postSetRefresh

Wether or not it should run something after it has been set. This is a perl boolean value.

	postSetRefresh=0

=head2 postSetRefresher

If 'postSetRefresh' is set to true, this is ran.

=head2 tile

This key contains setter to be used for tiling. '%%%THEFILE%%%' is replaced at
runtime with the name of the file.

	tile=hsetroot -tile %%%THEFILE%%%

=head1 ERROR CODES

=head2 1

Could not initialize ZConf.

=head2 2

ZConf error.

=head2 3

Failed to create the ZConf config 'zbgset'.

=head2 4

Autoinit errored.

=head2 5

Undefined arguement.

=head2 6

Invalid setter name.

=head2 7

Setter does not exist.

=head2 8

Could not determine the display.

=head2 9

Invalid hostname.

=head2 10

Invalid display name.

=head2 11

Image::Size::FillFullSelect->select failed.

=head2 12

The file does not exist.

=head2 13

The file does not exist.

=head2 14

The path does not exist.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-bgset at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-BGSet>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::BGSet


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-BGSet>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-BGSet>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-BGSet>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-BGSet>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::BGSet
