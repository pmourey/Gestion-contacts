# Gestion Contacts (Perl / Dancer2)

Application web pour gérer des contacts (ajout, recherche, modification, suppression) avec sauvegarde et restauration des backups.

---

## Prérequis

- Perl 5 (>= 5.30 recommandé)
- cpanminus (`cpanm`)
- SQLite3

Modules Perl nécessaires (gérés automatiquement par `cpanfile`) :

- Dancer2  
- DBI  
- DBD::SQLite  
- Template Toolkit  
- JSON  
- POSIX  

---

## Installation

### 1. Cloner le projet
```bash
git clone https://github.com/mon-projet/gestion-contacts.git
cd gestion-contacts
```

### 2. Installer Perl

#### macOS
```bash
brew install perl
```

#### Linux (Debian/Ubuntu)
```bash
sudo apt update
sudo apt install perl
```

#### Windows
Installer [Strawberry Perl](http://strawberryperl.com/).

---

### 3. Installer cpanminus

#### macOS / Linux
```bash
brew install cpanminus
# ou
curl -L https://cpanmin.us | perl - --sudo App::cpanminus
```

#### Windows (Strawberry Perl)
`cpanm` est inclus dans Strawberry Perl.

---

### 4. Installer les modules Perl requis
```bash
cpanm --installdeps .
```
> Cette commande lira le `cpanfile` présent à la racine et installera automatiquement toutes les dépendances.

---

### 5. Initialiser la base de données SQLite
La base `contacts.db` sera créée automatiquement au premier lancement si elle n’existe pas.

---

### 6. Lancer l’application
```bash
perl app.pl
```
Le serveur écoute par défaut sur [http://localhost:3000](http://localhost:3000).

---

## Sauvegarde / Restauration

- Les backups sont stockés dans `backups/` au format `contacts_backup_YYYYMMDD_HHMMSS.db`.  
- La page **Restore** permet de restaurer un backup ou de supprimer un backup existant.

---

## Structure du projet

```
project/
├─ app.pl              # Application principale
├─ lib/
│  └─ ContactManager.pm
├─ views/
│  ├─ index.tt
│  ├─ contacts.tt
│  ├─ rechercher.tt
│  ├─ modifier.tt
│  ├─ backup.tt
│  ├─ restore.tt
│  └─ do_template.tt
├─ style.css
├─ backups/            # Contient les backups
├─ contacts.db         # Base SQLite (créée automatiquement)
└─ cpanfile            # Dépendances Perl
```

---

## cpanfile (exemple)
```perl
requires 'Dancer2',         '1.1.2';
requires 'DBI',              '1.643';
requires 'DBD::SQLite',      '1.73';
requires 'Template',         '2.26';
requires 'JSON',             '4.03';
requires 'POSIX',            '1.34';
```

---

## Contributions

Pull requests bienvenues !  
Merci de ne pas créer de doublons dans la base SQLite : `ContactManager.pm` gère les contraintes d’unicité.

---

## Licence

MIT