#!/usr/bin/perl
use strict;
use warnings;
use DBI;

my $csv_file = "contacts.csv";
my $db_file  = "contacts.db";

# Connexion à SQLite
my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","", { RaiseError => 1, AutoCommit => 1 });

# Création de la table si elle n'existe pas
$dbh->do("
    CREATE TABLE IF NOT EXISTS contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        email TEXT NOT NULL,
        tel TEXT NOT NULL,
        UNIQUE(nom, email, tel) ON CONFLICT IGNORE
    )
");

# Lire le CSV
open my $fh, "<", $csv_file or die "Impossible d'ouvrir $csv_file: $!";
my $count_total = 0;
my $count_imported = 0;

while (my $ligne = <$fh>) {
    chomp $ligne;
    my ($nom, $email, $tel) = split /,/, $ligne;

    # Vérifier que la ligne est valide
    next unless $nom && $email && $tel;

    $count_total++;

    # Insérer dans SQLite (ignorer si déjà présent)
    my $sth = $dbh->prepare("INSERT OR IGNORE INTO contacts (nom, email, tel) VALUES (?, ?, ?)");
    $sth->execute($nom, $email, $tel);

    $count_imported += $sth->rows; # Compte uniquement les nouvelles lignes
}
close $fh;

print "✅ Migration terminée : $count_imported / $count_total contacts importés depuis $csv_file vers $db_file\n";
