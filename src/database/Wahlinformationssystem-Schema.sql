DROP SCHEMA IF EXISTS W cascade; -- Drop if already existing

CREATE SCHEMA W;

CREATE TABLE W.Landtagswahl (
    jahr int not null primary key,
    wahltag date not null
);

CREATE TABLE W.WahlabgabeToken (
    token varchar(255) not null primary key,
    landtagswahl int not null references W.Landtagswahl,
    erststimmeAbgegeben bool not null,
    zweitstimmeAbgegeben bool not null
);

CREATE TABLE W.Wahlkreis (
    wahlkreisname varchar(255) not null,
    landtagswahl int not null references W.Landtagswahl,
    sitze int not null,
    primary key (wahlkreisname, landtagswahl)
);

CREATE TABLE W.Stimmkreis (
    nummer int not null,
    wahlkreisname varchar(255) not null,
    landtagswahl int not null,
    stimmkreisname varchar(255) not null,
    stimmberechtigte int not null,
    primary key (nummer, wahlkreisname, landtagswahl),
    foreign key (wahlkreisname, landtagswahl) references W.Wahlkreis (wahlkreisname, landtagswahl)
);

CREATE TABLE W.Partei (
    name varchar(255) not null primary key
);

CREATE TABLE W.Kandidat (
    persNr int not null,
    landtagswahl int not null references W.Landtagswahl,
    name varchar(255) not null,
    partei varchar(255) not null references W.Partei,
    listenplatz int not null,
    listenkandidatInWahlkreis varchar(255) not null,
    direktkandidatInStimmkreis int,
    primary key (persNr, landtagswahl),
    foreign key (landtagswahl, listenkandidatInWahlkreis) references W.Wahlkreis(landtagswahl, wahlkreisname),
    foreign key (direktkandidatInStimmkreis, listenkandidatInWahlkreis, landtagswahl) references W.Stimmkreis (nummer, wahlkreisname, landtagswahl)

   );

CREATE TABLE W.Stimme (
    stimmeId int not null primary key,
    gueltig bool not null
);

CREATE TABLE W.Zweitstimme (
    stimmeId int not null primary key references W.Stimme,
    stimmkreisWahlkreis varchar(255) not null,
    stimmkreisNummer int not null,
    stimmkreisLandtagswahl int not null,
    foreign key (stimmkreisNummer, stimmkreisWahlkreis, stimmkreisLandtagswahl) references W.Stimmkreis(nummer, wahlkreisname, landtagswahl)
);

CREATE TABLE W.ZweitstimmeKandidat (
    zweitstimmeId int not null primary key references W.Zweitstimme,
    kandidat int not null,
    landtagswahl int not null,
    foreign key (kandidat, landtagswahl) references W.Kandidat(persNr, landtagswahl)
);

CREATE TABLE W.ZweitstimmePartei (
    zweitstimmeId int not null primary key references W.Zweitstimme,
    partei varchar(255) not null references W.Partei
);

CREATE TABLE W.Erststimme (
    stimmeId int not null primary key references W.Stimme,
    kandidat int not null,
    landtagswahl int not null,
    foreign key (kandidat, landtagswahl) references W.Kandidat(persNr, landtagswahl)
);