#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use Dancer2;
use lib 'lib';
use ContactManager;
use POSIX;

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
get '/backup_old' => sub {
    my $backup_file = ContactManager::backup_contacts();
    return template 'backup' => {
        current_page => 'backup',
        backup_file  => $backup_file,
    };
};

get '/backup' => sub {
    my $dir = 'backups';
    mkdir $dir unless -d $dir;  # crée le dossier s'il n'existe pas

    # Générer un timestamp YYYYMMDD_HHMMSS
    my $timestamp = strftime "%Y%m%d_%H%M%S", localtime;
    my $backup_file = "$dir/contacts_backup_$timestamp.csv";

    # Lire contacts existants et écrire le backup
    if (-e 'contacts.csv') {
        open my $in, '<', 'contacts.csv' or return "Impossible de lire contacts.csv : $!";
        open my $out, '>', $backup_file or return "Impossible de créer $backup_file : $!";
        while (my $line = <$in>) {
            print $out $line;
        }
        close $in;
        close $out;
    } else {
        return "Aucun contact à sauvegarder.";
    }

    # Retourne template avec confirmation
    template 'backup' => {
        current_page => 'backup',
        backup_file  => $backup_file,
    };
};


get '/restore_old' => sub {
    my $dir = 'backups';
    opendir(my $dh, $dir) or return "Impossible d'ouvrir $dir: $!";
    my @files = grep { /\.csv$/ && -f "$dir/$_" } readdir($dh);
    closedir $dh;

    return template 'restore' => {
        current_page => 'restore',
        backups      => \@files,
    };
};

use POSIX 'strftime';

get '/restore' => sub {
    my $dir = 'backups';
    opendir(my $dh, $dir) or return "Impossible d'ouvrir $dir: $!";
    my @files = grep { /\.csv$/ && -f "$dir/$_" } readdir($dh);
    closedir $dh;

    # Décoder le timestamp dans le nom du fichier
    my @backups;
    foreach my $file (@files) {
        if ($file =~ /_(\d{8})_(\d{6})\.csv$/) {
            my ($date, $time) = ($1, $2);
            my $formatted_date = sprintf "%s-%s-%s %s:%s:%s",
                substr($date,0,4), substr($date,4,2), substr($date,6,2),
                substr($time,0,2), substr($time,2,2), substr($time,4,2);
            push @backups, { file => $file, date => $formatted_date };
        } else {
            push @backups, { file => $file, date => 'Inconnue' };
        }
    }

    # Tri par date descendante (optionnel)
    @backups = sort { $b->{date} cmp $a->{date} } @backups;

    template 'restore' => {
        current_page => 'restore',
        backups      => \@backups,
    };
};

# Exécution de la restauration (via paramètre ?file=)
get '/do_restore' => sub {
    my $file = query_parameters->get('file');
    my $msg;

    if ($file) {
        ContactManager::restore_contacts("backups/$file");
        $msg = "Restauration effectuée depuis : $file";
    } else {
        $msg = "Fichier de backup non spécifié.";
    }

    return template 'do_template' => {
        current_page => 'restore',
        message      => $msg,
    };
};

# Supprimer un backup
post '/delete_backup' => sub {
    my $file = body_parameters->get('file');
    my $msg;

    if ($file && -f "backups/$file") {
        unlink "backups/$file" or $msg = "Impossible de supprimer $file : $!";
        $msg ||= "Backup supprimé : $file";
    } else {
        $msg = "Fichier de backup non spécifié ou inexistant.";
    }

    return template 'do_template' => {
        current_page => 'restore',
        message      => $msg,
    };
};

get '/contacts' => sub {
    my @contacts;

    if (-e 'contacts.csv') {
        open my $fh, '<', 'contacts.csv' or die "Impossible d'ouvrir contacts.csv : $!";
        while (my $ligne = <$fh>) {
            chomp $ligne;
            my ($nom, $email, $tel) = split /,/, $ligne;
            push @contacts, { nom => $nom, email => $email, tel => $tel };
        }
        close $fh;
    }

    template 'contacts' => {
        current_page => 'contacts',
        contacts     => \@contacts,
    };
};


start;
