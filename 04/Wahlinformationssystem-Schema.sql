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
    wahlkreis varchar(255) not null,
    landtagswahl int not null,
    name varchar(255) not null,
    primary key (nummer, wahlkreis),
    foreign key (wahlkreis, landtagswahl) references Wahlkreis
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
    listenkandidatIn varchar(255) not null,
    direktkandidatInWahlkreis varchar(255),
    direktkandidatInStimmkreis int,
    primary key (persNr, landtagswahl),
    foreign key (landtagswahl, listenkandidatIn) references Wahlkreis(landtagswahl, name),
    foreign key (direktkandidatInWahlkreis, direktkandidatInStimmkreis) references Stimmkreis(wahlkreis, nummer)
);

CREATE TABLE Stimme (
    id int not null primary key,
    gueltig bool not null
);

CREATE TABLE Zweitstimme (
    id int not null primary key references Stimme,
    stimmkreisWahlkreis varchar(255) not null,
    stimmkreisNummer int not null,
    foreign key (stimmkreisWahlkreis, stimmkreisNummer) references Stimmkreis(wahlkreis, nummer)
);

CREATE TABLE ZweitstimmeKandidat (
    id int not null primary key references Zweitstimme,
    kandidat int not null,
    landtagswahl int not null,
    foreign key (kandidat, landtagswahl) references Kandidat(persNr, landtagswahl)
);

CREATE TABLE ZweitstimmePartei (
    id int not null primary key references Zweitstimme,
    partei varchar(255) not null references Partei
);

CREATE TABLE Erststimme (
    id int not null primary key references Stimme,
    kandidat int not null,
    landtagswahl int not null,
    foreign key (kandidat, landtagswahl) references Kandidat(persNr, landtagswahl)
);