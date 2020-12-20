CREATE TABLE w.Kreis (
    Kreisschluessel int not null primary key,
    Wahlkreisname varchar(255) not null,
    Name varchar(255) not null
);

COPY w.Kreis(Kreisschluessel, Wahlkreisname, Name) FROM '/database/kreise.csv' DELIMITER ';' CSV HEADER;

CREATE TABLE w.Gemeinde (
    Gemeineschluessel int not null primary key,
    Kreisschluessel int not null references w.Kreis,
    Stimmkreis int not null,
    Name varchar(255) not null
);

COPY w.Gemeinde(Gemeineschluessel, Kreisschluessel, Stimmkreis, Name) FROM '/database/gemeinden.csv' DELIMITER ';' CSV HEADER;
