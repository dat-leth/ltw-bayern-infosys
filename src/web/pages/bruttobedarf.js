import React, {useEffect, useMemo, useState} from 'react';
import SideNavigation from "../src/SideNavigation";
import {makeStyles, Typography} from "@material-ui/core";
import {groupBy} from "../src/helper/groupBy";
import {Bar} from "react-chartjs-2";
import {getPartyColor} from "../src/helper/partyColor";

const useStyles = makeStyles(theme => ({
    table: {
        width: '100%',
        padding: theme.spacing(7, 7)
    },
    chart: {
        position: "relative",
        width: '80%',
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

function compare(a, b) {
    if (a.bwindowed < b.bwindowed) {
        return -1;
    }
    if (a.bwindowed > b.bwindowed) {
        return 1;
    }
    return 0;
}

export default function BruttoBedarf() {
    const classes = useStyles();

    const [data, setData] = useState();

    useEffect(() => {
        fetch(process.env.NEXT_PUBLIC_BACKEND_URL + '/prozentprobruttobedarf').then(resp => {
            if (resp.ok) {
                resp.json()
                    .then(data => setData(data))
                    .catch(err => console.error('Failed to deserialize JSON', err));
            } else {
                console.warn('Backend Request not successful', resp);
            }
        }).catch(err => console.error('Backend Request failed', err))
    }, []);

    useEffect(() => console.log('prozentprobruttobedarf data', data), [data]);

    const chartData = useMemo(() => {
        if (data == null) return {};

        console.log(Object.entries(groupBy(data, o => o.bwindowed)));

        return {
            datasets: Object.entries(groupBy(data, o => o.partei))
                .map(([k, v]) => (
                    {
                        label: k,
                        backgroundColor: getPartyColor(k),
                        data: v.sort(compare).map(o => o.prozent)
                    })),
            labels: [...new Set(data.map(o => o.bwindowed))],

        };
    }, [data]);

    const chartOptions = {
        responsive: true,
        legend: {
            position: 'bottom',
            display: true
        },
        scales: {
            xAxes: [{
                stacked: true,
            }],
            yAxes: [{
                stacked: true
            }]
        }
    };

    return <>
        <SideNavigation drawerWidth={300}/>
        <div className={classes.wrapper}>
            <Typography variant="h4" color="primary">Prozent pro Brutto-Grundbedarf</Typography>
            <div className={classes.chart}>
                <div>
                    <Typography>Auf der x-Achse sind der Brutto-Grundbedarf und auf der y-Achse die Prozentanteile der Stimmen einer jeden Partei aufgetragen.</Typography>
                    <Typography>Die x-Achse wurde dabei in 15 Windows aufgeteilt.</Typography>
                    <Bar data={chartData} options={chartOptions}/>
                </div>
            </div>
        </div>
    </>;
}
