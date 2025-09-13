package ContactManager;
use strict;
use warnings FATAL => 'all';
use Exporter 'import';
our @EXPORT_OK = qw(ajouter_contact supprimer_contact modifier_contact);
use File::Copy qw(copy);

# Add contact
sub ajouter_contact {
    my ($nom, $email, $tel) = @_;
    open my $fh, '>>', 'contacts.csv' or die "Impossible d'ouvrir contacts.csv: $!";
    print $fh "$nom,$email,$tel\n";
    close $fh;
}

# Delete contact
sub supprimer_contact {
    my ($nom, $email, $tel) = @_;

    open my $fh, '<', 'contacts.csv' or die "Impossible d'ouvrir contacts.csv: $!";
    my @lines = <$fh>;
    close $fh;

    open my $out, '>', 'contacts.csv' or die "Impossible d'ouvrir contacts.csv: $!";
    foreach my $ligne (@lines) {
        chomp $ligne;
        my ($n, $e, $t) = split /,/, $ligne;
        print $out "$ligne\n" unless $n eq $nom && $e eq $email && $t eq $tel;
    }
    close $out;
}

# Edit contact
sub modifier_contact {
    my ($old_nom, $old_email, $old_tel, $new_nom, $new_email, $new_tel) = @_;

    open my $fh, '<', 'contacts.csv' or die "Impossible d'ouvrir contacts.csv: $!";
    my @lines = <$fh>;
    close $fh;

    open my $out, '>', 'contacts.csv' or die "Impossible d'ouvrir contacts.csv: $!";
    foreach my $ligne (@lines) {
        chomp $ligne;
        my ($n, $e, $t) = split /,/, $ligne;
        if ($n eq $old_nom && $e eq $old_email && $t eq $old_tel) {
            print $out "$new_nom,$new_email,$new_tel\n";
        } else {
            print $out "$ligne\n";
        }
    }
    close $out;
}


# Backup contacts.csv to a timestamped file
sub backup_contacts {
    my $timestamp = time();
    my $backup_file = "contacts_backup_$timestamp.csv";
    copy("contacts.csv", $backup_file) or die "Backup failed: $!";
    return $backup_file;
}

# Restore contacts.csv from a specified backup file
sub restore_contacts {
    my ($backup_file) = @_;
    copy($backup_file, "contacts.csv") or die "Restore failed: $!";
}


1;
