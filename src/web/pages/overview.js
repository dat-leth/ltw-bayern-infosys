import React, {useEffect, useMemo, useState} from 'react';
import SideNavigation from "../src/SideNavigation";
import {
    makeStyles,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Typography
} from "@material-ui/core";
import {groupBy} from "../src/helper/groupBy";
import {Doughnut} from "react-chartjs-2";
import {getPartyColor} from "../src/helper/partyColor";
import {loadData} from "../src/helper/serverSide";

const useStyles = makeStyles(theme => ({
    table: {
        width: '100%',
        padding: theme.spacing(7, 7)
    },
    chart: {
        position: "relative",
        width: '55%',
        alignSelf: "center",
        paddingTop: theme.spacing(5)
    },
    wrapper: {
        display: 'flex',
        flexDirection: 'column',
        flex: '1 1 100%',
        padding: theme.spacing(5, 15, 0, 15),
        maxWidth: 1500
    }
}));

export const getServerSideProps = async () => await loadData('/sitzplatzverteilung');

export default function Overview({data}) {
    const classes = useStyles();

    const [wahlkreisData, setWahlkreisData] = useState(data);

    useEffect(() => {
        loadData('/sitzplatzverteilung', setWahlkreisData);
    }, []);

    useEffect(() => console.log('WahlkreisData', wahlkreisData), [wahlkreisData]);

    const tableData2018 = useMemo(() => {
        const wahlkreisDataNotEmpty = wahlkreisData || [];
        const wahlkreisData2018 = wahlkreisDataNotEmpty.filter(o => o.landtagswahl === 2018);
        const wahlkreisDataGrouped = groupBy(wahlkreisData2018, o => o.partei);

        return Object.entries(wahlkreisDataGrouped)
            .map(([k, v]) => {
                const aggGesamtSitze = v.reduce((p, c) => p + c.gesamt, 0);
                const aggUeberhang = v.reduce((p, c) => p + c.ueberhang, 0);
                const aggMinsitze = v.reduce((p, c) => p + c.minsitze, 0);

                return ({
                    partei: k,
                    sitze: aggGesamtSitze,
                    ueberhang: aggUeberhang,
                    ausgleich: aggGesamtSitze - aggMinsitze
                });
            });
    }, [wahlkreisData]);

    const chartData2018 = useMemo(() => {
        return {
            datasets: [
                {
                    data: tableData2018.map(o => o.sitze),
                    backgroundColor: tableData2018.map(o => getPartyColor(o.partei))
                }
            ],
            labels: tableData2018.map(o => o.partei),

        };
    }, [tableData2018]);

    const doughnutOptions = {
        circumference: Math.PI,
        rotation: -Math.PI,
        responsive: true,
        legend: {
            position: 'right'
        }
    };

    return <>
        <SideNavigation drawerWidth={300}/>
        <div className={classes.wrapper}>
            <Typography variant="h4" color="primary">Übersicht</Typography>
            <div className={classes.chart}>
                <div>
                    <Doughnut data={chartData2018} options={doughnutOptions}/>
                </div>
            </div>
            <TableContainer className={classes.table}>
                <Table>
                    <TableHead>
                        <TableRow>
                            <TableCell>Partei</TableCell>
                            <TableCell align="right">Sitze</TableCell>
                            <TableCell align="right">Überhangmandate</TableCell>
                            <TableCell align="right">Ausgleichmandate</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {tableData2018.map(o =>
                            <TableRow key={o.partei}>
                                <TableCell>{o.partei}</TableCell>
                                <TableCell align="right">{o.sitze}</TableCell>
                                <TableCell align="right">{o.ueberhang}</TableCell>
                                <TableCell align="right">{o.ausgleich}</TableCell>
                            </TableRow>)}
                    </TableBody>
                </Table>
            </TableContainer>
        </div>
    </>;
}
