#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use Dancer2;
use lib 'lib';
use ContactManager;

# Home page
get '/' => sub {
    return template 'index', { current_page => 'home' };
};

# Add contact
post '/ajouter' => sub {
    my $nom   = body_parameters->get('nom');
    my $email = body_parameters->get('email');
    my $tel   = body_parameters->get('tel');
    ContactManager::ajouter_contact($nom, $email, $tel);
    redirect '/';
};

# Search contacts
get '/rechercher' => sub {
    my $recherche = query_parameters->get('q');
    my @contacts;

    if (defined $recherche && $recherche ne '') {
        open my $fh, '<', 'contacts.csv' or return "Erreur ouverture fichier: $!";
        while (my $ligne = <$fh>) {
            chomp $ligne;
            my ($nom, $email, $tel) = split /,/, $ligne;
            if ($nom =~ /$recherche/i || $email =~ /$recherche/i || $tel =~ /$recherche/) {
                push @contacts, { nom => $nom, email => $email, tel => $tel };
            }
        }
        close $fh;
    }

    return template 'rechercher', {
        recherche     => $recherche,
        contacts      => \@contacts,
        current_page  => 'rechercher',
    };
};

# Delete contact
post '/supprimer' => sub {
    my $nom   = body_parameters->get('nom');
    my $email = body_parameters->get('email');
    my $tel   = body_parameters->get('tel');
    ContactManager::supprimer_contact($nom, $email, $tel);

    my $q = query_parameters->get('q') // '';
    redirect "/rechercher?q=$q";
};

# Show edit form
get '/modifier' => sub {
    my $nom   = query_parameters->get('nom');
    my $email = query_parameters->get('email');
    my $tel   = query_parameters->get('tel');
    return template 'modifier', {
        old_nom   => $nom,
        old_email => $email,
        old_tel   => $tel,
        current_page => 'rechercher',
    };
};

# Handle edit submission
post '/modifier' => sub {
    my $old_nom   = body_parameters->get('old_nom');
    my $old_email = body_parameters->get('old_email');
    my $old_tel   = body_parameters->get('old_tel');

    my $new_nom   = body_parameters->get('nom');
    my $new_email = body_parameters->get('email');
    my $new_tel   = body_parameters->get('tel');

    ContactManager::modifier_contact($old_nom, $old_email, $old_tel, $new_nom, $new_email, $new_tel);

    my $q = query_parameters->get('q') // '';
    redirect "/rechercher?q=$q";
};

# Backup contacts
get '/backup' => sub {
    my $backup_file = ContactManager::backup_contacts();
    return "Backup créé avec succès : $backup_file";
};

# Restore contacts (pass ?file=backupname.csv)
get '/restore' => sub {
    my $file = query_parameters->get('file');
    if ($file) {
        ContactManager::restore_contacts($file);
        return "Restauration effectuée depuis : $file";
    }
    return "Fichier de backup non spécifié.";
};

start;
