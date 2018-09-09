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

# Handle user request for help before any other operations.
if (defined $helpMe) {
    helpMe();
    exit 1;
}

# Ticket is mandatory.
if (!defined $ticket){
    printError('TICKET');
    exit 0;
}

# Establish the working environment: use the constants defined above unless the
# user has specified new environment variables.
if (!defined $sqlDir) { $sqlDir  = SQL_DIR; }
if (!defined $relDir) { $relDir  = RELEASE_DIR; }
if (!defined $version){ $version = RELEASE_VER; }

# Let's begin
print Dumper($helpMe, $sqlDir, $relDir, $ticket, $version);

print "\n\n\tAppending SQL in SQL file: ";
print "\n\t  ".$sqlDir.TKT_PREFIX.$ticket.".sql\n\n";
print "\tTo SQL Release file: ";
print "\n\t  ".$relDir.$version."/".RF_PREFIX.$version.".sql\n\n";

print "\tIs this correct [y/n]?";
#-------------------------------------------------------------------------------
# SUBROUTINES
#-------------------------------------------------------------------------------
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
    #** @method public helpMe
    #   Displays help information on this script.
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
            print "[ERROR]: No ticket number was entered.\n";
            print "         You MUST enter a ticket.\n";
        }
        default {
            print "\n\n";
            print "[ERROR]: An unspecified fatal error occurred.\n";
            print "         Please consult --help for assistance.\n";
        }
    }
}

1;