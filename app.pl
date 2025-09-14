#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use Dancer2;
use POSIX 'strftime';

use lib 'lib';
use ContactManager;

# Home page
get '/' => sub {
    return template 'index', { current_page => 'home' };
};

# Add contact
post '/ajouter' => sub {
    my $nom = body_parameters->get('nom');
    my $email = body_parameters->get('email');
    my $tel = body_parameters->get('tel');
    ContactManager::ajouter_contact($nom, $email, $tel);
    redirect '/';
};

# Search contacts
get '/rechercher' => sub {
    my $recherche = query_parameters->get('q');
    my @contacts;
    if ($recherche) {
        @contacts = ContactManager::rechercher_contacts($recherche);
    }
    return template 'rechercher', {
        recherche    => $recherche,
        contacts     => \@contacts,
        current_page => 'rechercher',
    };
};


# Delete contact
post '/supprimer' => sub {
    my $nom = body_parameters->get('nom');
    my $email = body_parameters->get('email');
    my $tel = body_parameters->get('tel');
    ContactManager::supprimer_contact($nom, $email, $tel);

    my $q = query_parameters->get('q') // '';
    redirect "/rechercher?q=$q";
};

# Show edit form
get '/modifier' => sub {
    my $nom = query_parameters->get('nom');
    my $email = query_parameters->get('email');
    my $tel = query_parameters->get('tel');
    return template 'modifier', {
        old_nom      => $nom,
        old_email    => $email,
        old_tel      => $tel,
        current_page => 'rechercher',
    };
};

# Handle edit submission
post '/modifier' => sub {
    my $old_nom = body_parameters->get('old_nom');
    my $old_email = body_parameters->get('old_email');
    my $old_tel = body_parameters->get('old_tel');

    my $new_nom = body_parameters->get('nom');
    my $new_email = body_parameters->get('email');
    my $new_tel = body_parameters->get('tel');

    ContactManager::modifier_contact($old_nom, $old_email, $old_tel, $new_nom, $new_email, $new_tel);

    my $q = query_parameters->get('q') // '';
    redirect "/rechercher?q=$q";
};

# Backup contacts (copie du fichier SQLite)
get '/backup' => sub {
    my $dir = 'backups';
    mkdir $dir unless -d $dir;

    my $timestamp = strftime "%Y%m%d_%H%M%S", localtime;
    my $backup_file = "$dir/contacts_backup_$timestamp.db";

    if (-e 'contacts.db') {
        require File::Copy;
        File::Copy::copy('contacts.db', $backup_file)
            or return "Impossible de créer $backup_file : $!";
    }
    else {
        return "Aucune base de données à sauvegarder.";
    }

    template 'backup' => {
        current_page => 'backup',
        backup_file  => $backup_file,
    };
};

get '/restore' => sub {
    my $dir = 'backups';
    opendir(my $dh, $dir) or return "Impossible d'ouvrir $dir: $!";
    my @files = grep {/\.db$/ && -f "$dir/$_"} readdir($dh);
    closedir $dh;

    my @backups;
    foreach my $file (@files) {
        if ($file =~ /_(\d{8})_(\d{6})\.db$/) {
            my ($date, $time) = ($1, $2);
            my $formatted_date = sprintf "%s-%s-%s %s:%s:%s",
                substr($date, 0, 4), substr($date, 4, 2), substr($date, 6, 2),
                substr($time, 0, 2), substr($time, 2, 2), substr($time, 4, 2);
            push @backups, { file => $file, date => $formatted_date };
        }
        else {
            push @backups, { file => $file, date => 'Inconnue' };
        }
    }

    @backups = sort {$b->{date} cmp $a->{date}} @backups;

    template 'restore' => {
        current_page => 'restore',
        backups      => \@backups,
    };
};


# Exécution de la restauration
get '/do_restore' => sub {
    my $file = query_parameters->get('file');
    my $msg;

    if ($file && -f "backups/$file") {
        require File::Copy;
        File::Copy::copy("backups/$file", "contacts.db")
            or $msg = "Impossible de restaurer depuis $file : $!";
        $msg ||= "Restauration effectuée depuis : $file";
    }
    else {
        $msg = "Fichier de backup non spécifié ou inexistant.";
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
    }
    else {
        $msg = "Fichier de backup non spécifié ou inexistant.";
    }

    return template 'do_template' => {
        current_page => 'restore',
        message      => $msg,
    };
};

get '/contacts' => sub {
    my @contacts = ContactManager::lister_contacts();
    template 'contacts' => {
        current_page => 'contacts',
        contacts     => \@contacts,
    };
};

start;
