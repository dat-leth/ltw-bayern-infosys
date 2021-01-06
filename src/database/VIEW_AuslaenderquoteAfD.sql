create or replace view w.auslaenderafd as 

with erststimmen_stimmkreis_summe as (
    select landtagswahl,
        stimmkreis,
        sum(anzahl) as summe
    from w.erststimmenprokandidatstimmkreis
    group by landtagswahl,
        stimmkreis
),
zweitstimmen_kandidat_stimmkreis_summe as (
    select landtagswahl,
        stimmkreis,
        sum(anzahl) as summe
    from w.zweitstimmenprokandidatstimmkreis
    group by landtagswahl,
        stimmkreis
),
zweitstimmen_partei_stimmkreis_summe as (
    select landtagswahl,
        stimmkreis,
        sum(anzahl) as summe
    from w.zweitstimmenproparteistimmkreis
    group by landtagswahl,
        stimmkreis
),
gesamtstimmen_stimmkreis as (
    select s.landtagswahl,
        s.nummer,
        e.summe + zk.summe + zp.summe as gesamt
    from w.stimmkreis s
        left join erststimmen_stimmkreis_summe e on e.landtagswahl = s.landtagswahl
        and e.stimmkreis = s.nummer
        left join zweitstimmen_kandidat_stimmkreis_summe zk on zk.landtagswahl = s.landtagswahl
        and zk.stimmkreis = s.nummer
        left join zweitstimmen_partei_stimmkreis_summe zp on zp.landtagswahl = s.landtagswahl
        and zp.stimmkreis = s.nummer
    where s.landtagswahl = 2018
    order by s.nummer
),
stimmkreis_afd as (
    select *
    from w.stimmenproparteistimmkreis
    where landtagswahl = 2018
        and partei = 'AfD'
),
stimmen as (
    select g.landtagswahl,
        s.stimmkreis,
        s.partei,
        s.erststimmen,
        s.zweitstimmen,
        g.gesamt
    from gesamtstimmen_stimmkreis g
        left join stimmkreis_afd s on s.landtagswahl = g.landtagswahl
        and s.stimmkreis = g.nummer
    order by stimmkreis
)
select g.kreisschluessel,
    k.name,
    a.quote,
    (sum(erststimmen) + sum(zweitstimmen)) / sum(gesamt) as afd_anteil
from w.auslaenderquote a
    join w.gemeinde g on g.kreisschluessel = a.kreisschluessel
    join w.kreis k on g.kreisschluessel = k.kreisschluessel
    join stimmen s on s.stimmkreis = g.stimmkreis
group by g.kreisschluessel,
    k.name,
    a.quote
order by afd_anteil asc,
    quote asc