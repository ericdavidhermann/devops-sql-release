#!C:\Strawberry\perl\bin\perl.exe
#---------------------------------------------------------------------------
# DEVOPS script for assisting with SQL script additions for release file
# candidates.
# Author: Eric Hermann, 2018
# Email: ericdavidhermann@gmail.com
# Licensed under GNU GPL v3.0
#---------------------------------------------------------------------------
use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use v5.10.1;
no warnings 'experimental';

use constant VERSION => "1.0.0";
# Ticketing system prefix (Like for Jira/Mantis/etc)
use constant TKT_PREFIX  => 'TKT-';
# Release file prefix
use constant RF_PREFIX   => 'release-sql-';
# Can set your defaults according to your needs here, and override with
# any GetOptions passed in.
use constant SQL_DIR      => 'data/';
use constant RELEASE_DIR  => 'data/releases/';
use constant RELEASE_VER  => 'v1.0';

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
    exit 1;
}

MAIN:
    printHeader();

    # Ticket is mandatory.
    while (!defined $ticket or $ticket eq '' or $ticket !~ /^\d*$/){
        $ticket = getTicket();
    }
    # We have our ticket now.
    print "\nThe ticket is: $ticket \n";

    # Establish the working environment: use the constants defined above unless the
    # user has specified new environment variables.
    if (!defined $sqlDir) { $sqlDir  = SQL_DIR; }
    if (!defined $relDir) { $relDir  = RELEASE_DIR; }
    if (!defined $version){ $version = RELEASE_VER; }

    # Let's begin
    print Dumper($sqlDir, $relDir, $version);

    print "\n\n\tAppending SQL in SQL file: ";
    print "\n\t  ".$sqlDir.TKT_PREFIX.$ticket.".sql\n\n";
    print "\tTo SQL Release file: ";
    print "\n\t  ".$relDir.$version."/".RF_PREFIX.$version.".sql\n\n";

    print "\tIs this correct [y/n]?";

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
    print "\n";
    print '═'x40;
    print "\nThis script will concatenate the\n";
    print "ticket's SQL file to the release SQL file\n\n";
    print "\n";
    print $0."\nVersion: " . VERSION. "\n\n";
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
            print "\n\n";
            print "[ERROR]: The ticket you entered was not numeric.\n";
            print "         Enter only the numeric part of the ticket!\n\n";
        }
        default {
            print "\n\n";
            print "[ERROR]: An unspecified fatal error occurred.\n";
            print "         Please consult --help for assistance.\n\n";
        }
    }
}

sub getTicket {
    #---------------------------------------------------------------------------
    #** @method public printError
    #   Continually reprompt the user for a valid ticket number
    # Parameters:
    #   NONE
    # Returns:
    #   ticket  INT : The ticket number the script will use from here on out.
    #*
    #---------------------------------------------------------------------------
    my $ticket = undef;
    if (!defined $ticket) {
        print "Please enter the ticket number: ";
        $ticket = <>;
    }

    chomp $ticket;

    if ( $ticket eq '' or $ticket !~ /^\d*$/ ) {
        printError('TICKET');
        my $ticket = undef; # Undefine it to reprompt.
    }

    return $ticket;
}

1;