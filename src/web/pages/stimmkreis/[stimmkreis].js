import React, {useEffect, useMemo, useState} from 'react';
import SideNavigation from "../../src/SideNavigation";
import {
    Card,
    CardContent,
    List,
    ListItem,
    ListItemText,
    makeStyles,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Typography
} from "@material-ui/core";
import {useRouter} from "next/router";
import {getPartyColor} from "../../src/helper/partyColor";
import {Doughnut} from "react-chartjs-2";
import {clientSideRendering, loadData} from "../../src/helper/serverSide";

const useStyles = makeStyles(theme => ({
    table: {
        width: '100%',
        padding: theme.spacing(7, 7)
    },
    wrapper: {
        display: 'flex',
        flexDirection: 'column',
        flex: '1 1 100%',
        padding: theme.spacing(5, 15, 0, 15),
        maxWidth: 1500
    },
    details: {
        display: 'flex',
        flexDirection: 'row',
        marginTop: 50,
    },
    leftCardContent: {
        position: 'relative'
    },
    card: {
        flex: '0 0 350px'
    },
    cardBig: {
        flex: '1 1 100%',
        marginLeft: 25
    },
    chart: {
        position: "relative",
        width: '100%',
        marginTop: 25
    },
    partyColor: {
        display: 'inline-block',
        width: 14,
        height: 14,
        verticalAlign: "middle",
        marginRight: 4,
        borderRadius: 3
    }
}));

export const getServerSideProps = async (context) => {
    if (clientSideRendering()) return {props: {}};

    const vergleichDataUrl = `/stimmkreisvergleichvorjahr?order=prozent2018.desc&stimmkreis=eq.${context.params.stimmkreis}`;
    const vergleichData = await loadData(vergleichDataUrl);


    const detailDataUrl = `/stimmkreisdetails?stimmkreis=eq.${context.params.stimmkreis}&landtagswahl=eq.2018`;
    const detailData = await loadData(detailDataUrl);

    return {
        props: {
            preVergleichData: vergleichData.props.data,
            preDetailData: detailData.props.data[0]
        }
    }
}

export default function Stimmkreis({preVergleichData, preDetailData}) {
    const router = useRouter();
    const {stimmkreis} = router.query;

    const classes = useStyles();

    const [vergleichData, setVergleichData] = useState(preVergleichData || []);
    const [detailData, setDetailData] = useState(preDetailData);

    useEffect(() => {
        if (stimmkreis == null) return;

        loadData(`/stimmkreisvergleichvorjahr?order=prozent2018.desc&stimmkreis=eq.${stimmkreis}`, setVergleichData);
    }, [stimmkreis]);

    useEffect(() => {
        if (stimmkreis == null) return;

        loadData(`/stimmkreisdetails?stimmkreis=eq.${stimmkreis}&landtagswahl=eq.2018`, o => setDetailData(o[0]));
    }, [stimmkreis]);

    const formatPercent = o => Math.round(o * 100 * 100) / 100;

    const formatDecimal = o => {
        if (o == null) return;

        o = o.toString()

        for (let i = 3; i < o.length; i += 4) {
            o = `${o.substr(0, o.length - i)}.${o.substr(o.length - i)}`
        }

        return o;
    }

    const chartData2018 = useMemo(() => {
        return {
            datasets: [
                {
                    data: vergleichData.map(o => o.prozent2018),
                    backgroundColor: vergleichData.map(o => getPartyColor(o.partei))
                }
            ],
            labels: vergleichData.map(o => o.partei),

        };
    }, [vergleichData]);

    const chartData2013 = useMemo(() => {
        return {
            datasets: [
                {
                    data: vergleichData.map(o => o.prozent2013),
                    backgroundColor: vergleichData.map(o => getPartyColor(o.partei))
                }
            ],
            labels: vergleichData.map(o => o.partei),

        };
    }, [vergleichData]);

    const doughnutOptions = {
        circumference: Math.PI,
        rotation: -Math.PI,
        responsive: true,
        legend: {
            display: false
        }
    };

    return <>
        <SideNavigation drawerWidth={300}/>
        <div className={classes.wrapper}>
            <Typography variant="h4" color="primary">Stimmkreis {stimmkreis}</Typography>
            <div className={classes.details}>
                <Card className={classes.card}>
                    <CardContent className={classes.leftCardContent}>
                        <Typography variant="h6" component="h2">
                            Allgemeine Infos
                        </Typography>

                        <List dense={true}>
                            <ListItem>
                                <ListItemText primary={`Nummer: ${detailData?.stimmkreis}`}/>
                            </ListItem>
                            <ListItem>
                                <ListItemText primary={`Name: ${detailData?.stimmkreisname}`}/>
                            </ListItem>
                            <ListItem>
                                <ListItemText primary={`Wahlkreis: ${detailData?.wahlkreisname}`}/>
                            </ListItem>
                            <ListItem>
                                <ListItemText
                                    primary={`Direktmandat: ${detailData?.direktmandat} (${detailData?.parteierststimme})`}/>
                            </ListItem>
                            <ListItem>
                                <ListItemText primary={`Stimmberechigte: ${formatDecimal(detailData?.stimmberechtigte)}`}/>
                            </ListItem>
                            <ListItem>
                                <ListItemText primary={`Wähler: ${formatDecimal(detailData?.waehler)}`}/>
                            </ListItem>
                            <ListItem>
                                <ListItemText
                                    primary={`Wahlbeteiligung: ${formatPercent(detailData?.waehler / detailData?.stimmberechtigte)}%`}/>
                            </ListItem>
                        </List>

                        <div className={classes.chart}>
                            <Typography variant="h6" component="h3">Anteile 2018</Typography>
                            <Doughnut data={chartData2018} options={doughnutOptions}/>
                        </div>

                        <div className={classes.chart}>
                            <Typography variant="h6" component="h3">Anteile 2013</Typography>
                            <Doughnut data={chartData2013} options={doughnutOptions}/>
                        </div>
                    </CardContent>
                </Card>

                <Card className={classes.cardBig}>
                    <CardContent>
                        <Typography variant="h6" component="h2">
                            Partei Info
                        </Typography>
                        <TableContainer className={classes.table}>
                            <Table size="small">
                                <TableHead>
                                    <TableRow>
                                        <TableCell>Partei</TableCell>
                                        <TableCell align="right">Stimmen 2018</TableCell>
                                        <TableCell align="right">Stimmen 2013</TableCell>
                                        <TableCell align="right">Anteil 2018 (%)</TableCell>
                                        <TableCell align="right">Anteil 2013 (%)</TableCell>
                                    </TableRow>
                                </TableHead>
                                <TableBody>
                                    {vergleichData.map(o =>
                                        <TableRow key={o.partei}>
                                            <TableCell>
                                                <span className={classes.partyColor}
                                                      style={{backgroundColor: getPartyColor(o.partei)}}/>
                                                {o.partei}
                                            </TableCell>
                                            <TableCell align="right">{formatDecimal(o.gesamtstimmen2018)}</TableCell>
                                            <TableCell align="right">{formatDecimal(o.gesamtstimmen2013) || '-'}</TableCell>
                                            <TableCell align="right">{formatPercent(o.prozent2018)}</TableCell>
                                            <TableCell align="right">{formatPercent(o.prozent2013)}</TableCell>
                                        </TableRow>
                                    )}
                                </TableBody>
                            </Table>
                        </TableContainer>
                    </CardContent>
                </Card>
            </div>
        </div>
    </>;
}
