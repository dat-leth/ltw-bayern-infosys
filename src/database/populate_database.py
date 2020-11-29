from dataclasses import dataclass
from datetime import datetime
import xml.etree.ElementTree as ET
import psycopg2
import psycopg2.extras

@dataclass
class Wahlkreis:
    nummer: int
    name: str
    landtagswahl: int
    sitze: int

@dataclass
class Stimmkreis:
    nummer: int
    wahlkreisname: str
    landtagswahl: int
    stimmkreisname: str
    stimmberechtigte: int


@dataclass
class Kandidat:
    persNr: int
    landtagswahl: int
    name: str
    partei: str
    listenplatz: int
    listenkandidatInWahlkreis: str
    direktkandidatInStimmkreis: int
    erststimmen: dict # StimmkreisNummer -> Anzahl (nur 1 Eintrag)
    zweitstimmen: dict # StimmkreisNummer -> Anzahl (alle anderen)

@dataclass
class Partei:
    parteiname: str
    landtagswahl: int
    zweitstimmenPartei: dict # StimmkreisNummer -> Anzahl


def get_wahlkreisname(stimmkreisnr):
    if 100 < stimmkreisnr < 200:
        return 'Oberbayern'
    elif 200 < stimmkreisnr < 300:
        return 'Niederbayern'
    elif 300 < stimmkreisnr < 400:
        return 'Oberpfalz'
    elif 400 < stimmkreisnr < 500:
        return 'Oberfranken'
    elif 500 < stimmkreisnr < 600:
        return 'Mittelfranken'
    elif 600 < stimmkreisnr < 700:
        return 'Unterfranken'
    elif 700 < stimmkreisnr < 800:
        return 'Schwaben'
    else:
        raise ValueError


def parse_wahlkreise(jahr):
    if jahr == 2013:
        return [
            Wahlkreis(901, 'Oberbayern', 2013, 60),
            Wahlkreis(902, 'Niederbayern', 2013, 18),
            Wahlkreis(903, 'Oberpfalz', 2013, 16),
            Wahlkreis(904, 'Oberfranken', 2013, 16),
            Wahlkreis(905, 'Mittelfranken', 2013, 24),
            Wahlkreis(906, 'Unterfranken', 2013, 20),
            Wahlkreis(907, 'Schwaben', 2013, 26),
        ]
    elif jahr == 2018:
        return [
            Wahlkreis(901, 'Oberbayern', 2018, 61),
            Wahlkreis(902, 'Niederbayern', 2018, 18),
            Wahlkreis(903, 'Oberpfalz', 2018, 16),
            Wahlkreis(904, 'Oberfranken', 2018, 16),
            Wahlkreis(905, 'Mittelfranken', 2018, 24),
            Wahlkreis(906, 'Unterfranken', 2018, 19),
            Wahlkreis(907, 'Schwaben', 2018, 26),
        ]


def parse_stimmkreise(info_xml_path, jahr):
    stimmkreise = []

    root = ET.parse(info_xml_path).getroot()
    for regionaleinheit in root.findall('Regionaleinheit'):
        nummer = int(regionaleinheit.findtext('Allgemeine_Angaben/Schluesselnummer'))
        if nummer >= 900 or nummer % 100 == 0:
            continue

        stimmkreise.append(Stimmkreis(
            nummer = nummer,
            wahlkreisname = get_wahlkreisname(nummer),
            landtagswahl = jahr,
            stimmkreisname = regionaleinheit.findtext('Allgemeine_Angaben/Name_der_Regionaleinheit').strip(),
            stimmberechtigte = int(regionaleinheit.findtext('Allgemeine_Angaben/Stimmberechtigte'))
        ))
    
    return stimmkreise

def parse_parteien(ergebnis_xml_path, jahr):
    root = ET.parse(ergebnis_xml_path).getroot()
    parteinamen = {i.findtext('Name').strip() for i in root.findall('.//Partei')}
    parteien = {n: Partei(n, jahr, {}) for n in parteinamen}

    for partei in root.findall('.//Partei'):
        for stimmkreis in partei.findall('.//Stimmkreis'):
            parteien[partei.findtext('Name').strip()].zweitstimmenPartei[int(stimmkreis.findtext('NrSK'))] = int(stimmkreis.findtext('ZweitSohneKandidat'))
    return list(parteien.values())

def parse_kandidaten(ergebnis_xml_path, jahr):
    persNr = 1
    kandidaten = []
    root = ET.parse(ergebnis_xml_path).getroot()
    for wahlkreis in root.findall('Wahlkreis'):
        wahlkreisname = wahlkreis.findtext('Name')
        for partei in wahlkreis.findall('Partei'):
            parteiname = partei.findtext('Name')
            for kandidat in partei.findall('Kandidat'):
                k = Kandidat(
                    persNr=persNr,
                    landtagswahl=jahr,
                    name=f"{kandidat.findtext('Nachname').strip()}, {kandidat.findtext('Vorname').strip()}",
                    partei=parteiname,
                    listenplatz=int(kandidat.findtext('AnfangListenPos')),
                    listenkandidatInWahlkreis=wahlkreisname,
                    direktkandidatInStimmkreis=None,
                    erststimmen={}, 
                    zweitstimmen={}
                )
                for stimmkreis in kandidat.findall('Stimmkreis'):
                    if stimmkreis.find('NumStimmen').attrib['Stimmentyp'] == 'Zweitstimmen':
                        k.zweitstimmen[int(stimmkreis.findtext('NrSK'))] = int(stimmkreis.findtext('NumStimmen'))
                    elif stimmkreis.find('NumStimmen').attrib['Stimmentyp'] == 'Erststimmen':
                        k.erststimmen[int(stimmkreis.findtext('NrSK'))] = int(stimmkreis.findtext('NumStimmen'))
                        k.direktkandidatInStimmkreis = int(stimmkreis.findtext('NrSK'))
                kandidaten.append(k)
                persNr = persNr + 1
    return kandidaten

def insert_landtagswahl(connection, jahr):
    cur = connection.cursor()
    cur.execute("INSERT INTO w.landtagswahl (jahr, wahltag) VALUES " +
                "(2013, '2013-09-15'), (2018, '2018-10-14')")
    cur.close()

def insert_wahlkreise(connection, wahlkreise):
    cur = connection.cursor()
    psycopg2.extras.execute_values(
        cur,
        'INSERT INTO W.Wahlkreis (wahlkreisname, landtagswahl, sitze) VALUES %s',
        [(w.name, w.landtagswahl, w.sitze) for w in wahlkreise]
    )
    cur.close()

def insert_stimmkreise(connection, stimmkreise):
    cur = connection.cursor()
    psycopg2.extras.execute_values(
        cur,
        'INSERT INTO W.Stimmkreis (nummer, wahlkreisname, landtagswahl, stimmkreisname, stimmberechtigte) VALUES %s',
        [(s.nummer, s.wahlkreisname, s.landtagswahl, s.stimmkreisname, s.stimmberechtigte) for s in stimmkreise]
    )
    cur.close()

def insert_parteien(connection, parteien):
    cur = connection.cursor()
    psycopg2.extras.execute_values(
        cur,
        'INSERT INTO W.Partei (name) VALUES %s',
        [(p.parteiname, ) for p in parteien]
    )
    cur.close()

def insert_kandidaten(connection, kandidaten):
    cur = connection.cursor()
    psycopg2.extras.execute_values(
        cur,
        'INSERT INTO W.Kandidat (persNr, landtagswahl, name, partei, listenplatz, listenkandidatInWahlkreis, direktkandidatInStimmkreis) VALUES %s',
        [(k.persNr, k.landtagswahl, k.name, k.partei, k.listenplatz, k.listenkandidatInWahlkreis, k.direktkandidatInStimmkreis) for k in kandidaten] 
    )
    cur.close()

def generate_erststimmen(connection, kandidaten, stimmkreise=None):
    if stimmkreise is not None:
        kandidaten = [k for k in kandidaten if k.direktkandidatInStimmkreis in stimmkreise]
    # create temp table erststimme (kandidat, landtagswahl, anzahlerststimmen)
    # create temp table zweitstimme (kandidat, landtagswahl, stimmkreis, wahlkreis, anzahl)
    cur = connection.cursor()
    cur.execute(
        'INSERT INTO W.Stimme (stimmeId, gueltig) SELECT i, true from generate_series(1, %s) g(i)', 
        (sum([sum(k.erststimmen.values()) for k in kandidaten]), )
    )
    values = []
    start = 1
    for k in kandidaten:
        if sum(k.erststimmen.values()) > 0:
            end = start - 1 + sum(k.erststimmen.values())
            values.append((k.persNr, k.landtagswahl, start, end))
            # cur.execute(
            #     'INSERT INTO W.Erststimme (stimmeId, kandidat, landtagswahl) SELECT i, %s as kandidat, %s as landtagswahl from generate_series(%s, %s) g(i)',
            #     (k.persNr, k.landtagswahl, start, end)
            # )
            start = end + 1
    psycopg2.extras.execute_batch(
        cur,
        'INSERT INTO W.Erststimme (stimmeId, kandidat, landtagswahl) SELECT i, %s as kandidat, %s as landtagswahl from generate_series(%s, %s) g(i)',
        values
    )
    cur.close()

def generate_zweitstimmen(connection, kandidaten, stimmkreise=None):
    if stimmkreise is not None:
        kandidaten = [k for k in kandidaten if k.direktkandidatInStimmkreis in stimmkreise]
    cur = connection.cursor()
    cur.execute(
        """
        CREATE TEMP TABLE tmp_agg_zweitstimmen (
            persNr int not null,
            landtagswahl int not null,
            stimmkreisnr int not null,
            anzahl int not null
        )
        ON COMMIT DELETE ROWS
        """
    )
    psycopg2.extras.execute_values(
        cur,
        'INSERT INTO tmp_agg_zweitstimmen VALUES %s',
        [(k.persNr, k.landtagswahl, stimmkreis, anzahl) for k in kandidaten for stimmkreis, anzahl in k.zweitstimmen.items()]
    )

    cur.execute(
        """
        insert into w.stimme 
        select 
            i, true 
        from 
            generate_series(
                (select count(*) from w.erststimme) + 1, 
                (select count(*) from w.erststimme) + 1 + (select sum(taz.anzahl) from tmp_agg_zweitstimmen taz)
            ) g(i)
        """
    )
    cur.execute(
        """
        insert into w.zweitstimme
        select (row_number() over () + (select count(*) from w.erststimme)), s.wahlkreisname, s.nummer, taz.landtagswahl
        from 
            tmp_agg_zweitstimmen taz, 
            generate_series(1, (
                select anzahl from tmp_agg_zweitstimmen taz2 where taz2.persnr = taz.persnr and taz2.landtagswahl = taz.landtagswahl and taz2.stimmkreisnr = taz.stimmkreisnr 
            )),
            w.stimmkreis s
        where s.landtagswahl = taz.landtagswahl and s.nummer = taz.stimmkreisnr
        """
    )
    cur.execute(
        """
        insert into w.zweitstimmekandidat 
        select (row_number() over () + (select count(*) from w.erststimme)), taz.persnr, taz.landtagswahl 
        from 
            tmp_agg_zweitstimmen taz, 
            generate_series(1, (
                select anzahl from tmp_agg_zweitstimmen taz2 where taz2.persnr = taz.persnr and taz2.landtagswahl = taz.landtagswahl and taz2.stimmkreisnr = taz.stimmkreisnr 
            )),
            w.stimmkreis s
        where s.landtagswahl = taz.landtagswahl and s.nummer = taz.stimmkreisnr 
        """
    )

    cur.close()

if __name__ == "__main__":
    ergebnis_xml_path = '2013Ergebnisse_final.xml'
    info_xml_path = '2013AllgemeineInformationen.xml'

    print(datetime.now(), 'Parsing...')
    wahlkreise = parse_wahlkreise(2013)
    stimmkreise = parse_stimmkreise(info_xml_path, 2013)
    parteien = parse_parteien(ergebnis_xml_path, 2013)
    kandidaten = parse_kandidaten(ergebnis_xml_path, 2013)

    print(datetime.now(), 'Connecting...')
    conn = psycopg2.connect("dbname=postgres user=postgres password=postgres")


    print(datetime.now(), 'Inserting Landtagswahl...')
    insert_landtagswahl(conn, 2013)
    
    print(datetime.now(), 'Inserting Wahlkreise...')
    insert_wahlkreise(conn, wahlkreise)
    
    print(datetime.now(), 'Inserting Stimmkreise...')
    insert_stimmkreise(conn, stimmkreise)

    print(datetime.now(), 'Inserting Parteien...')
    insert_parteien(conn, parteien)
    
    print(datetime.now(), 'Inserting Kandidaten...')
    insert_kandidaten(conn, kandidaten)
    
    print(datetime.now(), 'Generating Erststimmen (slow)...')
    generate_erststimmen(conn, kandidaten)
    
    print(datetime.now(), 'Generating Zweitstimmen (also slow but in DB)...')
    generate_zweitstimmen(conn, kandidaten)

    print(datetime.now())
    
    conn.commit()
    conn.close()
