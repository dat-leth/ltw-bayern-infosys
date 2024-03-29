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
import {getPartyColor} from "../src/helper/partyColor";
import {loadData} from "../src/helper/serverSide";

const useStyles = makeStyles(theme => ({
    table: {
        width: '100%',
        margin: theme.spacing(7, 7)
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

export default function WahlkreisOverview({data}) {
    const classes = useStyles();

    const [wahlkreisData, setWahlkreisData] = useState(data);

    useEffect(() => {
        loadData('/sitzplatzverteilung', setWahlkreisData);
    }, []);

    useEffect(() => console.log('WahlkreisData', wahlkreisData), [wahlkreisData]);

    const tableData2018 = useMemo(() => {
        const wahlkreisDataNotEmpty = wahlkreisData || [];
        return wahlkreisDataNotEmpty.filter(o => o.landtagswahl === 2018).sort((a, b) => a.wahlkreis.localeCompare(b.wahlkreis));
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
            <Typography variant="h4" color="primary">Wahlkreis Übersicht</Typography>
            <TableContainer className={classes.table}>
                <Table stickyHeader={true} size="small">
                    <TableHead>
                        <TableRow>
                            <TableCell>Wahlkreis</TableCell>
                            <TableCell>Partei</TableCell>
                            <TableCell align="right">Sitze</TableCell>
                            <TableCell align="right">Überhangmandate</TableCell>
                            <TableCell align="right">Ausgleichmandate</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {tableData2018.map(o =>
                            <TableRow key={o.partei + o.wahlkreis}>
                                <TableCell>{o.wahlkreis}</TableCell>
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
