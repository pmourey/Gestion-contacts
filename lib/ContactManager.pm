package ContactManager;
use strict;
use warnings;
use DBI;

my $db_file = "contacts.db";

# Connexion SQLite
sub get_dbh {
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","", {
        RaiseError => 1,
        AutoCommit => 1,
    });
    return $dbh;
}

# Initialiser la table si elle n'existe pas
sub init_db {
    my $dbh = get_dbh();
    $dbh->do("
        CREATE TABLE IF NOT EXISTS contacts (
            id   INTEGER PRIMARY KEY AUTOINCREMENT,
            nom  TEXT NOT NULL,
            email TEXT NOT NULL,
            tel  TEXT NOT NULL,
            UNIQUE(nom,email,tel)
        )
    ");
    $dbh->disconnect;
}

# Ajouter un contact
sub ajouter_contact {
    my ($nom, $email, $tel) = @_;
    my $dbh = get_dbh();
    eval {
        my $sth = $dbh->prepare("INSERT OR IGNORE INTO contacts (nom,email,tel) VALUES (?,?,?)");
        $sth->execute($nom, $email, $tel);
    };
    $dbh->disconnect;
}

# Lister tous les contacts
sub lister_contacts {
    my $dbh = get_dbh();
    my $sth = $dbh->prepare("SELECT id, nom, email, tel FROM contacts ORDER BY nom");
    $sth->execute();
    my @contacts;
    while (my $row = $sth->fetchrow_hashref) {
        push @contacts, $row;
    }
    $dbh->disconnect;
    return @contacts;
}

# Rechercher des contacts
sub rechercher_contacts {
    my ($recherche) = @_;
    my $dbh = get_dbh();
    my $sth = $dbh->prepare("
        SELECT id, nom, email, tel
        FROM contacts
        WHERE nom LIKE ? OR email LIKE ? OR tel LIKE ?
        ORDER BY nom
    ");
    my $like = "%$recherche%";
    $sth->execute($like, $like, $like);

    my @contacts;
    while (my $row = $sth->fetchrow_hashref) {
        push @contacts, $row;
    }
    $dbh->disconnect;
    return @contacts;
}

# Supprimer un contact
sub supprimer_contact {
    my ($nom, $email, $tel) = @_;
    my $dbh = get_dbh();
    my $sth = $dbh->prepare("DELETE FROM contacts WHERE nom=? AND email=? AND tel=?");
    $sth->execute($nom, $email, $tel);
    $dbh->disconnect;
}

# Modifier un contact
sub modifier_contact {
    my ($old_nom, $old_email, $old_tel, $new_nom, $new_email, $new_tel) = @_;
    my $dbh = get_dbh();
    my $sth = $dbh->prepare("
        UPDATE contacts
        SET nom=?, email=?, tel=?
        WHERE nom=? AND email=? AND tel=?
    ");
    $sth->execute($new_nom, $new_email, $new_tel, $old_nom, $old_email, $old_tel);
    $dbh->disconnect;
}

# Restaurer (après backup)
# Ici, comme tu copies le fichier .db complet, rien à faire dans ce module.
sub restore_contacts {
    my ($file) = @_;
    # Cette fonction est conservée pour compatibilité mais ne fait rien
    return 1;
}

1;
