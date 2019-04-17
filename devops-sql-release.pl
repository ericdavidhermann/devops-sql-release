#!C:\Strawberry\perl\bin\perl.exe
#-------------------------------------------------------------------------------
# DEVOPS script for assisting with SQL script additions for release file
# candidates.
# Author: Eric Hermann, 2018
# Email: ericdavidhermann@gmail.com
# Licensed under GNU GPL v3.0
#-------------------------------------------------------------------------------
use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use v5.10.1;
no warnings 'experimental';
use Try::Tiny;

# The version number for this script
use constant VERSION => "1.0.0";

#----------
# Can set your defaults according to your needs here, and override with
# any GetOptions passed in.
# Ticketing system prefix (Like for Jira/Mantis/etc)
use constant TKT_PREFIX   => 'TKT-';
# Release file prefix
use constant RF_PREFIX    => 'release-';
# The directory for your individual ticket-based SQL files
use constant SQL_DIR      => 'data/';
# The directory for your combined SQL release file
use constant RELEASE_DIR  => 'data/releases/';
# The release version for your application.
# Not to be confused with the VERSION of this perl script!
use constant RELEASE_VER  => 'v1.0';
#----------

# Initialize potential GetOptions
my ($helpMe, $sqlDir, $relDir, $ticket, $version) = (undef)x5;

GetOptions ("h|help"          => \$helpMe,
            "d|datadir=s"     => \$sqlDir,
            "r|releasedir=s"  => \$relDir,
            "t|ticket=s"      => \$ticket,
            "v|version=s"     => \$version);

# Handle user request for help before any other operations are done.
if (defined $helpMe) {
    helpMe();
    exit 0;
}

MAIN:
    my $operation={successful=>1}; # Ever the optimist.

    printHeader();

    # Ticket is mandatory and we will reprompt til we get one.
    while (!defined $ticket or $ticket eq '' or $ticket !~ /^\d*$/){
        $ticket = getTicket();
    }

    # Establish the working environment: use the constants defined above unless
    # the user has specified new environment variables.
    if (!defined $sqlDir) { $sqlDir  = SQL_DIR; }
    if (!defined $relDir) { $relDir  = RELEASE_DIR; }
    if (!defined $version){ $version = RELEASE_VER; }

    # Let's begin
    # Build our SQL file and Release file path and name
    my $sqlFile = $sqlDir.RELEASE_VER."/".TKT_PREFIX.$ticket.".sql";
    # EX: data/TKT-1000.sql
    my $relFile = $relDir . RF_PREFIX . RELEASE_VER. "/" .
                  RF_PREFIX .$version."-final.sql";
    # EX: data/releases/release-v1.0/release-v1.0-final.sql

    print "\n\n    Appending SQL in SQL file:\n";
    print "      $sqlFile";
    print "\n\n    To SQL Release file:\n";
    print "      $relFile\n\n";

    my $confirm=undef;
    print "    Is this correct? [y/n]: ";
    $confirm=<>;

    if ($confirm !~ /^y|Y|yes|YES/) {
        printError('CONFIRM');
        $operation->{successful} = 0;
    }

    # TODO: CHECK IF BOTH FILES EXIST BEFORE PROCEEDING

    if ($operation->{successful}){
        print "\n    Appending...\n";
        $operation = appendToReleaseFile($sqlFile, $relFile);
        if ($operation->{successful}) {
            print "\n    ...Done\n";
        } else {
            print "\n    Abending Script\n";
        }
    }

    $operation->{successful} ? exit 0 : exit 1;

#/MAIN

#-------------------------------------------------------------------------------
# SUBROUTINES
#-------------------------------------------------------------------------------
sub printHeader {
    #---------------------------------------------------------------------------
    #** @method public printHeader
    #   Prints the program header to the screen.
    # Parameters:
    #   None
    # Returns:
    #   Nothing
    #*
    #---------------------------------------------------------------------------
    my $div = '═'x55;
    print "\n\n";
    print "╔$div╗\n";
    print "║  ".$0."\t\t\t\t║\n";
    print "║  Version: " . VERSION ."\t\t\t\t\t║\n";
    print "╠$div╣\n";
    print "║  This script will concatenate the ticket's\t\t║\n";
    print "║  SQL file to the release SQL file\t\t\t║\n";
    print "╚$div╝\n";
}

sub helpMe {
    #---------------------------------------------------------------------------
    #** @method public helpMe
    #   Displays help information for the user on how to use this script.
    # Parameters:
    #   None
    # Returns:
    #   Nothing
    #*
    #---------------------------------------------------------------------------
    print qq |
        ╔══════════════════════════════════════════════════════════════════════╗
        ║                       devops-sql-release                             ║
        ║                             HELP                                     ║
        ║ This script will append a given ticket's change SQL to the given     ║
        ║ release candidate SQL file.                                          ║
        ║                                                                      ║
        ║ Ex: ./devops-sql-release.pl -t=TKT-1000 -dd=data -r=v1.0             ║
        ║                                                                      ║
        ║ The above example would take TKT-1000.sql found in /data and append  ║
        ║  it to the end of the release file.                                  ║
        ╠═══════════════════════════════╤══════════════════════════════════════╣
        ║ Argument                      │Effect                                ║
        ╟───────────────────────────────┼──────────────────────────────────────╢
        ║ h or help                     │Displays this help menu               ║
        ╟───────────────────────────────┼──────────────────────────────────────╢
        ║ d or datadir                  │Overrides the set data directory      ║
        ╟───────────────────────────────┼──────────────────────────────────────╢
        ║ r or release                  │Overrides the set release file        ║
        ╟───────────────────────────────┼──────────────────────────────────────╢
        ║ t or ticket                   │Sets the ticket being worked with     ║
        ╟───────────────────────────────┼──────────────────────────────────────╢
        ║ v or version                  │Sets the target version worked with   ║
        ╚═══════════════════════════════╧══════════════════════════════════════╝
    |;
}

sub printError {
    #---------------------------------------------------------------------------
    #** @method public printError
    #   Error message handling.
    # Parameters:
    #   eClass - STRING : The class of error that induced the problem.
    # Returns:
    #   Nothing
    #*
    #---------------------------------------------------------------------------
    my $eClass = uc(shift);
    given ($eClass) {
        when ('TICKET'){
            print "\n\n    ";
            print "[ERROR]: The ticket you entered was not numeric.\n";
            print "         Enter only the numeric part of the ticket!\n\n";
        }

        when ('CONFIRM'){
            print "\n\n    ";
            print "[ERROR]: Aborting script execution at request of user.\n";
            print "         Please rerun script after making necessary\n";
            print "         changes.\n\n";
        }

        when ('UNDEF_FILE'){
            print "\n\n    ";
            print "[ERROR]: One or both of the file path/names is missing\n";
            print "         Aborting appending of SQL to release file.\n\n";
        }

        when ('APPEND'){
            print "\n\n    ";
            print "[ERROR]: A problem was encountered while attempting\n";
            print "         to append the SQL to the release file.\n";
            print "         Aborting appending of SQL to release file.\n\n";
        }

        default {
            print "\n\n    ";
            print "[ERROR]: An unspecified fatal error occurred.\n";
            print "         Please consult --help for assistance.\n\n";
        }
    }
}

sub getTicket {
    #---------------------------------------------------------------------------
    #** @method public getTicket
    #   Continually reprompt the user for a valid ticket number
    # Parameters:
    #   NONE
    # Returns:
    #   ticket  INT : The ticket number the script will use from here on out.
    #*
    #---------------------------------------------------------------------------
    my $ticket = undef;
    if (!defined $ticket) {
        print "    Please enter the ticket number: ";
        $ticket = <>;
    }

    chomp $ticket;

    if ( $ticket eq '' or $ticket !~ /^\d*$/ ) {
        printError('TICKET');
        my $ticket = undef; # Undefine it to reprompt.
    }

    return $ticket;
}

sub appendToReleaseFile {
    #---------------------------------------------------------------------------
    #** @method public appendToReleaseFile
    #   Appends the ticket sqlFile to the release candidate file relFile
    # Parameters:
    #   sqlFile : STRING - The path/name of the SQL file to be appended
    #   relFile : STRING - The path/name of the release candidate SQL file
    # Returns:
    #   ticket  INT : The ticket number the script will use from here on out.
    #*
    #---------------------------------------------------------------------------
    my ($sqlFile, $relFile) = @_;
    my $result = {successful=>1}; # Assume this will succeed

    # Make sure we have what we need with regard to file names.
    if (!defined $sqlFile or $sqlFile eq '' or
        !defined $relFile or $relFile eq '')
    {
        printError('UNDEF_FILE');
        $result->{successful} = 0;
    }

    try {
        open my $in_fh, '<', $sqlFile;
        open my $out_fh, '>>', $relFile;
        # Add a single new line before reading in file.
        print $out_fh "\n";
        local $/ = \65536; # Reading in 64kb chunks
        while ( my $chunk = <$in_fh> ) { print $out_fh $chunk; }
        # Add a single new line after reading in the file is complete.
        print $out_fh "\n";
    } catch {
        printError('APPEND');
        $result->{successful} = 0;
    };

    return $result;
}

1;
