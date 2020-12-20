import SideNavigation from "../src/SideNavigation";
import { useEffect, useMemo, useState } from 'react';
import { makeStyles, Typography } from "@material-ui/core";
import { Scatter } from "react-chartjs-2";

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

export default function AuslaenderAfD() {
    const classes = useStyles()
    const [auslaenderData, setAuslaenderData] = useState()

    useEffect(() => {
        fetch(process.env.NEXT_PUBLIC_BACKEND_URL + '/auslaenderafd').then(resp => {
            if (resp.ok) {
                resp.json()
                    .then(data => setAuslaenderData(data))
                    .catch(err => console.error('Failed to deserialize JSON', err));
            } else {
                console.warn('Backend Request not successful', resp);
            }
        }).catch(err => console.error('Backend Request failed', err))
    }, []);

    const chartData = useMemo(() => {
        if (auslaenderData) {
            return {
                datasets: [{
                    label: 'Gesamtstimmenanteil AfD vs. Ausländeranteil',
                    backgroundColor: '#0C4A6E',
                    data: auslaenderData.map((kreis) => {
                        return {
                            x: kreis.afd_anteil,
                            y: kreis.quote,
                            label: `${kreis.name} (${kreis.kreisschluessel})`
                        }
                    })
                }]
            }
        } else {
            return {
                datasets: [{
                    data: []
                }]
            }
        }
    }, [auslaenderData])

    const chartOptions = {
        scales: {
            yAxes: [{
                scaleLabel: {
                  display: true,
                  labelString: 'Ausländerquote'
                }
              }],
              xAxes: [{
                scaleLabel: {
                  display: true,
                  labelString: 'Gesamtstimmenanteil'
                }
              }],
        },
        tooltips: {
            callbacks: {
               label: function(tooltipItem, data) {
                  var label = [data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index].label, tooltipItem.xLabel, tooltipItem.yLabel]
                  return label
               }
            }
         }
    }


    return <>
        <SideNavigation drawerWidth={300} />
        <div className={classes.wrapper}>
            <Typography variant="h4" color="primary">Ausländeranteil vs. Gesamtstimmenanteil der AfD</Typography>
            <div className={classes.chart}>
                <div>
                    <Typography>Scatter-Plot</Typography>
                    <Scatter data={chartData} options={chartOptions} />
                </div>
            </div>
        </div>
    </>
}