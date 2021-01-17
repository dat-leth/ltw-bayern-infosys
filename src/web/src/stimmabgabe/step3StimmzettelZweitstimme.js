import { Button, makeStyles, FormControl, FormLabel, RadioGroup, Radio, FormControlLabel, Paper } from "@material-ui/core";
import ToggleButton from '@material-ui/lab/ToggleButton';
import { groupBy } from "../helper/groupBy";
import { useMemo } from 'react'

const useStyles = makeStyles(theme => ({
  button: {
    marginRight: theme.spacing(1),
  },
  instructions: {
    marginTop: theme.spacing(1),
    marginBottom: theme.spacing(1),
  },
  stimmzettel: {
    display: 'flex',
    flexDirection: 'row',
    flexWrap: 'nowrap'
  },
  spalte: {
    display: 'flex',
    flexDirection: 'column',
    marginRight: '10px',
    width: '300px',
    padding: '15px'
  }
}));


export default function Step3StimmzettelZweitstimme(props) {
  const classes = useStyles()

  const kandidatProPartei = useMemo(() => {
    return groupBy(props.stimmzettelZweitstimme, s => s.partei)
  }, [props.stimmzettelZweitstimme])

  const handleNext = () => {
    props.setActiveStep((prevActiveStep) => prevActiveStep + 1);
  };
  const handleBack = () => {
    props.setActiveStep((prevActiveStep) => prevActiveStep - 1);
  };


  const handleKandidatChange = (event) => {
    props.setZweitstimme({ kandidat: +event.target.value, partei: null });
  };

  const handleParteiChange = (partei) => {
    props.setZweitstimme({ kandidat: null, partei: partei })
  }

  return <>
    <div>
      <div>
        Sie haben 1 (eine) Stimme.
      </div>
      <div style={{overflow: 'auto'}}>
        <FormControl component="fieldset">
          <FormLabel component="legend">Zweitstimme für die Wahl einer oder eines Wahlkreisabgeordneten</FormLabel>
          <RadioGroup value={props.zweitstimme.kandidat} onChange={handleKandidatChange} className={classes.stimmzettel}>
            {Object.keys(kandidatProPartei).map((partei) => (
              <Paper key={partei} elevation={3} className={classes.spalte}>
                <ToggleButton value={partei} selected={props.zweitstimme.partei === partei} onChange={() => handleParteiChange(partei)}>{partei}</ToggleButton>
                { kandidatProPartei[partei].map((kandidat) => (<FormControlLabel key={kandidat.persnr} value={kandidat.persnr} control={<Radio />} label={kandidat.name}></FormControlLabel>))}
              </Paper>
            ))}
          </RadioGroup>
        </FormControl>
      </div>
      <div><Button variant="contained" onClick={() => props.setZweitstimme({ kandidat: null, partei: null })}>Zurücksetzen</Button></div>
      <div>
      
        <Button disabled={props.activeStep === 0} onClick={handleBack} className={classes.button}>
        Zurück
              </Button>
      <Button
        variant="contained"
        color="primary"
        onClick={handleNext}
        className={classes.button}
      >
        Weiter
      </Button>
      </div>

      
    </div>
  </>
}