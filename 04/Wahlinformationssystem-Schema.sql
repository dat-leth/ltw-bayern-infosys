CREATE DATABASE Wahlinformationssystem;

CREATE TABLE Landtagswahl (
    legislaturPeriode int not null primary key,
    wahltag date not null
);

CREATE TABLE WahlberechtigteToken (
    token varchar(255) not null primary key,
    landtagswahl int not null references Landtagswahl,
    erststimmeAbgegeben bool not null,
    zweitstimmeAbgegeben bool not null
);

CREATE TABLE Person (
    persNr int not null primary key,
    name varchar(255) not null,
    beruf varchar(255) not null
);

CREATE TABLE Wahlkreis (
    name varchar(255) not null,
    landtagswahl int not null references Landtagswahl,
    anzahlSitze int not null,
    anzahlEinwohner int not null,
    primary key (name, landtagswahl)
);

CREATE TABLE Stimmkreis (
    nummer int not null,
    wahlkreis int not null references Wahlkreis,
    name varchar(255) not null,
    primary key (nummer, wahlkreis)
);

CREATE TABLE Partei (
    name varchar(255) not null primary key
);

CREATE TABLE Kandidat (
    persNr int not null references Person,
    landtagswahl int not null references Landtagswahl,
    partei varchar(255) not null references Partei,
    listenplatz int not null,
    anzahlErststimmen int not null,
    anzahlZweitstimmen int not null,
    listenkandidatIn int not null references Wahlkreis,
    direktkandidatIn int references Stimmkreis,
    primary key (persNr, landtagswahl),
    unique (landtagswahl, listenkandidatIn, listenplatz)
);

CREATE TABLE Stimme (
    id int not null primary key,
    gueltig bool not null
);

CREATE TABLE Zweitstimme (
    id int not null primary key references Stimme,
    stimmkreis int not null references Stimmkreis
);

CREATE TABLE ZweitstimmeKandidat (
    id int not null primary key references Zweitstimme,
    kandidat int not null references Kandidat
);

CREATE TABLE ZweitstimmePartei (
    id int not null primary key references Zweitstimme,
    partei int not null references Partei
);

CREATE TABLE Erststimme (
    id int not null primary key references Stimme,
    kandidat int not null references Kandidat
);