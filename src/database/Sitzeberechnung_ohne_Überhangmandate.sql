with 
-- Erst-/Zweitstimmen pro Partei pro Wahlkreis
erststimmen_partei as (
    select k.partei,
        k.listenkandidatinwahlkreis as wahlkreisname,
        count(*) as anzahl
    from w.erststimme e
        join w.kandidat k on e.kandidat = k.persnr
        and e.landtagswahl = k.landtagswahl
    where e.landtagswahl = 2018
        and e.gueltig = true
    group by k.partei,
        k.listenkandidatinwahlkreis
),
zweitstimmen_kandidat_partei as (
    select k.partei,
        k.listenkandidatinwahlkreis as wahlkreisname,
        count(*) as anzahl
    from w.zweitstimmekandidat z
        join w.kandidat k on z.kandidat = k.persnr
        and z.landtagswahl = k.landtagswahl
    where z.landtagswahl = 2018
        and z.gueltig = true
    group by k.partei,
        k.listenkandidatinwahlkreis
),
zweitstimmen_ohne_kandidat_partei as (
    select z.partei,
        z.wahlkreisname,
        count(*) as anzahl
    from w.zweitstimmepartei z
    where z.landtagswahl = 2018
        and z.gueltig = true
    group by z.partei,
        z.wahlkreisname
),

-- Erst-/Zweitstimmen insgesamt
erststimmen_gesamt as (
    select count(*) as anzahl
    from w.erststimme e
    where e.landtagswahl = 2018
        and e.gueltig = true
),
zweitstimmen_kandidat_gesamt as (
    select count(*) as anzahl
    from w.zweitstimmekandidat z
    where z.landtagswahl = 2018
        and z.gueltig = true
),
zweitstimmen_ohne_kandidat_gesamt as (
    select count(*) as anzahl
    from w.zweitstimmepartei z
    where z.landtagswahl = 2018
        and z.gueltig = true
),

-- Gesamtstimmen pro Partei pro Wahlkreis
stimmen_wahlkreis_partei as (
    select partei,
        wahlkreisname,
        sum(anzahl) as anzahl
    from (
            select *
            from erststimmen_partei
            union
            select *
            from zweitstimmen_kandidat_partei
            union
            select *
            from zweitstimmen_ohne_kandidat_partei
        ) sub
    group by partei,
        wahlkreisname
),

-- Gesamtstimmen pro Partei
stimmen_partei as (
    select partei,
        sum(anzahl) as anzahl
    from (
            select *
            from erststimmen_partei
            union
            select *
            from zweitstimmen_kandidat_partei
            union
            select *
            from zweitstimmen_ohne_kandidat_partei
        ) sub
    group by partei
),

-- Gesamtstimmen
stimmen_gesamt as (
    select sum(anzahl)
    from (
            select *
            from erststimmen_gesamt
            union
            select *
            from zweitstimmen_kandidat_gesamt
            union
            select *
            from zweitstimmen_ohne_kandidat_gesamt
        ) sub
),

-- Stimmenprozente pro Partei
stimmen_prozent as (
    select partei,
        anzahl,
        anzahl / (
            select *
            from stimmen_gesamt
        ) as prozent
    from stimmen_partei
),

-- Parteien unter/über 5%-Hürde
parteien_unter_5 as (
    select *
    from stimmen_prozent
    where prozent < 0.05
),
parteien_ueber_5 as (
    select *
    from stimmen_prozent
    where prozent >= 0.05
),

-- Gesamtstimmen pro Wahlkreis von Parteien über Sperrklausel
stimmen_ueber_5_wahlkreis as (
    select wahlkreisname,
        sum(anzahl) as gesamtstimmen
    from stimmen_wahlkreis_partei
    where partei in (
            select partei
            from parteien_ueber_5
        )
    group by wahlkreisname
),

-- Anteil von Sitzen pro Wahlkreis einer Partei
sitze_anteil as (
    select p.partei,
        s.anzahl,
        w.wahlkreisname,
        w.sitze,
        (w.sitze * s.anzahl) / (
            select gesamtstimmen
            from stimmen_ueber_5_wahlkreis s5
            where s5.wahlkreisname = w.wahlkreisname
        ) as anteil
    from parteien_ueber_5 p
        join stimmen_wahlkreis_partei s on s.partei = p.partei
        join w.wahlkreis w on w.wahlkreisname = s.wahlkreisname
    where w.landtagswahl = 2018
),
-- Berechnung ganzzahliger Anteil und Nachkommastellen, Sortierung der Nachkommastellen pro Wahlkreis
sitze_ganzzahl as (
    select s.partei,
        s.wahlkreisname,
        s.sitze,
        floor(s.anteil) as ganz,
        s.anteil - floor(s.anteil) as rest,
        row_number() over (
            partition by s.wahlkreisname
            order by s.anteil - floor(s.anteil) desc
        )
    from sitze_anteil s
),
-- Berechnung übriger Sitze nach Verteilung des ganzzahligen Anteils
sitze_wahlkreis_rest as (
    select s.wahlkreisname,
        s.sitze,
        sum(s.ganz) as verteilt,
        s.sitze - sum(s.ganz) as rest
    from sitze_ganzzahl s
    group by s.wahlkreisname,
        s.sitze
),
-- Wählen der Parteien entsprechend der Sortierung nach Nachkommastellen
sitze_bruchteile as (
    select sg.partei,
        sg.wahlkreisname,
        count(*) as extra
    from sitze_ganzzahl sg
        join sitze_wahlkreis_rest swr on sg.wahlkreisname = swr.wahlkreisname
    where row_number <= swr.rest
    group by sg.partei,
        sg.wahlkreisname
),
-- Sitzeberechnung nach Wahlkreisen ohne Beachtung von Überhang-/Ausgleichsmandate
sitze as (
    select sa.partei,
        sa.anzahl,
        sa.wahlkreisname,
        sa.sitze,
        floor(sa.anteil) as ganz,
        coalesce(sb.extra, 0) as rest,
        floor(sa.anteil) + coalesce(sb.extra, 0) as sitze_partei
    from sitze_anteil sa
        left join sitze_bruchteile sb on sa.partei = sb.partei
        and sa.wahlkreisname = sb.wahlkreisname
)
select *
from sitze